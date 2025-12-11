# Documento de Requisitos - Gestión de Usuarios por Administrador

## Introducción

Este documento define los requisitos para el sistema de gestión de usuarios por parte de administradores en la aplicación "Donde Caiga". El sistema permitirá a los administradores degradar anfitriones a viajeros, bloquear/desbloquear cuentas y gestionar el estado de cualquier usuario (excepto otros administradores) para mantener la integridad y seguridad de la plataforma. **IMPORTANTE**: Por seguridad, los administradores NO pueden promover viajeros a anfitriones directamente - deben usar el proceso de verificación existente.

## Glosario

- **Sistema**: La aplicación móvil "Donde Caiga" desarrollada en Flutter
- **Administrador**: Usuario con rol_id = 3 que tiene permisos especiales de gestión
- **Usuario Objetivo**: Usuario cuya cuenta será gestionada por el administrador (viajero o anfitrión)
- **Degradación de Rol**: Proceso de cambiar un anfitrión (rol_id = 2) a viajero (rol_id = 1)
- **Bloqueo de Cuenta**: Cambiar el estado_cuenta de un usuario a "bloqueado" para impedir su acceso
- **Desbloqueo de Cuenta**: Cambiar el estado_cuenta de un usuario de "bloqueado" a "activo"
- **Panel de Administración**: Interfaz administrativa existente (`AdminDashboardScreen`) donde se gestionan usuarios
- **Historial de Acciones**: Registro de todas las acciones administrativas realizadas
- **Re-verificación**: Proceso donde un anfitrión degradado debe solicitar nuevamente ser anfitrión

## Requisitos

### Requisito 1: Integración con Panel de Administración Existente

**User Story:** Como administrador, quiero gestionar usuarios desde el panel de administración existente, para tener una experiencia unificada sin interfaces adicionales.

#### Criterios de Aceptación

1. WHEN un administrador accede al panel de administración existente, THEN el Sistema SHALL mostrar la lista de usuarios con opciones de gestión integradas
2. WHEN el administrador hace clic en un usuario de la lista, THEN el Sistema SHALL mostrar un diálogo mejorado con opciones de gestión (degradar rol, bloquear/desbloquear)
3. WHEN se muestra la lista de usuarios, THEN el Sistema SHALL excluir automáticamente todos los usuarios con rol_id = 3 (administradores)
4. WHEN se muestra la lista de usuarios, THEN el Sistema SHALL mostrar para cada usuario: foto de perfil, nombre, email, rol actual, estado de cuenta y fecha de registro
5. WHEN se carga la lista de usuarios, THEN el Sistema SHALL ordenar los usuarios por fecha de registro (más recientes primero)

### Requisito 2: Búsqueda y Filtrado de Usuarios

**User Story:** Como administrador, quiero buscar y filtrar usuarios específicos en el panel existente, para encontrar rápidamente la cuenta que necesito gestionar.

#### Criterios de Aceptación

1. WHEN el administrador está en el panel de administración, THEN el Sistema SHALL agregar una barra de búsqueda en la sección de usuarios
2. WHEN el administrador escribe en la búsqueda, THEN el Sistema SHALL filtrar usuarios por nombre o email en tiempo real
3. WHEN el administrador selecciona un filtro de rol, THEN el Sistema SHALL mostrar solo usuarios con ese rol específico (viajero o anfitrión)
4. WHEN el administrador selecciona un filtro de estado, THEN el Sistema SHALL mostrar solo usuarios con ese estado específico (activo, bloqueado)
5. WHEN no hay resultados de búsqueda, THEN el Sistema SHALL mostrar un mensaje indicando "No se encontraron usuarios"

### Requisito 3: Degradación de Anfitrión a Viajero

**User Story:** Como administrador, quiero degradar un anfitrión a viajero cuando sea necesario, para que deba pasar nuevamente por el proceso de verificación si desea ser anfitrión otra vez.

