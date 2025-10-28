# Decisiones Fase 0 (log)

- 2025-10-27: Naming MQTT `site/<sede>/line/<linea>/machine/<equipo>/v1/<stream>`.
- 2025-10-27: Streams `state/meta` retained; `cycle/alarm` no-retained. QoS: 1.
- 2025-10-27: JSON base con `msg_ver, ts, machine_id, event, seq, source`.
- 2025-10-27: TimescaleDB para series de tiempo + vistas continuas.
