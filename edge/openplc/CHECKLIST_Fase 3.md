# Checklist Fase 3

## 1. ICD Modbus

- [ ] Tabla de registros definida
- [ ] Enumeraciones acordadas
- [ ] Endianness especificado
- [ ] Revisado y aprobado

## 2. Prueba Modbus

- [ ] OpenPLC corriendo con Modbus TCP enabled
- [ ] Registros mapeados en OpenPLC
- [ ] `modpoll -m tcp localhost 40001 6` devuelve valores
- [ ] Node-RED lee correctamente (screenshot)

## 3. Detección de Ciclo

- [ ] Criterio operativo definido (ej: "delta cycle_count > 0")
- [ ] Script de prueba escrito
- [ ] Verificado manualmente 5+ veces

## 4. MQTT Contract

- [ ] Topics definidos (`mfg/{machine_id}/{state|cycle|alarm}`)
- [ ] Formato JSON especificado
- [ ] `mosquitto_sub -t 'mfg/#'` muestra eventos

## DoD (Definition of Done)

- ✅ Lectura Modbus estable (sin errores 5+ minutos)
- ✅ Mosquitto recibe eventos correctos (state retained, cycle no)
- ✅ Documentación actualizada
