-- Eventos de estado (últimas 24 horas)
INSERT INTO event_state (time, machine_id, state, reason_code, order_id, lot_id, seq, source) VALUES
(now() - interval '20 hours', 'test_cnc_01', 'RUN', NULL, 'ORD001', 'LOT001', 1, 'plc'),
(now() - interval '19 hours', 'test_cnc_01', 'STOP', 'LUNCH', 'ORD001', 'LOT001', 2, 'plc'),
(now() - interval '18 hours', 'test_cnc_01', 'RUN', NULL, 'ORD001', 'LOT001', 3, 'plc'),
(now() - interval '12 hours', 'test_cnc_01', 'IDLE', NULL, NULL, NULL, 4, 'plc'),
(now() - interval '10 hours', 'test_cnc_02', 'RUN', NULL, 'ORD002', 'LOT002', 1, 'plc'),
(now() - interval '8 hours', 'test_cnc_02', 'RUN', NULL, 'ORD002', 'LOT002', 2, 'plc')
ON CONFLICT DO NOTHING;

-- Eventos de ciclo
INSERT INTO event_cycle (time, machine_id, order_id, lot_id, result, good, scrap, scrap_reason_code, ct_ideal_ms, ct_actual_ms, seq, source) VALUES
(now() - interval '19.5 hours', 'test_cnc_01', 'ORD001', 'LOT001', 'GOOD', 1, 0, NULL, 1200, 1180, 1, 'plc'),
(now() - interval '19 hours', 'test_cnc_01', 'ORD001', 'LOT001', 'GOOD', 1, 0, NULL, 1200, 1200, 2, 'plc'),
(now() - interval '18.5 hours', 'test_cnc_01', 'ORD001', 'LOT001', 'SCRAP', 0, 1, 'DENT', 1200, 1300, 3, 'plc'),
(now() - interval '9.5 hours', 'test_cnc_02', 'ORD002', 'LOT002', 'GOOD', 1, 0, NULL, 1500, 1500, 1, 'plc'),
(now() - interval '9 hours', 'test_cnc_02', 'ORD002', 'LOT002', 'GOOD', 1, 0, NULL, 1500, 1480, 2, 'plc')
ON CONFLICT DO NOTHING;

-- Alarmas
INSERT INTO event_alarm (time, machine_id, alarm_code, severity, text, active, seq, source) VALUES
(now() - interval '18 hours', 'test_cnc_01', 'TEMP_HIGH', 'warn', 'Temperatura alta', true, 1, 'plc'),
(now() - interval '17.5 hours', 'test_cnc_01', 'TEMP_HIGH', 'warn', 'Temperatura normal', false, 2, 'plc')
ON CONFLICT DO NOTHING;