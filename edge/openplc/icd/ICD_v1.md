# ICD Modbus - OpenPLC

## Tabla de Registros (Holding Registers)


| Dirección | Tipo | Variable OpenPLC | Descripción       | Rango   | Unidad |
| ------------ | ------ | ------------------ | -------------------- | --------- | -------- |
| 40001      | WORD | state            | Estado máquina    | 0-5     | enum   |
| 40002      | WORD | cycle_count      | Contador ciclos    | 0-65535 | piezas |
| 40003      | WORD | good_count       | Piezas buenas      | 0-65535 | piezas |
| 40004      | WORD | scrap_count      | Piezas defectuosas | 0-65535 | piezas |
| 40005      | WORD | temperature      | Temperatura        | 0-100   | °C    |
| 40006      | WORD | order_id_hi      | Order ID (part 1)  | -       | -      |
| 40007      | WORD | order_id_lo      | Order ID (part 2)  | -       | -      |

## Enumeraciones

**State (40001):**

- 0: IDLE
- 1: RUN
- 2: STOP
- 3: FAULT
- 4: SETUP

## Notas

- Endianness: Big-Endian
- Frecuencia lectura: 100ms
- Timeout conexión: 5s
