# Plan de Implementación - Gestión de Usuarios por Administrador

## Descripción

Este plan implementa el sistema de gestión de usuarios por administrador que permite degradar anfitriones a viajeros, bloquear/desbloquear cuentas, y mantener un historial de auditoría. Se integra con la interfaz de administración existente (`AdminDashboardScreen`) y respeta las restricciones de seguridad establecidas.

## Tareas de Implementación

- [x] 1. Crear modelos de datos y tabla de auditoría


  - Crear modelos para acciones administrativas y logs de auditoría
  - Implementar tabla `admin_audit_log` en la base de datos
  - Definir tipos de acciones y estructuras de datos
  - _Requirements: 7.1, 7.3_



- [ ] 1.1 Crear modelo AdminAction
  - Implementar clase `AdminAction` con campos: adminId, targetUserId, actionType, actionData, reason, timestamp
  - Definir constantes para tipos de acción: 'degrade_role', 'block_account', 'unblock_account'
  - Agregar métodos de serialización toJson() y fromJson()


  - _Requirements: 7.1_

- [ ] 1.2 Crear modelo AuditLog
  - Implementar clase `AuditLog` con campos completos de auditoría


  - Incluir información del administrador y usuario objetivo
  - Agregar campo wasSuccessful para rastrear éxito/fallo de acciones
  - _Requirements: 7.3_



- [ ] 1.3 Crear modelo AdminActionResult
  - Implementar clase para resultados de operaciones administrativas
  - Incluir campos: success, message, data, errorCode
  - Definir códigos de error estándar para diferentes tipos de fallas
  - _Requirements: 9.1, 9.2_

- [ ] 1.4 Escribir pruebas unitarias para modelos de datos
  - Crear pruebas para serialización/deserialización de AdminAction
  - Probar validación de campos requeridos en AuditLog
  - Verificar manejo de errores en AdminActionResult
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 2. Implementar tabla de auditoría en base de datos


  - Crear script SQL para tabla `admin_audit_log`
  - Implementar índices para optimizar consultas
  - Configurar políticas RLS para acceso de administradores
  - _Requirements: 7.1_



- [ ] 2.1 Crear script SQL para tabla admin_audit_log
  - Definir estructura de tabla con campos UUID, referencias y JSONB
  - Crear índices en admin_id, target_user_id, action_type, created_at
  - Agregar comentarios de documentación para cada campo



  - _Requirements: 7.1_

- [ ] 2.2 Configurar políticas RLS para auditoría
  - Crear política para que solo administradores puedan insertar registros
  - Permitir lectura de auditoría solo a administradores

  - Implementar validación de permisos a nivel de base de datos
  - _Requirements: 6.1, 7.2_

- [ ]* 2.3 Escribir pruebas de integración para base de datos
  - Probar inserción de registros de auditoría
  - Verificar funcionamiento de políticas RLS

  - Validar rendimiento de consultas con índices
  - _Requirements: 2.1, 2.2_

- [ ] 3. Extender AdminRepository con funciones de gestión
  - Agregar métodos para degradar roles, bloquear/desbloquear usuarios
  - Implementar validaciones de permisos y seguridad

  - Integrar con sistema de auditoría existente
  - _Requirements: 3.3, 4.3, 5.3, 6.2_

- [ ] 3.1 Implementar método degradarAnfitrionAViajero
  - Validar que usuario objetivo sea anfitrión y no administrador

  - Actualizar rol_id de 2 a 1 en users_profiles
  - Crear nueva solicitud de anfitrión en estado 'pendiente'
  - Desactivar todas las propiedades del usuario
  - _Requirements: 3.3, 3.4, 3.5, 10.2, 10.3_



- [ ] 3.2 Implementar método bloquearCuentaUsuario
  - Validar permisos y que usuario no sea administrador
  - Cambiar estado_cuenta de 'activo' a 'bloqueado'

  - Cancelar reservas pendientes del usuario
  - Desactivar propiedades si es anfitrión
  - _Requirements: 4.3, 10.4, 10.5_

