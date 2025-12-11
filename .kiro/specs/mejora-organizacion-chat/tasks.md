# Plan de Implementación - Mejora de Organización del Chat

## Descripción

Este plan implementa la mejora de organización del chat dividiendo la interfaz actual en dos apartados: "Mis Viajes" (reservas como viajero) y "Mis Reservas" (reservas en propiedades como anfitrión). Incluye colores distintivos, sistema de filtros, integración con reseñas y mejoras de usabilidad.

## Tareas de Implementación

- [ ] 1. Crear modelos de datos para la nueva estructura
  - Crear modelos para apartados, filtros y información extendida de reservas
  - Definir enums para tipos de apartados y filtros
  - Implementar lógica de categorización de reservas
  - _Requirements: 1.1, 2.1_

- [x] 1.1 Crear modelo ChatApartado


  - Implementar enum TipoApartado (misViajes, misReservas)
  - Definir clase ChatApartado con colores, iconos y listas de reservas
  - Agregar métodos para obtener configuración de colores por tipo
  - _Requirements: 1.1, 2.1, 3.1, 3.2_

- [x] 1.2 Crear modelo FiltroChat


  - Implementar clase FiltroChat con todos los tipos de filtros
  - Definir enums OrdenFecha y EstadoFiltro
  - Agregar métodos de serialización para persistencia
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 1.3 Crear modelo ReservaChatInfo


  - Extender modelo Reserva con información adicional para chat
  - Agregar campos: esVigente, diasRestantes, puedeResenar, yaReseno
  - Implementar cálculos de tiempo y estado de reseñas
  - _Requirements: 7.1, 7.2, 5.1, 5.4_

- [ ]* 1.4 Escribir pruebas unitarias para modelos
  - Probar cálculos de tiempo y estados
  - Verificar lógica de categorización de apartados
  - Validar serialización de filtros
  - _Requirements: 1.1, 1.2, 1.3_

- [ ] 2. Extender ChatRepository con nuevas funcionalidades
  - Agregar métodos para obtener reservas categorizadas
  - Implementar lógica para verificar estado de reseñas
  - Integrar con sistema de reseñas existente
  - _Requirements: 1.2, 1.5, 2.2, 5.1_


- [x] 2.1 Implementar métodos de categorización de reservas

  - Crear obtenerReservasViajeroVigentes()
  - Crear obtenerReservasViajeroPasadas()
  - Crear obtenerReservasAnfitrionVigentes()
  - Crear obtenerReservasAnfitrionPasadas()
  - _Requirements: 1.2, 2.2_

- [x] 2.2 Implementar verificación de estado de reseñas


  - Crear método puedeResenar() que verifique si la reserva está completada
  - Crear método yaReseno() que verifique si ya existe reseña
  - Integrar con tabla de reseñas existente
  - _Requirements: 1.5, 1.6, 5.1, 5.4_


- [x] 2.3 Agregar métodos de información extendida

  - Implementar cálculo de días restantes para reservas vigentes
  - Implementar cálculo de tiempo transcurrido para reservas pasadas
  - Obtener información del otro usuario (foto, calificación)
  - _Requirements: 7.1, 7.2, 7.3_

- [ ]* 2.4 Escribir pruebas unitarias para ChatRepository
  - Probar categorización correcta de reservas
  - Verificar lógica de estado de reseñas
  - Validar cálculos de tiempo
  - _Requirements: 2.1, 2.2, 2.3_

- [ ] 3. Crear servicio de filtros
  - Implementar ChatFilterService para manejar todos los tipos de filtros
  - Crear lógica eficiente de filtrado y ordenamiento
  - Implementar persistencia de filtros por apartado
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 6.2_

- [x] 3.1 Implementar filtros básicos


  - Crear filtrarPorLugar() con búsqueda por nombre y ciudad
  - Crear ordenarPorFecha() con opciones múltiples
  - Crear ordenarAlfabeticamente() ascendente y descendente
  - _Requirements: 4.2, 4.3, 4.4_

- [x] 3.2 Implementar filtros avanzados


  - Crear filtrarPorEstado() para vigentes, pasadas, con reseña pendiente
  - Crear filtrarPorRango() para rangos de fechas específicos
  - Implementar combinación de múltiples filtros
  - _Requirements: 4.5, 4.6_

