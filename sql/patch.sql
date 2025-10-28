-- ===== Limpieza segura por si quedaron restos =====
DROP MATERIALIZED VIEW IF EXISTS oee_hour CASCADE;
DROP MATERIALIZED VIEW IF EXISTS state_durations_hour CASCADE;
DROP MATERIALIZED VIEW IF EXISTS cycle_agg_hour CASCADE;

DROP VIEW IF EXISTS oee_hour_v CASCADE;
DROP VIEW IF EXISTS state_durations_hour_v CASCADE;
DROP VIEW IF EXISTS cycle_agg_hour_v CASCADE;
DROP VIEW IF EXISTS state_spans_v CASCADE;

-- ===== 1) Ciclos por hora (VIEW) =====
CREATE VIEW cycle_agg_hour_v AS
SELECT time_bucket('1 hour', time) AS bucket,
       machine_id,
       COUNT(*)::int AS total_count,
       SUM(good)::int AS good_count,
       SUM(scrap)::int AS scrap_count,
       MIN(ct_ideal_ms) AS ct_ideal_ms
FROM event_cycle
GROUP BY bucket, machine_id;

-- ===== 2) Span entre eventos de estado (SUBQUERY en VIEW) =====
-- Calcula el "siguiente timestamp" por máquina y el delta en segundos
CREATE VIEW state_spans_v AS
SELECT
  machine_id,
  state,
  time,
  LEAD(time) OVER (PARTITION BY machine_id ORDER BY time) AS next_time,
  EXTRACT(EPOCH FROM (LEAD(time) OVER (PARTITION BY machine_id ORDER BY time) - time)) AS delta_s
FROM event_state;

-- ===== 3) Duraciones por hora (VIEW usando la subconsulta previa) =====
CREATE VIEW state_durations_hour_v AS
SELECT
  machine_id,
  time_bucket('1 hour', time) AS bucket,
  SUM(delta_s) FILTER (WHERE state = 'RUN') AS run_s,
  SUM(delta_s) FILTER (WHERE state IN ('STOP','FAULT')) AS stopfault_s
FROM state_spans_v
-- Nota: el último evento de la hora no tiene next_time; delta_s será NULL y no suma.
GROUP BY machine_id, bucket;

-- ===== 4) OEE por hora (VIEW uniendo todo) =====
-- Requiere que llenes planned_time_hour con tu calendario.
-- Si aún no lo llenas, puedes poner planned_s = 3600 para pruebas.
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
