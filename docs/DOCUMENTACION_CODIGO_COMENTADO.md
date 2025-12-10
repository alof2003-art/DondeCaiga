# Documentación del Código - Donde Caiga v2

## Índice de Pantallas de la Aplicación

### Autenticación
- **SplashScreen** (`lib/features/auth/presentation/screens/splash_screen.dart`)
  - Pantalla inicial que se muestra al abrir la app
  - Verifica si el usuario ya tiene sesión activa
  - Redirige al login o al home según corresponda

- **LoginScreen** (`lib/features/auth/presentation/screens/login_screen.dart`)
  - Permite a los usuarios iniciar sesión con email y contraseña
  - Incluye validación de campos
  - Redirige al home después del login exitoso

- **RegisterScreen** (`lib/features/auth/presentation/screens/register_screen.dart`)
  - Permite crear una nueva cuenta de usuario
  - Solicita nombre, teléfono, email, contraseña
  - Permite subir foto de perfil y cédula
  - Genera código de verificación automáticamente

### Navegación Principal
- **MainScreen** (`lib/features/main/presentation/screens/main_screen.dart`)
  - Pantalla contenedora con navegación inferior
  - Gestiona las 4 pestañas principales: Explorar, Anfitrión, Buzón, Perfil

- **HomeScreen** (`lib/features/home/presentation/screens/home_screen.dart`)
  - Pantalla de bienvenida después del login
  - Muestra información básica del usuario
  - Incluye botón para cerrar sesión

### Explorar
- **ExplorarScreen** (`lib/features/explorar/presentation/screens/explorar_screen.dart`)
  - Lista todos los alojamientos activos disponibles
  - Muestra tarjetas con foto, título, ubicación, capacidad
  - Incluye nombre del anfitrión con indicador de desempeño
  - Muestra calificación en estrellas en esquina superior derecha

- **DetallePropiedadScreen** (`lib/features/explorar/presentation/screens/detalle_propiedad_screen.dart`)
  - Muestra información completa de un alojamiento
  - Incluye fotos, descripción, ubicación en mapa
  - Permite ver reseñas y hacer reservas

### Anfitrión
- **AnfitrionScreen** (`lib/features/anfitrion/presentation/screens/anfitrion_screen.dart`)
  - Vista diferente según el rol del usuario
  - Para viajeros: opción de solicitar ser anfitrión
  - Para anfitriones: lista de sus alojamientos y botón para crear nuevos
  - Incluye acceso a reservas recibidas

- **SolicitudAnfitrionScreen** (`lib/features/anfitrion/presentation/screens/solicitud_anfitrion_screen.dart`)
  - Formulario para solicitar convertirse en anfitrión
  - Requiere foto selfie y foto de la propiedad
  - Incluye campo de mensaje opcional

- **AdminSolicitudesScreen** (`lib/features/anfitrion/presentation/screens/admin_solicitudes_screen.dart`)
  - Solo visible para administradores
  - Lista solicitudes pendientes de anfitrión
  - Permite aprobar o rechazar solicitudes
  - Muestra fotos de verificación

### Propiedades
- **CrearPropiedadScreen** (`lib/features/propiedades/presentation/screens/crear_propiedad_screen.dart`)
  - Formulario para crear un nuevo alojamiento
  - Incluye campos: título, descripción, dirección, ciudad, país
  - Permite seleccionar ubicación en mapa
  - Requiere foto principal
  - Configura capacidad, habitaciones, baños, garaje

- **EditarPropiedadScreen** (`lib/features/propiedades/presentation/screens/editar_propiedad_screen.dart`)
  - Permite modificar información de un alojamiento existente
  - Mismos campos que crear propiedad
  - Incluye opción para cambiar estado (activo/inactivo)

- **LocationPickerScreen** (`lib/features/propiedades/presentation/screens/location_picker_screen.dart`)
  - Mapa interactivo para seleccionar ubicación
  - Permite buscar direcciones con autocompletado
  - Confirma coordenadas seleccionadas

### Reservas
- **ReservaCalendarioScreen** (`lib/features/reservas/presentation/screens/reserva_calendario_screen.dart`)
  - Calendario para seleccionar fechas de reserva
  - Muestra disponibilidad del alojamiento
  - Permite confirmar reserva

- **MisReservasAnfitrionScreen** (`lib/features/reservas/presentation/screens/mis_reservas_anfitrion_screen.dart`)
  - Lista de reservas recibidas por el anfitrión
  - Permite aceptar o rechazar reservas
  - Muestra información del viajero

### Reseñas
- **CrearResenaScreen** (`lib/features/resenas/presentation/screens/crear_resena_screen.dart`)
  - Formulario para dejar una reseña
  - Calificación de 1 a 5 estrellas
  - Campo de comentario opcional
  - Solo disponible después de una reserva completada

### Chat/Buzón
- **BuzonScreen** (`lib/features/buzon/presentation/screens/buzon_screen.dart`)
  - Pantalla placeholder para mensajes
  - Preparada para futura implementación de chat

