# Requirements Document

## Introduction

Este documento especifica los requisitos para corregir la lógica de reservas en la aplicación "Donde Caiga". Actualmente existen dos problemas críticos:
1. Los usuarios pueden crear múltiples reservas simultáneas
2. La validación de disponibilidad bloquea fechas que deberían estar disponibles

## Glossary

- **Sistema**: La aplicación móvil "Donde Caiga"
- **Viajero**: Usuario que busca y reserva alojamientos
- **Reserva Activa**: Reserva con estado 'pendiente' o 'confirmada'
- **Reserva Futura**: Reserva cuya fecha de inicio es posterior a la fecha actual
- **Conflicto de Fechas**: Cuando dos reservas tienen fechas que se solapan
- **Disponibilidad**: Fechas en las que una propiedad puede ser reservada

## Requirements

### Requirement 1

**User Story:** Como viajero, quiero que el sistema me impida crear múltiples reservas simultáneas, para evitar confusiones y conflictos de fechas.

#### Acceptance Criteria

1. WHEN un viajero intenta crear una reserva THEN el sistema SHALL verificar si el viajero tiene reservas activas futuras
2. WHEN un viajero tiene una reserva activa futura THEN el sistema SHALL mostrar un mensaje indicando que debe completar su reserva actual antes de crear una nueva
3. WHEN un viajero tiene solo reservas pasadas o completadas THEN el sistema SHALL permitir crear una nueva reserva
4. WHEN el sistema valida reservas activas THEN el sistema SHALL considerar solo reservas con estado 'pendiente' o 'confirmada'

### Requirement 2

**User Story:** Como viajero, quiero poder reservar una propiedad en fechas disponibles, incluso si otros usuarios tienen reservas en fechas diferentes.

#### Acceptance Criteria

1. WHEN un viajero selecciona fechas para reservar THEN el sistema SHALL verificar disponibilidad solo para esas fechas específicas
2. WHEN existe una reserva en fechas diferentes THEN el sistema SHALL permitir la nueva reserva sin conflicto
3. WHEN existe solapamiento de fechas THEN el sistema SHALL rechazar la reserva y mostrar un mensaje claro
4. WHEN el sistema valida disponibilidad THEN el sistema SHALL considerar solo reservas con estado 'pendiente' o 'confirmada'

### Requirement 3

**User Story:** Como desarrollador, quiero que la lógica de validación de fechas sea precisa, para evitar bloqueos incorrectos de disponibilidad.

#### Acceptance Criteria

1. WHEN el sistema compara fechas THEN el sistema SHALL usar comparación inclusiva de rangos de fechas
2. WHEN el sistema detecta solapamiento THEN el sistema SHALL verificar que al menos un día se solape entre las reservas
3. WHEN el sistema valida disponibilidad THEN el sistema SHALL excluir reservas rechazadas, canceladas o completadas
4. WHEN el sistema marca fechas ocupadas THEN el sistema SHALL incluir solo los días exactos de las reservas activas

### Requirement 4

**User Story:** Como usuario del sistema, quiero recibir mensajes claros cuando no puedo realizar una acción, para entender qué debo hacer.

#### Acceptance Criteria

1. WHEN un viajero tiene una reserva activa THEN el sistema SHALL mostrar el mensaje "Ya tienes una reserva activa. Completa tu reserva actual antes de crear una nueva"
2. WHEN hay conflicto de fechas THEN el sistema SHALL mostrar el mensaje "Las fechas seleccionadas no están disponibles. Por favor selecciona otras fechas"
3. WHEN el sistema muestra un error THEN el sistema SHALL usar colores apropiados (naranja para advertencias, rojo para errores)
4. WHEN el sistema valida una acción THEN el sistema SHALL proporcionar retroalimentación inmediata al usuario
