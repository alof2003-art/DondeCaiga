# Requirements Document

## Introduction

Este documento especifica los requisitos para mejorar la visualización del calendario de reservas, haciendo más evidente qué fechas están ocupadas y proporcionando retroalimentación clara al usuario.

## Glossary

- **Sistema**: La aplicación móvil "Donde Caiga"
- **Calendario de Reservas**: Interfaz donde el usuario selecciona fechas para reservar
- **Fecha Ocupada**: Día en el que ya existe una reserva activa (pendiente o confirmada)
- **Fecha Disponible**: Día en el que no hay reservas activas
- **Indicador Visual**: Elemento gráfico que muestra el estado de una fecha

## Requirements

### Requirement 1

**User Story:** Como viajero, quiero ver claramente qué fechas están ocupadas en el calendario, para saber rápidamente cuándo puedo reservar.

#### Acceptance Criteria

1. WHEN el calendario se muestra THEN el sistema SHALL marcar las fechas ocupadas con color rojo
2. WHEN una fecha está ocupada THEN el sistema SHALL aplicar un estilo visual distintivo (fondo rojo, texto blanco)
3. WHEN una fecha está disponible THEN el sistema SHALL mantener el estilo normal del calendario
4. WHEN el calendario carga THEN el sistema SHALL mostrar todas las fechas ocupadas inmediatamente

### Requirement 2

**User Story:** Como viajero, quiero recibir retroalimentación cuando intento seleccionar una fecha ocupada, para entender por qué no puedo reservar ese día.

#### Acceptance Criteria

1. WHEN un usuario toca una fecha ocupada THEN el sistema SHALL mostrar un mensaje informativo
2. WHEN se muestra el mensaje THEN el sistema SHALL indicar "Esta fecha ya está reservada. Por favor selecciona otra fecha"
3. WHEN se muestra el mensaje THEN el sistema SHALL usar color naranja para indicar advertencia
4. WHEN un usuario toca una fecha ocupada THEN el sistema SHALL NO permitir seleccionarla

### Requirement 3

**User Story:** Como usuario del sistema, quiero que el calendario sea intuitivo y fácil de entender, para poder hacer reservas sin confusión.

#### Acceptance Criteria

1. WHEN el calendario se muestra THEN el sistema SHALL usar colores consistentes (rojo = ocupado, verde = seleccionado, gris = pasado)
2. WHEN hay múltiples días ocupados consecutivos THEN el sistema SHALL marcar cada día individualmente en rojo
3. WHEN el usuario selecciona un rango de fechas THEN el sistema SHALL validar que ninguna fecha del rango esté ocupada
4. WHEN el calendario muestra fechas THEN el sistema SHALL mantener buen contraste y legibilidad
