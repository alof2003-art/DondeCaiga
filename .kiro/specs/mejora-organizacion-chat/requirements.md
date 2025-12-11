# Documento de Requisitos - Mejora de Organización del Chat

## Introducción

Este documento define los requisitos para mejorar la organización del sistema de chat en la aplicación "Donde Caiga". El sistema actual muestra todas las reservas en una sola lista, pero se requiere organizarlas en dos apartados claros: "Mis Viajes" y "Mis Reservas", con filtros y colores distintivos para mejorar la experiencia del usuario.

## Glosario

- **Sistema**: La aplicación móvil "Donde Caiga" desarrollada en Flutter
- **Chat**: Pantalla de conversaciones y reservas (`ChatListaScreen`)
- **Mis Viajes**: Apartado que muestra reservas del usuario como viajero
- **Mis Reservas**: Apartado que muestra reservas en propiedades del usuario como anfitrión
- **Reserva Vigente**: Reserva confirmada con fechas futuras o actuales
- **Reserva Pasada**: Reserva completada con fechas anteriores a hoy
- **Reseña Pendiente**: Reserva pasada que aún no ha sido reseñada por el viajero

## Requisitos

### Requisito 1: Apartado "Mis Viajes"

**User Story:** Como viajero, quiero ver mis viajes organizados en un apartado específico, para distinguir claramente entre mis viajes y las reservas en mis propiedades.

#### Criterios de Aceptación

1. WHEN un usuario accede al chat, THEN el Sistema SHALL mostrar un apartado llamado "Mis Viajes" como primera sección
2. WHEN el usuario tiene una reserva vigente como viajero, THEN el Sistema SHALL mostrar esa reserva en primer lugar con el texto "Lugar que estás reservando ahora"
3. WHEN el usuario no tiene reservas vigentes como viajero, THEN el Sistema SHALL mostrar el mensaje "Explora por más lugares" con un botón para ir a explorar
4. WHEN el usuario tiene reservas pasadas como viajero, THEN el Sistema SHALL mostrar esas reservas bajo el subtítulo "Lugares que ya visitaste"
5. WHEN una reserva pasada no ha sido reseñada, THEN el Sistema SHALL mostrar un botón "Escribir Reseña" junto a esa reserva
6. WHEN una reserva pasada ya fue reseñada, THEN el Sistema SHALL mostrar un indicador "Reseñado" y no permitir reseñar nuevamente

### Requisito 2: Apartado "Mis Reservas"

**User Story:** Como anfitrión, quiero ver las reservas en mis propiedades organizadas en un apartado específico, para gestionar mejor las reservas de mis huéspedes.

#### Criterios de Aceptación

1. WHEN un usuario accede al chat, THEN el Sistema SHALL mostrar un apartado llamado "Mis Reservas" como segunda sección
2. WHEN el usuario tiene reservas vigentes en sus propiedades, THEN el Sistema SHALL mostrar esas reservas en primer lugar bajo el subtítulo "Reservas vigentes en mis alojamientos"
3. WHEN el usuario tiene reservas pasadas en sus propiedades, THEN el Sistema SHALL mostrar esas reservas bajo el subtítulo "Reservas pasadas"
4. WHEN no hay reservas en las propiedades del usuario, THEN el Sistema SHALL mostrar el mensaje "No tienes reservas en tus alojamientos"
5. WHEN el usuario no es anfitrión, THEN el Sistema SHALL mostrar el mensaje "Conviértete en anfitrión para recibir reservas"

### Requisito 3: Colores Distintivos por Apartado

**User Story:** Como usuario, quiero que cada apartado tenga colores distintivos, para identificar rápidamente si estoy viendo mis viajes o mis reservas como anfitrión.

#### Criterios de Aceptación