- [x] 3.3 Implementar persistencia de filtros



  - Crear sistema de guardado de filtros por apartado
  - Implementar restauración de filtros al cambiar apartados
  - Agregar funcionalidad de limpiar filtros
  - _Requirements: 6.2, 4.7_

- [ ]* 3.4 Escribir pruebas unitarias para ChatFilterService
  - Probar cada tipo de filtro individualmente
  - Verificar combinación de múltiples filtros
  - Validar persistencia y restauración
  - _Requirements: 3.1, 3.2, 3.3_



- [x] 4. Refactorizar ChatListaScreen principal


  - Convertir a arquitectura de pestañas con TabController
  - Implementar coordinación entre apartados
  - Agregar barra de filtros y estado de carga

  - _Requirements: 6.1, 6.4, 6.5_


- [ ] 4.1 Implementar estructura de pestañas
  - Agregar TabController para manejar dos apartados
  - Crear TabBar con colores distintivos por apartado

  - Implementar TabBarView con contenido específico
  - _Requirements: 6.1, 3.1, 3.2_


- [ ] 4.2 Agregar sistema de filtros en AppBar
  - Crear botón de filtros en AppBar

  - Implementar indicador de filtros activos
  - Mostrar contador de resultados filtrados

  - _Requirements: 4.6, 4.7_

- [ ] 4.3 Implementar coordinación de estado
  - Manejar carga independiente por apartado
  - Implementar pull-to-refresh para ambos apartados
  - Coordinar actualizaciones después de acciones (reseñas)
  - _Requirements: 6.4, 6.5, 5.3_


- [ ]* 4.4 Escribir pruebas de widget para ChatListaScreen
  - Probar navegación entre pestañas
  - Verificar persistencia de filtros
  - Validar coordinación de estado
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 5. Crear widget ApartadoMisViajes

  - Implementar apartado específico para reservas como viajero
  - Usar colores azules distintivos
  - Mostrar reserva vigente actual y lugares visitados
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [x] 5.1 Implementar sección de reserva vigente

  - Mostrar reserva actual con destaque especial
  - Agregar contador de días restantes
  - Mostrar mensaje "Explora por más lugares" si no hay reservas
  - _Requirements: 1.2, 1.3, 7.1_

- [x] 5.2 Implementar sección de lugares visitados

  - Mostrar reservas pasadas con opción de reseñar
  - Agregar botón "Escribir Reseña" para reservas sin reseñar
  - Mostrar indicador "Reseñado" para reservas ya reseñadas
  - _Requirements: 1.4, 1.5, 1.6, 5.1_

- [x] 5.3 Aplicar esquema de colores azul

  - Usar #2196F3 para elementos principales
  - Aplicar #E3F2FD para fondos y elementos secundarios
  - Usar #FF9800 para indicadores de reseña pendiente
  - _Requirements: 3.1, 3.3, 3.5_

- [ ]* 5.4 Escribir pruebas de widget para ApartadoMisViajes
  - Probar renderizado de reserva vigente

  - Verificar funcionalidad de reseñas
  - Validar esquema de colores
  - _Requirements: 5.1, 5.2, 5.3_


- [x] 6. Crear widget ApartadoMisReservas

  - Implementar apartado específico para reservas como anfitrión
  - Usar colores verdes distintivos
  - Mostrar reservas vigentes y pasadas en propiedades
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_


- [ ] 6.1 Implementar sección de reservas vigentes
  - Mostrar reservas activas en propiedades del usuario
  - Agregar información del huésped y fechas
  - Mostrar contador de días hasta check-in/check-out
  - _Requirements: 2.2, 7.1, 7.3_


- [ ] 6.2 Implementar sección de reservas pasadas
  - Mostrar historial de reservas completadas
  - Agregar información de tiempo transcurrido
  - Mostrar calificaciones recibidas si están disponibles

  - _Requirements: 2.3, 7.2_

- [ ] 6.3 Manejar estados sin contenido
  - Mostrar mensaje para usuarios no anfitriones
  - Agregar botón para convertirse en anfitrión
  - Mostrar mensaje cuando no hay reservas
  - _Requirements: 2.4, 2.5, 6.3_

- [ ] 6.4 Aplicar esquema de colores verde
  - Usar #4CAF50 para elementos principales

  - Aplicar #E8F5E8 para fondos y elementos secundarios
  - Usar colores tenues para reservas pasadas
  - _Requirements: 3.2, 3.4_

