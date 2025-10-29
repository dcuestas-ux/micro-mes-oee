INSERT INTO machines (machine_id, name, ct_ideal_ms) VALUES
  ('test_cnc_01', 'Test CNC 01', 1200),
  ('test_cnc_02', 'Test CNC 02', 1500)
ON CONFLICT DO NOTHING;