- [ ] 3.3 Implementar método desbloquearCuentaUsuario
  - Validar permisos administrativos
  - Cambiar estado_cuenta de 'bloqueado' a 'activo'
  - Registrar acción en auditoría

  - _Requirements: 5.3, 5.5_

- [ ] 3.4 Implementar validaciones de seguridad
  - Crear método validarPermisosAdmin para verificar permisos
  - Implementar prevención de auto-gestión


  - Validar que usuario objetivo no sea administrador
  - _Requirements: 6.2, 6.3, 6.4, 6.6_



- [x] 3.5 Escribir pruebas unitarias para AdminRepository

  - Probar degradación de anfitrión con creación de solicitud
  - Verificar bloqueo/desbloqueo de cuentas
  - Validar todas las restricciones de seguridad
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 4. Crear AuditRepository para historial de acciones
  - Implementar repositorio para gestión de logs de auditoría
  - Agregar métodos para registrar y consultar acciones
  - Implementar filtros y paginación para el historial
  - _Requirements: 7.1, 7.2, 7.5, 7.6_

- [ ] 4.1 Implementar método registrarAccionAdmin
  - Crear función para insertar registros de auditoría
  - Incluir manejo de errores y validación de datos
  - Registrar tanto éxitos como fallos de acciones
  - _Requirements: 7.1_

- [ ] 4.2 Implementar método obtenerHistorialAuditoria
  - Crear consulta con filtros por tipo de acción y fechas
  - Implementar paginación para grandes volúmenes de datos
  - Ordenar resultados por fecha (más recientes primero)
  - _Requirements: 7.2, 7.4, 7.5, 7.6_

- [ ] 4.3 Escribir pruebas unitarias para AuditRepository
  - Probar registro de diferentes tipos de acciones
  - Verificar funcionamiento de filtros y paginación
  - Validar ordenamiento correcto del historial
  - _Requirements: 4.1, 4.2_

- [x] 5. Extender AdminDashboardScreen con funciones de gestión


  - Mejorar diálogo de detalle de usuario con botones de acción
  - Agregar búsqueda y filtros a la lista de usuarios
  - Implementar navegación al historial de auditoría
  - _Requirements: 1.1, 1.2, 2.1, 2.2_

- [x] 5.1 Mejorar diálogo _mostrarDetalleUsuario


  - Agregar botones de acción según rol y estado del usuario
  - Mostrar "Degradar a Viajero" solo para anfitriones
  - Mostrar "Bloquear/Desbloquear" según estado actual
  - Excluir opciones para administradores
  - _Requirements: 1.2, 3.1, 4.1, 5.1, 6.1_

- [x] 5.2 Implementar búsqueda y filtros de usuarios


  - Agregar barra de búsqueda en sección de usuarios
  - Implementar filtros por rol (viajero/anfitrión)
  - Agregar filtro por estado (activo/bloqueado)
  - Filtrar en tiempo real mientras el usuario escribe
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ] 5.3 Agregar navegación al historial de auditoría
  - Crear botón para acceder al historial desde el panel principal
  - Implementar navegación a AuditHistoryScreen
  - Mostrar contador de acciones recientes si es posible
  - _Requirements: 7.2_

- [ ]* 5.4 Escribir pruebas de widget para AdminDashboardScreen
  - Probar renderizado de botones de acción según contexto
  - Verificar funcionamiento de búsqueda y filtros
  - Validar navegación al historial de auditoría
  - _Requirements: 5.1, 5.2, 5.3_

- [ ] 6. Crear diálogos de confirmación y acción
  - Implementar UserActionDialog para confirmaciones
  - Crear ConfirmationDialog reutilizable
  - Agregar validación de entrada para motivos de bloqueo
  - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [ ] 6.1 Crear UserActionDialog
  - Implementar diálogo específico para acciones de usuario
  - Incluir campos para motivo cuando sea requerido
  - Mostrar información clara sobre la acción a realizar
  - Validar entrada antes de permitir confirmación
  - _Requirements: 8.1, 8.2, 8.3_

