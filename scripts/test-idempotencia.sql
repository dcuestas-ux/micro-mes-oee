-- Test de idempotencia: insertar duplicados
INSERT INTO machines (machine_id, name, ct_ideal_ms) VALUES 
  ('test_cnc', 'Test Machine', 1200)
ON CONFLICT DO NOTHING;

-- Repetir: debería no hacer nada
INSERT INTO machines (machine_id, name, ct_ideal_ms) VALUES 
  ('test_cnc', 'Test Machine', 1200)
ON CONFLICT DO NOTHING;

-- Verificar: solo un registro
SELECT COUNT(*) FROM machines WHERE machine_id = 'test_cnc';
-- Expected: 1

-- Cleanup
DELETE FROM machines WHERE machine_id = 'test_cnc';