1. WHEN se muestra el apartado "Mis Viajes", THEN el Sistema SHALL usar colores azules (#2196F3) para encabezados, iconos y elementos distintivos
2. WHEN se muestra el apartado "Mis Reservas", THEN el Sistema SHALL usar colores verdes (#4CAF50) para encabezados, iconos y elementos distintivos
3. WHEN se muestra una reserva vigente, THEN el Sistema SHALL usar un borde de color más intenso que las reservas pasadas
4. WHEN se muestra una reserva pasada, THEN el Sistema SHALL usar colores más tenues y opacidad reducida
5. WHEN se muestra una reseña pendiente, THEN el Sistema SHALL usar un indicador naranja (#FF9800) para llamar la atención

### Requisito 4: Sistema de Filtros

**User Story:** Como usuario, quiero filtrar mis reservas por diferentes criterios, para encontrar rápidamente la información que busco.

#### Criterios de Aceptación

1. WHEN el usuario accede a los filtros, THEN el Sistema SHALL mostrar opciones de filtrado por: lugar, fecha, orden alfabético y estado
2. WHEN el usuario selecciona filtro por lugar, THEN el Sistema SHALL mostrar un campo de búsqueda para filtrar por nombre de propiedad o ciudad
3. WHEN el usuario selecciona filtro por fecha, THEN el Sistema SHALL permitir ordenar por fecha más reciente, más antigua, o rango de fechas específico
4. WHEN el usuario selecciona orden alfabético, THEN el Sistema SHALL ordenar las reservas por nombre de propiedad de A-Z o Z-A
5. WHEN el usuario selecciona filtro por estado, THEN el Sistema SHALL permitir filtrar por: vigentes, pasadas, con reseña pendiente
6. WHEN se aplican filtros, THEN el Sistema SHALL mostrar un indicador del número de resultados filtrados
7. WHEN el usuario quiere limpiar filtros, THEN el Sistema SHALL mostrar un botón "Limpiar filtros" que restaure la vista original

### Requisito 5: Integración con Sistema de Reseñas

**User Story:** Como viajero, quiero poder escribir reseñas directamente desde el chat, para evaluar los lugares donde me he hospedado sin navegar a otras pantallas.

#### Criterios de Aceptación

1. WHEN un viajero completa una reserva, THEN el Sistema SHALL habilitar automáticamente la opción de reseñar esa propiedad
2. WHEN el viajero hace clic en "Escribir Reseña", THEN el Sistema SHALL abrir el formulario de reseña con los datos de la reserva pre-cargados
3. WHEN el viajero envía una reseña, THEN el Sistema SHALL actualizar inmediatamente el estado en el chat para mostrar "Reseñado"
4. WHEN un viajero intenta reseñar una propiedad por segunda vez, THEN el Sistema SHALL mostrar un mensaje "Ya reseñaste este lugar"
5. WHEN se muestra una reserva con reseña pendiente, THEN el Sistema SHALL mostrar un recordatorio sutil "Comparte tu experiencia"

### Requisito 6: Navegación y Usabilidad

**User Story:** Como usuario, quiero una navegación intuitiva entre apartados, para acceder fácilmente a la información que necesito.

#### Criterios de Aceptación

1. WHEN el usuario accede al chat, THEN el Sistema SHALL mostrar pestañas o secciones claramente diferenciadas para cada apartado
2. WHEN el usuario cambia entre apartados, THEN el Sistema SHALL mantener los filtros aplicados específicos de cada apartado
3. WHEN no hay contenido en un apartado, THEN el Sistema SHALL mostrar mensajes de estado claros y acciones sugeridas
4. WHEN el usuario hace pull-to-refresh, THEN el Sistema SHALL actualizar el contenido de ambos apartados
5. WHEN se carga el contenido, THEN el Sistema SHALL mostrar indicadores de carga específicos para cada apartado
6. WHEN hay errores de conexión, THEN el Sistema SHALL mostrar mensajes de error específicos y opciones de reintento

### Requisito 7: Información Mejorada de Reservas

**User Story:** Como usuario, quiero ver información más detallada y organizada de mis reservas, para tener mejor contexto de cada conversación.

#### Criterios de Aceptación

1. WHEN se muestra una reserva vigente, THEN el Sistema SHALL mostrar días restantes hasta el check-in o check-out
2. WHEN se muestra una reserva pasada, THEN el Sistema SHALL mostrar cuánto tiempo hace que terminó
3. WHEN se muestra información del otro usuario, THEN el Sistema SHALL incluir su foto de perfil y calificación promedio si está disponible
4. WHEN se muestra el código de verificación, THEN el Sistema SHALL indicar claramente si es para mostrar al anfitrión o al viajero
5. WHEN una reserva está próxima a vencer, THEN el Sistema SHALL mostrar un recordatorio visual
6. WHEN se muestra una reserva cancelada, THEN el Sistema SHALL indicar claramente el estado y la fecha de cancelación

### Requisito 8: Rendimiento y Carga

**User Story:** Como usuario, quiero que el chat cargue rápidamente y maneje eficientemente grandes cantidades de reservas, para tener una experiencia fluida.

#### Criterios de Aceptación

1. WHEN el usuario tiene muchas reservas, THEN el Sistema SHALL implementar paginación o carga lazy para mejorar el rendimiento
2. WHEN se cargan las reservas, THEN el Sistema SHALL priorizar la carga de reservas vigentes sobre las pasadas
3. WHEN se aplican filtros, THEN el Sistema SHALL procesar los filtros de manera eficiente sin bloquear la UI
4. WHEN se actualiza el contenido, THEN el Sistema SHALL usar caché local para mostrar contenido previo mientras carga nuevos datos
5. WHEN hay problemas de conectividad, THEN el Sistema SHALL mostrar contenido en caché con indicadores de estado offline
6. WHEN se navega entre apartados, THEN el Sistema SHALL mantener el estado de scroll y posición del usuario