- [ ] 6.2 Crear ConfirmationDialog reutilizable
  - Implementar diálogo genérico de confirmación
  - Incluir botones "Confirmar" y "Cancelar" estándar
  - Permitir personalización de título y mensaje
  - Agregar indicador de carga durante procesamiento
  - _Requirements: 8.4, 8.5, 8.6_

- [x]* 6.3 Escribir pruebas de widget para diálogos



  - Probar renderizado correcto de campos y botones
  - Verificar validación de entrada en campos requeridos
  - Validar comportamiento de confirmación y cancelación
  - _Requirements: 6.1, 6.2_



- [ ] 7. Implementar AuditHistoryScreen
  - Crear pantalla para mostrar historial completo de auditoría
  - Implementar filtros por tipo de acción y rango de fechas
  - Agregar paginación para manejar grandes volúmenes


  - _Requirements: 7.2, 7.3, 7.4, 7.5, 7.6_

- [ ] 7.1 Crear interfaz de AuditHistoryScreen
  - Implementar lista de entradas de auditoría con información completa


  - Mostrar fecha/hora, administrador, usuario afectado, acción y motivo
  - Usar iconos y colores para diferenciar tipos de acciones
  - _Requirements: 7.2, 7.3_

- [ ] 7.2 Implementar filtros de historial
  - Agregar filtros por tipo de acción (degradación, bloqueo, desbloqueo)
  - Implementar selector de rango de fechas
  - Permitir combinación de múltiples filtros
  - _Requirements: 7.5, 7.6_

- [ ] 7.3 Implementar paginación de historial
  - Agregar carga por páginas para mejorar rendimiento
  - Implementar scroll infinito o botones de navegación
  - Mostrar indicadores de carga durante consultas
  - _Requirements: 7.4_

- [ ]* 7.4 Escribir pruebas de widget para AuditHistoryScreen
  - Probar renderizado de lista de auditoría
  - Verificar funcionamiento de filtros
  - Validar comportamiento de paginación
  - _Requirements: 7.1, 7.2, 7.3_

- [ ] 8. Implementar manejo de errores y retroalimentación
  - Crear UserManagementErrorHandler para errores específicos
  - Implementar mensajes de éxito y error consistentes
  - Agregar validación de conectividad y permisos
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [ ] 8.1 Crear UserManagementErrorHandler
  - Implementar manejo específico para errores de permisos
  - Agregar manejo de errores de validación y conectividad
  - Definir mensajes de error claros y específicos
  - _Requirements: 9.2, 9.3, 9.4, 9.5, 9.6_

- [ ] 8.2 Implementar sistema de mensajes de retroalimentación
  - Crear mensajes de éxito verdes con detalles específicos
  - Implementar mensajes de error rojos con información del problema
  - Agregar indicadores de carga durante operaciones
  - _Requirements: 9.1, 9.2, 8.6_

- [ ] 8.3 Escribir pruebas unitarias para manejo de errores
  - Probar diferentes tipos de errores y sus mensajes
  - Verificar comportamiento con errores de conectividad
  - Validar manejo de errores de permisos
  - _Requirements: 8.1, 8.2_

- [ ] 9. Implementar notificaciones por email
  - Integrar con sistema de email de Supabase
  - Crear plantillas de email para diferentes acciones
  - Implementar envío asíncrono de notificaciones
  - _Requirements: 10.7_

- [ ] 9.1 Crear servicio de notificaciones administrativas
  - Implementar función para enviar emails de cambios de cuenta
  - Crear plantillas para degradación de rol, bloqueo y desbloqueo
  - Incluir información relevante en cada tipo de notificación
  - _Requirements: 10.7_

- [ ] 9.2 Integrar notificaciones con acciones administrativas
  - Agregar llamadas a notificaciones en cada acción exitosa
  - Implementar envío asíncrono para no bloquear UI
  - Manejar errores de envío sin afectar la acción principal
  - _Requirements: 10.7_

- [ ]* 9.3 Escribir pruebas unitarias para notificaciones
  - Probar envío de diferentes tipos de notificaciones
  - Verificar contenido correcto de plantillas de email
  - Validar manejo de errores en envío de emails
  - _Requirements: 9.1, 9.2_

