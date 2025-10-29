INSERT INTO shift_calendar (name, dow, start_local, duration_min, timezone) VALUES
 ('Turno A', ARRAY[1,2,3,4,5,6], '06:00', 480, 'America/Bogota'),
 ('Turno B', ARRAY[1,2,3,4,5,6], '14:00', 480, 'America/Bogota'),
 ('Turno C', ARRAY[1,2,3,4,5,6], '22:00', 480, 'America/Bogota')
ON CONFLICT DO NOTHING;