- [ ]* 6.5 Escribir pruebas de widget para ApartadoMisReservas
  - Probar renderizado de reservas vigentes y pasadas

  - Verificar manejo de estados sin contenido
  - Validar esquema de colores
  - _Requirements: 6.1, 6.2, 6.3, 6.4_



- [ ] 7. Crear diálogo de filtros
  - Implementar FiltrosChatDialog con todas las opciones de filtrado
  - Crear interfaz intuitiva para selección de filtros
  - Implementar vista previa de resultados
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_


- [ ] 7.1 Implementar interfaz de filtros básicos
  - Crear campo de búsqueda por lugar
  - Agregar selector de orden por fecha
  - Implementar toggle de orden alfabético
  - _Requirements: 4.2, 4.3, 4.4_

- [ ] 7.2 Implementar filtros avanzados
  - Crear selector de estado (vigentes, pasadas, reseña pendiente)
  - Agregar selector de rango de fechas

  - Implementar combinación de múltiples filtros
  - _Requirements: 4.5, 4.6_

- [ ] 7.3 Agregar funcionalidades de usabilidad
  - Mostrar contador de resultados en tiempo real
  - Implementar botón "Limpiar filtros"

  - Agregar vista previa de filtros aplicados
  - _Requirements: 4.6, 4.7_

- [ ]* 7.4 Escribir pruebas de widget para FiltrosChatDialog
  - Probar aplicación de cada tipo de filtro

  - Verificar combinación de filtros múltiples
  - Validar funcionalidad de limpiar filtros
  - _Requirements: 7.1, 7.2, 7.3_



- [ ] 8. Crear widgets de tarjetas de reserva especializadas
  - Implementar ReservaCardViajero y ReservaCardAnfitrion
  - Aplicar colores distintivos y información contextual
  - Integrar funcionalidades específicas por rol
  - _Requirements: 3.1, 3.2, 7.1, 7.2, 7.3_

- [ ] 8.1 Crear ReservaCardViajero
  - Diseñar tarjeta con colores azules
  - Agregar botón de reseña para reservas pasadas
  - Mostrar información relevante para viajeros
  - _Requirements: 3.1, 1.5, 7.1, 7.3_

- [ ] 8.2 Crear ReservaCardAnfitrion
  - Diseñar tarjeta con colores verdes
  - Mostrar información del huésped
  - Agregar detalles relevantes para anfitriones
  - _Requirements: 3.2, 7.1, 7.2, 7.3_

- [ ] 8.3 Implementar estados visuales
  - Aplicar opacidad reducida para reservas pasadas
  - Usar bordes intensos para reservas vigentes
  - Agregar indicadores de estado especiales
  - _Requirements: 3.3, 3.4, 3.5_

- [ ]* 8.4 Escribir pruebas de widget para tarjetas de reserva
  - Probar renderizado correcto por tipo de usuario
  - Verificar aplicación de colores distintivos
  - Validar funcionalidades específicas
  - _Requirements: 8.1, 8.2, 8.3_

- [ ] 9. Integrar con sistema de reseñas existente
  - Conectar funcionalidad de reseñas desde el chat
  - Implementar navegación fluida al formulario de reseñas
  - Actualizar estado después de crear reseña
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ] 9.1 Implementar navegación a reseñas
  - Crear método para abrir formulario de reseña con datos pre-cargados
  - Implementar callback para actualizar estado después de reseñar
  - Manejar errores de navegación y envío
  - _Requirements: 5.2, 5.3_

- [ ] 9.2 Actualizar estado de reseñas en tiempo real
  - Implementar listener para cambios en reseñas
  - Actualizar UI inmediatamente después de crear reseña
  - Sincronizar estado entre apartados si es necesario
  - _Requirements: 5.3, 5.4_

- [ ]* 9.3 Escribir pruebas de integración con reseñas
  - Probar navegación al formulario de reseñas
  - Verificar actualización de estado después de reseñar
  - Validar prevención de reseñas duplicadas
  - _Requirements: 9.1, 9.2_

- [ ] 10. Implementar optimizaciones de rendimiento
  - Agregar paginación para listas grandes de reservas
  - Implementar caché local para mejorar velocidad
  - Optimizar filtros para grandes volúmenes de datos
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [ ] 10.1 Implementar paginación lazy
  - Crear carga por páginas para reservas
  - Implementar scroll infinito o botones de navegación
  - Priorizar carga de reservas vigentes
  - _Requirements: 8.1, 8.2_