- **ChatConversacionScreen** (`lib/features/chat/presentation/screens/chat_conversacion_screen.dart`)
  - Conversación individual entre usuarios
  - Envío y recepción de mensajes en tiempo real

### Perfil
- **PerfilScreen** (`lib/features/perfil/presentation/screens/perfil_screen.dart`)
  - Muestra información del usuario actual
  - Foto de perfil, nombre, email
  - Botón para editar perfil
  - Botón para cerrar sesión
  - Para admins: acceso a panel de administración

- **EditarPerfilScreen** (`lib/features/perfil/presentation/screens/editar_perfil_screen.dart`)
  - Permite editar nombre y foto de perfil
  - Validación de campos
  - Actualización en tiempo real

### Administración
- **AdminDashboardScreen** (`lib/features/admin/presentation/screens/admin_dashboard_screen.dart`)
  - Solo accesible para administradores
  - Muestra estadísticas del sistema
  - Lista todos los usuarios registrados
  - Información de roles y estados

---

## Código Comentado por Funcionalidad

### 1. EDITAR PERFIL

**Archivo:** `lib/features/perfil/presentation/screens/editar_perfil_screen.dart`

**Líneas clave comentadas:**

```dart
// Línea 30-35: Inicialización de controladores y servicios
// Se preparan los repositorios necesarios para actualizar el perfil
// y subir archivos al storage de Supabase

// Línea 47-72: Función para seleccionar foto de perfil
// Abre el selector de imágenes de la galería del dispositivo
// Limita el tamaño de la imagen a 800x800 para optimizar
// Guarda la imagen seleccionada en el estado local

// Línea 74-120: Función principal para guardar cambios
// Primero valida que el formulario sea correcto
// Compara el nombre actual con el nuevo para detectar cambios
// Si hay foto nueva, la sube primero al storage
// Luego actualiza la base de datos con los cambios
// Muestra mensaje de éxito y regresa a la pantalla anterior

// Línea 150-190: Widget de foto de perfil con botón de cámara
// Muestra la foto actual o la nueva seleccionada
// Incluye un ícono de cámara en la esquina para indicar que es editable
// Al tocar la foto se abre el selector de imágenes

// Línea 200-220: Campo de texto para editar el nombre
// Incluye validación de longitud mínima de 3 caracteres
// No permite nombres vacíos
```

---

### 2. ESTADÍSTICAS DE ADMIN

**Archivo:** `lib/features/admin/presentation/screens/admin_dashboard_screen.dart`

**Líneas clave comentadas:**

```dart
// Línea 25-50: Función para cargar datos del dashboard
// Obtiene estadísticas generales del sistema desde la base de datos
// Incluye conteo de usuarios por rol y total de alojamientos
// Maneja estados de carga y errores

// Línea 52-75: Funciones auxiliares para roles
// Convierte el ID numérico del rol a texto legible
// Asigna colores específicos a cada rol para la UI
// Define íconos representativos para cada tipo de usuario

// Línea 120-180: Widget de estadísticas visuales
// Crea un grid de 2x2 con tarjetas de estadísticas
// Cada tarjeta muestra un número y un ícono
// Usa colores diferenciados para cada métrica
// Calcula aspect ratio dinámicamente para responsive design

// Línea 200-250: Lista de usuarios del sistema
// Muestra todos los usuarios registrados en tarjetas
// Cada tarjeta incluye foto, nombre, email y rol
// Al tocar una tarjeta se muestra un diálogo con más detalles
// Los colores de las tarjetas varían según el rol del usuario

// Línea 280-310: Diálogo de detalle de usuario
// Muestra información completa del usuario seleccionado
// Incluye estado de cuenta y verificación de email
// Formato de tabla para mejor legibilidad
```

---

### 3. CREACIÓN DE ALOJAMIENTOS

**Archivo:** `lib/features/propiedades/presentation/screens/crear_propiedad_screen.dart`

**Líneas clave comentadas:**

```dart
// Línea 20-40: Controladores de formulario
// Se crean controladores para cada campo de texto del formulario
// Variables de estado para capacidad, habitaciones, baños y garaje
// Variables para almacenar coordenadas del mapa

// Línea 55-85: Función para seleccionar foto principal
// Muestra un bottom sheet con opciones de cámara o galería
// Permite al usuario elegir cómo quiere subir la foto
// Optimiza la imagen a 1024x1024 para reducir tamaño

// Línea 87-105: Función para abrir selector de ubicación en mapa
// Navega a la pantalla del mapa interactivo
// Pasa la ubicación actual si ya existe
// Recibe las coordenadas seleccionadas y las guarda

// Línea 107-165: Función principal para crear propiedad
// Valida que todos los campos requeridos estén completos
// Verifica que se haya subido una foto
// Primero crea el registro en la base de datos
// Luego sube la foto al storage usando el ID generado
// Finalmente actualiza el registro con la URL de la foto
// Este orden evita fotos huérfanas en el storage

// Línea 200-230: Widget de selector de foto
// Muestra un contenedor grande para la foto principal
// Si no hay foto, muestra un ícono de "agregar foto"
// Si hay foto, la muestra en preview
// Al tocar se abre el selector de imágenes

// Línea 300-350: Campos de capacidad y características
// Dropdowns para seleccionar número de personas, habitaciones y baños
// Checkbox para indicar si tiene garaje
// Valores predefinidos para facilitar la selección

// Línea 380-410: Botón de crear con estado de carga
// Muestra un spinner mientras se procesa la creación
// Se deshabilita durante el proceso para evitar doble envío
// Cambia de texto a spinner cuando está cargando
```