#### Criterios de Aceptación

1. WHEN el administrador selecciona un usuario anfitrión de la lista, THEN el Sistema SHALL mostrar la opción "Degradar a Viajero" claramente visible
2. WHEN el administrador selecciona "Degradar a Viajero", THEN el Sistema SHALL mostrar un diálogo de confirmación explicando que se removerán los permisos de anfitrión
3. WHEN se confirma la degradación, THEN el Sistema SHALL actualizar rol_id de 2 a 1 en la base de datos
4. WHEN se degrada un anfitrión a viajero, THEN el Sistema SHALL eliminar cualquier solicitud de anfitrión existente del usuario
5. WHEN se degrada un anfitrión a viajero, THEN el Sistema SHALL permitir al usuario crear una nueva solicitud de anfitrión en el futuro
6. WHEN el usuario es viajero, THEN el Sistema SHALL NO mostrar opciones de cambio de rol (solo pueden subir mediante el proceso de verificación normal)

### Requisito 4: Bloqueo de Cuenta de Usuario

**User Story:** Como administrador, quiero bloquear la cuenta de un usuario que se porta mal, para impedir su acceso a la plataforma y proteger a otros usuarios.

#### Criterios de Aceptación

1. WHEN el administrador selecciona un usuario activo, THEN el Sistema SHALL mostrar la opción "Bloquear Cuenta" claramente visible
2. WHEN el administrador selecciona "Bloquear Cuenta", THEN el Sistema SHALL mostrar un diálogo de confirmación solicitando el motivo del bloqueo
3. WHEN se confirma el bloqueo, THEN el Sistema SHALL cambiar el estado_cuenta del usuario de "activo" a "bloqueado"
4. WHEN un usuario bloqueado intenta iniciar sesión, THEN el Sistema SHALL mostrar un mensaje indicando que su cuenta está bloqueada y no permitir el acceso
5. WHEN se bloquea una cuenta, THEN el Sistema SHALL cerrar automáticamente todas las sesiones activas del usuario
6. WHEN se bloquea una cuenta, THEN el Sistema SHALL registrar la acción en el historial con fecha, administrador responsable y motivo

### Requisito 5: Desbloqueo de Cuenta de Usuario

**User Story:** Como administrador, quiero desbloquear la cuenta de un usuario previamente bloqueado, para restaurar su acceso cuando sea apropiado.

#### Criterios de Aceptación

1. WHEN el administrador selecciona un usuario bloqueado, THEN el Sistema SHALL mostrar la opción "Desbloquear Cuenta" claramente visible
2. WHEN el administrador selecciona "Desbloquear Cuenta", THEN el Sistema SHALL mostrar un diálogo de confirmación explicando que se restaurará el acceso
3. WHEN se confirma el desbloqueo, THEN el Sistema SHALL cambiar el estado_cuenta del usuario de "bloqueado" a "activo"
4. WHEN se desbloquea una cuenta, THEN el Sistema SHALL permitir al usuario iniciar sesión normalmente en su próximo intento
5. WHEN se desbloquea una cuenta, THEN el Sistema SHALL registrar la acción en el historial con fecha y administrador responsable
6. WHEN se desbloquea una cuenta, THEN el Sistema SHALL actualizar inmediatamente la visualización del estado en la lista

### Requisito 6: Eliminación Permanente de Cuenta de Usuario

**User Story:** Como administrador, quiero eliminar permanentemente la cuenta de un usuario cuando sea necesario por violaciones graves, para remover completamente su acceso y datos de la plataforma.

#### Criterios de Aceptación

