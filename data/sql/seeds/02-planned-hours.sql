-- Horas planificadas (requiere máquinas en la tabla)
WITH hours AS (
  SELECT generate_series(
           date_trunc('hour', now() at time zone 'UTC' - interval '3 days'),
           date_trunc('hour', now() at time zone 'UTC'),
           interval '1 hour'
         ) AS bucket
)
INSERT INTO planned_time_hour (bucket, machine_id, planned_s)
SELECT h.bucket, m.machine_id, 3600
FROM hours h
CROSS JOIN machines m
JOIN shift_calendar s
  ON (EXTRACT(ISODOW FROM (h.bucket at time zone s.timezone)) = ANY(s.dow)
      AND (h.bucket at time zone s.timezone)::time
          BETWEEN s.start_local AND (s.start_local + (s.duration_min||' minutes')::interval))
ON CONFLICT (bucket, machine_id) DO NOTHING;