- [ ]* 10. Escribir pruebas de propiedades (Property-Based Testing)
  - Implementar pruebas de propiedades para validar comportamientos universales
  - Usar faker para generar datos de prueba aleatorios
  - Configurar 100+ iteraciones por prueba de propiedad
  - _Requirements: Todas las propiedades de correctness_

- [ ]* 10.1 Escribir prueba de propiedad para exclusión de administradores
  - **Property 1: Exclusión de administradores en lista**
  - Generar usuarios aleatorios con diferentes roles incluyendo administradores
  - Verificar que ningún usuario con rol_id = 3 aparezca en lista gestionable
  - **Validates: Requirements 1.3, 6.1**

- [ ]* 10.2 Escribir prueba de propiedad para degradación con re-verificación
  - **Property 7: Degradación de anfitrión con re-verificación**
  - Generar anfitriones aleatorios y degradar a viajeros
  - Verificar que rol cambie a 1 y se cree solicitud de anfitrión pendiente
  - **Validates: Requirements 3.3, 3.4, 3.5**

- [ ]* 10.3 Escribir prueba de propiedad para bloqueo de acceso
  - **Property 9: Bloqueo impide acceso**
  - Generar usuarios aleatorios y bloquear cuentas
  - Verificar que usuarios bloqueados no puedan iniciar sesión
  - **Validates: Requirements 4.4**

- [ ]* 10.4 Escribir prueba de propiedad para validación de permisos
  - **Property 11: Validación de permisos administrativos**
  - Generar intentos de gestión con diferentes combinaciones de usuarios
  - Verificar que administradores no puedan gestionar otros administradores
  - **Validates: Requirements 6.2, 6.3, 6.4**

- [ ]* 10.5 Escribir prueba de propiedad para registro de auditoría
  - **Property 13: Registro de auditoría completo**
  - Generar acciones administrativas aleatorias
  - Verificar que todas las acciones se registren correctamente en auditoría
  - **Validates: Requirements 4.6, 5.5, 6.5, 7.1**

- [ ]* 10.6 Escribir pruebas de propiedades adicionales
  - Implementar pruebas para las 22 propiedades restantes
  - Cubrir filtrado, ordenamiento, cambios de estado, etc.
  - Asegurar cobertura completa de todos los comportamientos universales
  - **Validates: Todas las propiedades de correctness restantes**

- [ ] 11. Checkpoint - Verificar funcionamiento completo
  - Asegurar que todas las pruebas pasen
  - Verificar integración correcta con sistema existente
  - Validar que no se rompan funcionalidades existentes
  - Preguntar al usuario si surgen dudas

- [ ] 12. Documentación y refinamiento final
  - Actualizar documentación de API con nuevos métodos
  - Crear guía de uso para administradores
  - Optimizar rendimiento si es necesario
  - _Requirements: Todos_

- [ ] 12.1 Actualizar documentación técnica
  - Documentar nuevos métodos en AdminRepository
  - Agregar ejemplos de uso de AuditRepository
  - Documentar estructura de tabla admin_audit_log
  - _Requirements: Documentación técnica_

- [ ] 12.2 Crear guía de usuario para administradores
  - Documentar cómo degradar anfitriones a viajeros
  - Explicar proceso de bloqueo/desbloqueo de cuentas
  - Describir cómo usar el historial de auditoría
  - _Requirements: Documentación de usuario_

- [ ]* 12.3 Escribir pruebas de integración end-to-end
  - Probar flujo completo de degradación de rol
  - Verificar flujo completo de bloqueo/desbloqueo
  - Validar funcionamiento del historial de auditoría
  - _Requirements: Integración completa_

- [ ] 13. Checkpoint final - Asegurar que todas las pruebas pasen
  - Ejecutar suite completa de pruebas unitarias y de propiedades
  - Verificar que no hay regresiones en funcionalidad existente
  - Confirmar que todas las propiedades de correctness se cumplen
  - Preguntar al usuario si surgen dudas