1. WHEN el administrador selecciona cualquier usuario (viajero o anfitrión), THEN el Sistema SHALL mostrar la opción "Eliminar Cuenta" claramente visible
2. WHEN el administrador selecciona "Eliminar Cuenta", THEN el Sistema SHALL mostrar un diálogo de confirmación con advertencia sobre la irreversibilidad de la acción
3. WHEN se muestra el diálogo de eliminación, THEN el Sistema SHALL requerir que el administrador escriba el motivo de la eliminación en un campo de texto
4. WHEN se muestra el diálogo de eliminación, THEN el Sistema SHALL requerir que el administrador escriba exactamente "ACEPTAR" en un campo de verificación para confirmar la acción
5. WHEN el administrador no escribe "ACEPTAR" exactamente, THEN el Sistema SHALL deshabilitar el botón de confirmación y mostrar mensaje de error
6. WHEN se confirma la eliminación con todos los campos válidos, THEN el Sistema SHALL eliminar permanentemente la cuenta del usuario de la base de datos
7. WHEN se elimina una cuenta, THEN el Sistema SHALL eliminar automáticamente todas las reservas del usuario (como viajero y como anfitrión)
8. WHEN se elimina una cuenta, THEN el Sistema SHALL eliminar automáticamente todas las propiedades/alojamientos del usuario
9. WHEN se elimina una cuenta, THEN el Sistema SHALL eliminar automáticamente todas las reseñas escritas por el usuario y las reseñas recibidas en sus propiedades
10. WHEN se elimina una cuenta, THEN el Sistema SHALL eliminar automáticamente todas las fotos de perfil y fotos de propiedades del usuario del storage
11. WHEN se elimina una cuenta, THEN el Sistema SHALL eliminar automáticamente todos los mensajes de chat del usuario y todas las conversaciones completas donde participaba
12. WHEN se elimina una cuenta, THEN el Sistema SHALL eliminar automáticamente todas las solicitudes de anfitrión del usuario
13. WHEN se elimina una cuenta, THEN el Sistema SHALL registrar la acción en el historial de auditoría antes de proceder con la eliminación

### Requisito 7: Restricciones de Seguridad

**User Story:** Como sistema, necesito implementar restricciones de seguridad, para evitar que los administradores gestionen cuentas de otros administradores y mantengan la integridad del sistema.

#### Criterios de Aceptación

1. WHEN se carga la lista de usuarios, THEN el Sistema SHALL excluir automáticamente todos los usuarios con rol_id = 3 (administradores)
2. WHEN un administrador intenta acceder directamente a gestionar otro administrador, THEN el Sistema SHALL mostrar un mensaje de error "No tienes permisos para gestionar esta cuenta"
3. WHEN se realizan cambios de rol, THEN el Sistema SHALL validar que el usuario objetivo no sea administrador antes de proceder
4. WHEN se realizan bloqueos, THEN el Sistema SHALL validar que el usuario objetivo no sea administrador antes de proceder
5. WHEN se detecta un intento de gestionar un administrador, THEN el Sistema SHALL registrar el intento en logs de seguridad
6. WHEN un administrador intenta cambiar su propio rol o bloquearse, THEN el Sistema SHALL mostrar un mensaje "No puedes gestionar tu propia cuenta"

### Requisito 8: Historial de Acciones Administrativas

**User Story:** Como administrador, quiero ver un historial de todas las acciones administrativas realizadas, para mantener un registro de auditoría y transparencia.

#### Criterios de Aceptación

1. WHEN se realiza cualquier acción administrativa, THEN el Sistema SHALL registrar en una tabla de auditoría: fecha, administrador, usuario objetivo, acción realizada y motivo
2. WHEN el administrador accede al historial desde el panel, THEN el Sistema SHALL mostrar todas las acciones ordenadas por fecha (más recientes primero)
3. WHEN se muestra el historial, THEN el Sistema SHALL incluir: fecha/hora, nombre del administrador, usuario afectado, tipo de acción y motivo (si aplica)
4. WHEN el historial contiene muchas entradas, THEN el Sistema SHALL implementar paginación para mejorar el rendimiento
5. WHEN se consulta el historial, THEN el Sistema SHALL permitir filtrar por tipo de acción (degradación de rol, bloqueo, desbloqueo)
6. WHEN se consulta el historial, THEN el Sistema SHALL permitir filtrar por rango de fechas