---

### 4. SOLICITUDES DEL ADMIN

**Archivo:** `lib/features/anfitrion/presentation/screens/admin_solicitudes_screen.dart`

**Líneas clave comentadas:**

```dart
// Línea 25-45: Función para cargar solicitudes pendientes
// Consulta la base de datos por solicitudes con estado "pendiente"
// Incluye información del usuario que hizo la solicitud
// Maneja estados de carga y errores

// Línea 47-85: Función para aprobar solicitud
// Muestra diálogo de confirmación antes de aprobar
// Actualiza el rol del usuario a "anfitrión" en la base de datos
// Registra el ID del admin que aprobó la solicitud
// Actualiza el estado de la solicitud a "aprobada"
// Recarga la lista para reflejar los cambios

// Línea 87-135: Función para rechazar solicitud
// Muestra diálogo con campo para comentario opcional
// Permite al admin explicar por qué se rechaza
// Actualiza el estado de la solicitud a "rechazada"
// Guarda el comentario y el ID del admin revisor
// No cambia el rol del usuario

// Línea 137-165: Función para ver fotos en pantalla completa
// Abre un diálogo con la imagen ampliada
// Permite hacer zoom con InteractiveViewer
// Incluye botón para descargar la imagen
// Útil para verificar la identidad del solicitante

// Línea 200-280: Tarjetas de solicitudes
// Cada tarjeta muestra nombre, email y mensaje del solicitante
// Incluye botones para ver ambas fotos (selfie y propiedad)
// Botones de aprobar (verde) y rechazar (rojo) al final
// Diseño claro para facilitar la revisión rápida
```

---

### 5. GENERACIÓN DE CÓDIGO DE VERIFICACIÓN

**Archivo:** `lib/features/auth/presentation/screens/register_screen.dart`

**Líneas clave comentadas:**

```dart
// Línea 50-75: Función para seleccionar documento de identidad
// Muestra opciones de cámara o galería en un bottom sheet
// Permite al usuario fotografiar o seleccionar su cédula
// Optimiza la imagen antes de guardarla
// Este documento se usa para verificación de identidad

// Línea 77-125: Función principal de registro
// Valida todos los campos del formulario antes de continuar
// Crea un objeto UserRegistrationData con toda la información
// Llama al servicio de autenticación para crear la cuenta
// El servicio internamente genera un código de verificación único
// Sube las fotos al storage de Supabase
// Crea el perfil del usuario en la base de datos
// Muestra mensaje de éxito y regresa al login

// Línea 150-170: Widget de selector de foto de perfil
// Componente reutilizable para elegir foto de perfil
// Muestra un círculo con la foto o un ícono de persona
// Incluye botón de cámara para indicar que es editable

// Línea 200-230: Campos de formulario con validación
// Cada campo tiene su propio validador
// Los errores se muestran en tiempo real
// Se limpian cuando el usuario empieza a escribir
// Validaciones incluyen: formato de email, longitud de contraseña, etc.

// Línea 250-280: Botón de subir cédula
// Cambia de color y texto cuando se ha cargado un documento
// Muestra ícono de check verde cuando está completo
// Opcional pero recomendado para verificación
```

**Nota sobre el código de verificación:**
El código de verificación se genera automáticamente en el backend de Supabase cuando se crea una cuenta nueva. No es visible en el código del frontend, pero se envía por email al usuario para confirmar su cuenta.

---

## Resumen de Archivos Documentados

| Funcionalidad | Archivo | Líneas Clave |
|--------------|---------|--------------|
| Editar Perfil | `editar_perfil_screen.dart` | 30-35, 47-72, 74-120, 150-220 |
| Estadísticas Admin | `admin_dashboard_screen.dart` | 25-50, 52-75, 120-250, 280-310 |
| Crear Alojamiento | `crear_propiedad_screen.dart` | 20-40, 55-85, 87-165, 200-410 |
| Solicitudes Admin | `admin_solicitudes_screen.dart` | 25-45, 47-135, 137-165, 200-280 |
| Registro y Verificación | `register_screen.dart` | 50-75, 77-125, 150-230, 250-280 |

---

## Notas Adicionales

- Todos los comentarios están escritos en lenguaje natural y humanizado
- Se evitaron emojis según lo solicitado
- Los comentarios explican el "por qué" y el "qué" de cada sección
- Se incluyen números de línea aproximados para facilitar la ubicación
- La documentación cubre las funcionalidades específicas solicitadas
