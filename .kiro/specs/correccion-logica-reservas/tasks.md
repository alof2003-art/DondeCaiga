# Implementation Plan

- [x] 1. Actualizar ReservaRepository con nuevas validaciones


  - Agregar método `verificarReservasActivas()` para detectar reservas activas del usuario
  - Mejorar método `verificarDisponibilidad()` con lógica precisa de solapamiento de fechas
  - Asegurar que solo se consideren reservas con estado 'pendiente' o 'confirmada'
  - _Requirements: 1.1, 1.4, 2.1, 2.4, 3.1, 3.3_



- [ ] 2. Actualizar ReservaCalendarioScreen con validación en dos pasos
  - Modificar método `_crearReserva()` para agregar validación de reservas activas
  - Implementar validación en orden: primero reservas activas, luego disponibilidad
  - Agregar mensajes de error claros y específicos para cada caso


  - Usar colores apropiados (naranja para advertencias)
  - _Requirements: 1.2, 2.2, 4.1, 4.2, 4.3, 4.4_

- [x] 3. Checkpoint - Probar manualmente todos los casos


  - Ensure all tests pass, ask the user if questions arise.