### Requisito 9: Confirmaciones y Validaciones

**User Story:** Como administrador, quiero recibir confirmaciones claras antes de realizar acciones críticas, para evitar cambios accidentales que puedan afectar a los usuarios.

#### Criterios de Aceptación

1. WHEN el administrador intenta degradar un anfitrión, THEN el Sistema SHALL mostrar un diálogo con el texto "¿Estás seguro de degradar a [nombre] de Anfitrión a Viajero? Deberá solicitar verificación nuevamente."
2. WHEN el administrador intenta bloquear una cuenta, THEN el Sistema SHALL mostrar un diálogo con campo obligatorio para el motivo del bloqueo
3. WHEN el administrador intenta desbloquear una cuenta, THEN el Sistema SHALL mostrar un diálogo con el texto "¿Estás seguro de desbloquear la cuenta de [nombre]? El usuario podrá acceder nuevamente."
4. WHEN se muestra cualquier diálogo de confirmación, THEN el Sistema SHALL incluir botones claramente etiquetados "Confirmar" y "Cancelar"
5. WHEN el administrador cancela una acción, THEN el Sistema SHALL cerrar el diálogo sin realizar cambios
6. WHEN se confirma una acción, THEN el Sistema SHALL mostrar un indicador de carga mientras se procesa

### Requisito 10: Manejo de Errores y Retroalimentación

**User Story:** Como administrador, quiero recibir mensajes claros sobre el resultado de mis acciones, para saber si fueron exitosas o si ocurrió algún problema.

#### Criterios de Aceptación

1. WHEN una acción administrativa es exitosa, THEN el Sistema SHALL mostrar un mensaje de confirmación verde con detalles específicos de la acción realizada
2. WHEN una acción administrativa falla, THEN el Sistema SHALL mostrar un mensaje de error rojo con información específica sobre el problema
3. WHEN hay problemas de conectividad, THEN el Sistema SHALL mostrar un mensaje indicando "Error de conexión. Verifica tu internet e intenta nuevamente"
4. WHEN el administrador no tiene permisos suficientes, THEN el Sistema SHALL mostrar un mensaje "No tienes permisos para realizar esta acción"
5. WHEN se intenta gestionar un usuario que no existe, THEN el Sistema SHALL mostrar un mensaje "El usuario seleccionado no existe o fue eliminado"
6. WHEN ocurre un error inesperado, THEN el Sistema SHALL mostrar un mensaje genérico y registrar el error detallado en logs

### Requisito 11: Impacto en Funcionalidades Existentes

**User Story:** Como sistema, necesito manejar correctamente el impacto de los cambios administrativos en las funcionalidades existentes, para mantener la consistencia de la aplicación.

#### Criterios de Aceptación

1. WHEN se degrada un anfitrión a viajero, THEN el Sistema SHALL mantener todas sus reservas existentes como viajero
2. WHEN se degrada un anfitrión a viajero, THEN el Sistema SHALL mantener todas sus propiedades pero cambiar su estado a "inactivo"
3. WHEN se degrada un anfitrión a viajero, THEN el Sistema SHALL crear una nueva solicitud de anfitrión en estado "pendiente" para permitir re-verificación
4. WHEN se bloquea la cuenta de un anfitrión, THEN el Sistema SHALL cambiar automáticamente todas sus propiedades activas a estado "inactivo"
5. WHEN se bloquea la cuenta de un usuario, THEN el Sistema SHALL cancelar automáticamente todas sus reservas pendientes
6. WHEN se desbloquea la cuenta de un anfitrión, THEN el Sistema SHALL permitir que reactive manualmente sus propiedades
7. WHEN se realizan cambios administrativos, THEN el Sistema SHALL notificar al usuario afectado por email sobre los cambios en su cuenta