-- ===== 1) LIMPIEZA SEGURA =====
DROP MATERIALIZED VIEW IF EXISTS oee_hour CASCADE;
DROP MATERIALIZED VIEW IF EXISTS state_durations_hour CASCADE;
DROP MATERIALIZED VIEW IF EXISTS cycle_agg_hour CASCADE;

DROP VIEW IF EXISTS oee_hour_v CASCADE;
DROP VIEW IF EXISTS state_durations_hour_v CASCADE;
DROP VIEW IF EXISTS cycle_agg_hour_v CASCADE;
DROP VIEW IF EXISTS state_spans_v CASCADE;

-- ===== 2) ALIAS (VISTAS BASE) =====
CREATE OR REPLACE VIEW machine_state AS
  SELECT time AS ts, machine_id, state, reason_code, order_id, lot_id, seq, source FROM event_state;
CREATE OR REPLACE VIEW production_cycle AS
  SELECT time AS ts, machine_id, order_id, lot_id, result, good, scrap, scrap_reason_code, ct_ideal_ms, ct_actual_ms, seq, source FROM event_cycle;
CREATE OR REPLACE VIEW alarms AS
  SELECT time AS ts, machine_id, alarm_code, severity, text, active, seq, source FROM event_alarm;

-- ===== 3) ÍNDICES =====
CREATE INDEX IF NOT EXISTS ix_event_state_time ON event_state(time);
CREATE INDEX IF NOT EXISTS ix_event_state_machine_time ON event_state(machine_id, time);
CREATE UNIQUE INDEX IF NOT EXISTS ux_event_state_seq ON event_state(machine_id, seq);
CREATE INDEX IF NOT EXISTS ix_event_cycle_time ON event_cycle(time);
CREATE INDEX IF NOT EXISTS ix_event_cycle_machine_time ON event_cycle(machine_id, time);
CREATE UNIQUE INDEX IF NOT EXISTS ux_event_cycle_seq ON event_cycle(machine_id, seq);
CREATE INDEX IF NOT EXISTS ix_event_alarm_time ON event_alarm(time);
CREATE INDEX IF NOT EXISTS ix_event_alarm_machine_time ON event_alarm(machine_id, time);
CREATE UNIQUE INDEX IF NOT EXISTS ux_event_alarm_seq ON event_alarm(machine_id, seq);

-- ===== 4) VISTAS COMPLEJAS =====
CREATE VIEW cycle_agg_hour_v AS
SELECT time_bucket('1 hour', time) AS bucket,
       machine_id,
       COUNT(*)::int AS total_count,
       SUM(good)::int AS good_count,
       SUM(scrap)::int AS scrap_count,
       MIN(ct_ideal_ms) AS ct_ideal_ms
FROM event_cycle
GROUP BY bucket, machine_id;

CREATE VIEW state_spans_v AS
SELECT
  machine_id,
  state,
  time,
  LEAD(time) OVER (PARTITION BY machine_id ORDER BY time) AS next_time,
  EXTRACT(EPOCH FROM (LEAD(time) OVER (PARTITION BY machine_id ORDER BY time) - time)) AS delta_s
FROM event_state;

CREATE VIEW state_durations_hour_v AS
SELECT
  machine_id,
  time_bucket('1 hour', time) AS bucket,
  SUM(delta_s) FILTER (WHERE state = 'RUN') AS run_s,
  SUM(delta_s) FILTER (WHERE state IN ('STOP','FAULT')) AS stopfault_s
FROM state_spans_v
GROUP BY machine_id, bucket;

CREATE VIEW oee_hour_v AS
SELECT
  c.bucket,
  c.machine_id,
  c.total_count,
  c.good_count,
  c.scrap_count,
  sd.run_s,
  p.planned_s,
  (sd.run_s / NULLIF(p.planned_s,0))::float AS availability,
  ((m.ct_ideal_ms/1000.0 * c.total_count) / NULLIF(sd.run_s,0))::float AS performance,
  (c.good_count / NULLIF(c.total_count,0)::float) AS quality,
  (
    (sd.run_s / NULLIF(p.planned_s,0)) *
    ((m.ct_ideal_ms/1000.0 * c.total_count) / NULLIF(sd.run_s,0)) *
    (c.good_count / NULLIF(c.total_count,0)::float)
  )::float AS oee
FROM cycle_agg_hour_v c
JOIN state_durations_hour_v sd USING (machine_id, bucket)
JOIN planned_time_hour p USING (machine_id, bucket)
JOIN machines m USING (machine_id);

-- ===== VISTA OEE POR TURNO =====
CREATE VIEW oee_shift AS
SELECT
  date_trunc('day', c.bucket) AS day,
  s.name AS shift_name,
  c.machine_id,
  SUM(c.total_count)::int AS total_count,
  SUM(c.good_count)::int AS good_count,
  SUM(c.scrap_count)::int AS scrap_count,
  SUM(sd.run_s) AS run_s,
  SUM(p.planned_s) AS planned_s,
  (SUM(sd.run_s) / NULLIF(SUM(p.planned_s),0))::float AS availability,
  ((m.ct_ideal_ms/1000.0 * SUM(c.total_count)) / NULLIF(SUM(sd.run_s),0))::float AS performance,
  (SUM(c.good_count) / NULLIF(SUM(c.total_count),0)::float) AS quality,
  ((SUM(sd.run_s) / NULLIF(SUM(p.planned_s),0)) *
   ((m.ct_ideal_ms/1000.0 * SUM(c.total_count)) / NULLIF(SUM(sd.run_s),0)) *
   (SUM(c.good_count) / NULLIF(SUM(c.total_count),0)::float))::float AS oee
FROM cycle_agg_hour_v c
JOIN state_durations_hour_v sd USING (machine_id, bucket)
JOIN planned_time_hour p USING (machine_id, bucket)
JOIN machines m USING (machine_id)
JOIN shift_calendar s ON (EXTRACT(ISODOW FROM (c.bucket at time zone s.timezone)) = ANY(s.dow)
      AND (c.bucket at time zone s.timezone)::time BETWEEN s.start_local AND (s.start_local + (s.duration_min||' minutes')::interval))
GROUP BY day, shift_name, c.machine_id, m.ct_ideal_ms;