- [ ] 10.2 Implementar sistema de caché
  - Crear caché local para reservas y filtros
  - Implementar estrategia de invalidación de caché
  - Mostrar contenido en caché durante carga
  - _Requirements: 8.4, 8.5_

- [ ] 10.3 Optimizar procesamiento de filtros
  - Implementar filtros asíncronos para no bloquear UI
  - Crear índices en memoria para búsquedas rápidas
  - Optimizar algoritmos de ordenamiento
  - _Requirements: 8.3, 8.6_

- [ ]* 10.4 Escribir pruebas de rendimiento
  - Probar comportamiento con grandes volúmenes de datos
  - Verificar eficiencia de filtros y paginación
  - Validar uso de memoria y caché
  - _Requirements: 10.1, 10.2, 10.3_

- [ ]* 11. Escribir pruebas de propiedades (Property-Based Testing)
  - Implementar pruebas de propiedades para validar comportamientos universales
  - Usar faker para generar datos de prueba aleatorios
  - Configurar 100+ iteraciones por prueba de propiedad
  - _Requirements: Todas las propiedades de correctness_

- [ ]* 11.1 Escribir prueba de propiedad para separación de apartados
  - **Property 1: Separación correcta de apartados**
  - Generar reservas aleatorias con diferentes roles de usuario
  - Verificar que las reservas se categoricen correctamente por apartado
  - **Validates: Requirements 1.1, 2.1**

- [ ]* 11.2 Escribir prueba de propiedad para colores distintivos
  - **Property 2: Colores distintivos por apartado**
  - Generar apartados aleatorios y verificar esquemas de color
  - Validar consistencia de colores en todos los elementos
  - **Validates: Requirements 3.1, 3.2**

- [ ]* 11.3 Escribir prueba de propiedad para control de reseñas
  - **Property 4: Control de reseñas único**
  - Generar reservas completadas aleatorias
  - Verificar que solo se permita reseñar una vez por reserva
  - **Validates: Requirements 1.5, 1.6, 5.1, 5.4**

- [ ]* 11.4 Escribir prueba de propiedad para filtrado consistente
  - **Property 5: Filtrado consistente**
  - Generar reservas aleatorias y aplicar filtros aleatorios
  - Verificar que todos los resultados cumplan los criterios
  - **Validates: Requirements 4.2, 4.3, 4.4, 4.5**

- [ ]* 11.5 Escribir pruebas de propiedades adicionales
  - Implementar pruebas para las 6 propiedades restantes
  - Cubrir ordenamiento temporal, persistencia de filtros, etc.
  - Asegurar cobertura completa de comportamientos universales
  - **Validates: Todas las propiedades de correctness restantes**

- [x] 12. Checkpoint - Verificar funcionamiento completo



  - Asegurar que todas las pruebas pasen
  - Verificar integración correcta con sistema existente
  - Validar que no se rompan funcionalidades existentes
  - Preguntar al usuario si surgen dudas

- [x] 13. Refinamiento final y optimización



  - Ajustar detalles de UI según feedback
  - Optimizar rendimiento si es necesario
  - Documentar nuevas funcionalidades
  - _Requirements: Todos_

- [x] 13.1 Ajustes finales de UI/UX


  - Refinar colores y espaciados
  - Mejorar animaciones y transiciones
  - Ajustar textos y mensajes de estado
  - _Requirements: UI/UX general_



- [ ] 13.2 Optimización final de rendimiento
  - Revisar y optimizar consultas a base de datos
  - Mejorar algoritmos de filtrado si es necesario
  - Optimizar uso de memoria
  - _Requirements: 8.1, 8.2, 8.3_

- [ ]* 13.3 Documentación técnica
  - Documentar nuevos componentes y servicios
  - Crear guía de uso para desarrolladores
  - Actualizar documentación de arquitectura
  - _Requirements: Documentación_

- [ ] 14. Checkpoint final - Asegurar que todas las pruebas pasen
  - Ejecutar suite completa de pruebas unitarias y de propiedades
  - Verificar que no hay regresiones en funcionalidad existente
  - Confirmar que todas las propiedades de correctness se cumplen
  - Preguntar al usuario si surgen dudas