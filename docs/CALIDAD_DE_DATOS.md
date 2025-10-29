# Reglas de Calidad de Datos

## Validación de eventos

### 1. Timestamps ISO 8601

- Formato: `YYYY-MM-DDTHH:MM:SS+HH:MM`
- Zona horaria: Siempre UTC o con offset explícito
- No aceptar: timestamps naivos sin zona

### 2. Secuencia temporal por máquina

- `seq` debe ser monotónicamente creciente por máquina_id
- No se permiten gaps o saltos atrás
- Validar: `ORDER BY machine_id, seq`

### 3. Estados válidos (event_state)

- `IDLE` - máquina inactiva
- `RUN` - produciendo
- `STOP` - parada planificada
- `FAULT` - falla
- `SETUP` - configuración

### 4. Resultados válidos (event_cycle)

- `GOOD` - pieza aceptada
- `SCRAP` - pieza rechazada
- Los flags `good` y `scrap` deben ser mutuamente excluyentes

### 5. Severidad de alarmas (event_alarm)

- `info` - informativa
- `warn` - advertencia
- `fault` - falla crítica

### 6. Integridad referencial

- `machine_id` debe existir en `machines`
- `order_id` debe existir en `orders` (si es provisto)
- `lot_id` debe existir en `lots` (si es provisto)

## Checks automáticos

```sql
-- Detectar duplicados
SELECT machine_id, seq, COUNT(*) 
FROM event_state 
GROUP BY machine_id, seq 
HAVING COUNT(*) > 1;

-- Detectar gaps en sequencia
SELECT machine_id, seq, 
       LEAD(seq) OVER (PARTITION BY machine_id ORDER BY seq) - seq AS gap
FROM event_state
WHERE LEAD(seq) OVER (PARTITION BY machine_id ORDER BY seq) - seq > 1;

-- Validar máquinas
SELECT e.machine_id 
FROM event_state e
LEFT JOIN machines m ON e.machine_id = m.machine_id
WHERE m.machine_id IS NULL;
```
