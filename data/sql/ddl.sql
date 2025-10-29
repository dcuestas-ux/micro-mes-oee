-- Autor: Carolina
CREATE EXTENSION IF NOT EXISTS timescaledb;

CREATE TABLE IF NOT EXISTS machines (
  machine_id text PRIMARY KEY,
  name text,
  ct_ideal_ms integer NOT NULL DEFAULT 1200
);

CREATE TABLE IF NOT EXISTS shift_calendar (
  id serial PRIMARY KEY,
  name text NOT NULL,
  dow int[] NOT NULL, -- 1..7 (Mon..Sun)
  start_local time NOT NULL,
  duration_min int NOT NULL,
  timezone text NOT NULL DEFAULT 'America/Bogota'
);

CREATE TABLE IF NOT EXISTS orders (
  order_id text PRIMARY KEY,
  sku text,
  target_qty int
);

CREATE TABLE IF NOT EXISTS lots (
  lot_id text PRIMARY KEY,
  order_id text REFERENCES orders(order_id),
  planned_qty int
);

CREATE TABLE IF NOT EXISTS event_state (
  time timestamptz NOT NULL,
  machine_id text NOT NULL REFERENCES machines(machine_id),
  state text NOT NULL CHECK (state IN ('IDLE','RUN','STOP','FAULT','SETUP')),
  reason_code text,
  order_id text,
  lot_id text,
  seq bigint NOT NULL,
  source text
);
SELECT create_hypertable('event_state','time', if_not_exists=>true);

CREATE TABLE IF NOT EXISTS event_cycle (
  time timestamptz NOT NULL,
  machine_id text NOT NULL REFERENCES machines(machine_id),
  order_id text,
  lot_id text,
  result text NOT NULL CHECK (result IN ('GOOD','SCRAP')),
  good smallint NOT NULL CHECK (good IN (0,1)),
  scrap smallint NOT NULL CHECK (scrap IN (0,1)),
  scrap_reason_code text,
  ct_ideal_ms integer NOT NULL,
  ct_actual_ms integer,
  seq bigint NOT NULL,
  source text
);
SELECT create_hypertable('event_cycle','time', if_not_exists=>true);

CREATE TABLE IF NOT EXISTS event_alarm (
  time timestamptz NOT NULL,
  machine_id text NOT NULL REFERENCES machines(machine_id),
  alarm_code text NOT NULL,
  severity text NOT NULL CHECK (severity IN ('info','warn','fault')),
  text text,
  active boolean NOT NULL,
  seq bigint NOT NULL,
  source text
);
SELECT create_hypertable('event_alarm','time', if_not_exists=>true);

-- Agregación por hora (ciclos)
CREATE MATERIALIZED VIEW IF NOT EXISTS cycle_agg_hour
WITH (timescaledb.continuous) AS
SELECT time_bucket('1 hour', time) AS bucket,
       machine_id,
       count(*)::int AS total_count,
       sum(good)::int AS good_count,
       sum(scrap)::int AS scrap_count,
       min(ct_ideal_ms) AS ct_ideal_ms
FROM event_cycle
GROUP BY bucket, machine_id;

-- Aproximación de duraciones por estado por hora
CREATE VIEW state_spans_v AS
SELECT
  machine_id,
  state,
  time,
  LEAD(time) OVER (PARTITION BY machine_id ORDER BY time) AS next_time,
  EXTRACT(EPOCH FROM (LEAD(time) OVER (PARTITION BY machine_id ORDER BY time) - time)) AS delta_s
FROM event_state;

CREATE MATERIALIZED VIEW IF NOT EXISTS state_durations_hour AS
SELECT
  machine_id,
  time_bucket('1 hour', time) AS bucket,
  SUM(delta_s) FILTER (WHERE state = 'RUN') AS run_s,
  SUM(delta_s) FILTER (WHERE state IN ('STOP','FAULT')) AS stopfault_s
FROM state_spans_v
GROUP BY machine_id, bucket;

-- Tiempo planificado por hora (desde calendario)
CREATE TABLE IF NOT EXISTS planned_time_hour (
  bucket timestamptz NOT NULL,
  machine_id text NOT NULL REFERENCES machines(machine_id),
  planned_s integer NOT NULL,
  PRIMARY KEY (bucket, machine_id)
);

-- Vista OEE por hora
CREATE MATERIALIZED VIEW IF NOT EXISTS oee_hour AS
SELECT c.bucket, c.machine_id,
       c.total_count, c.good_count, c.scrap_count,
       sd.run_s, p.planned_s,
       (sd.run_s / NULLIF(p.planned_s,0))::float AS availability,
       ((m.ct_ideal_ms/1000.0 * c.total_count) / NULLIF(sd.run_s,0))::float AS performance,
       (c.good_count / NULLIF(c.total_count,0)::float) AS quality,
       ((sd.run_s / NULLIF(p.planned_s,0)) *
        ((m.ct_ideal_ms/1000.0 * c.total_count) / NULLIF(sd.run_s,0)) *
        (c.good_count / NULLIF(c.total_count,0)::float))::float AS oee
FROM cycle_agg_hour c
JOIN state_durations_hour sd USING (machine_id, bucket)
JOIN planned_time_hour p USING (machine_id, bucket)
JOIN machines m USING (machine_id);
