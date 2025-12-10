# 🏠 Nuevas Funcionalidades - Donde Caiga

## 📋 Resumen de Cambios

Vamos a implementar:
1. ✅ Barra de navegación inferior con 4 opciones
2. ✅ Sistema de roles (Viajero, Anfitrión, Admin)
3. ✅ Solicitudes para ser anfitrión
4. ✅ Gestión de propiedades
5. ✅ Sistema de mensajería
6. ✅ Cuenta admin especial

## 🗄️ Paso 1: Crear Esquema de Base de Datos

### 1.1 Ejecutar Script Principal
1. Ve a Supabase > SQL Editor
2. Copia y pega el contenido de `supabase_esquema_completo.sql`
3. Ejecuta el script

Esto creará:
- ✅ Tabla `roles` (viajero, anfitrión, admin)
- ✅ Actualización de `users_profiles` con rol
- ✅ Tabla `propiedades` (alojamientos)
- ✅ Tabla `fotos_propiedades`
- ✅ Tabla `solicitudes_anfitrion`
- ✅ Tabla `reservas`
- ✅ Tabla `mensajes` (chat)
- ✅ Tabla `resenas` (calificaciones)
- ✅ Todas las políticas de seguridad (RLS)

### 1.2 Crear Buckets de Storage
Ve a Supabase > Storage y crea estos buckets (marca como PUBLIC):
1. `solicitudes-anfitrion` - Para fotos de solicitudes
2. `propiedades-fotos` - Para fotos de propiedades

Luego ejecuta `crear_buckets_storage.sql` para las políticas.

### 1.3 Crear Cuenta Admin
1. Regístrate en la app con el email: `alof2003@gmail.com` y contraseña: `123456`
2. Ve a Supabase > SQL Editor
3. Ejecuta el script `crear_cuenta_admin.sql`
4. Ahora esa cuenta tendrá privilegios de admin

## 📱 Paso 2: Implementar la Interfaz

### 2.1 Barra de Navegación Inferior
Vamos a crear un `BottomNavigationBar` con 4 opciones:
- 🔍 Explorar (ver alojamientos)
- 🏠 Anfitrión (registrar propiedad)
- 💬 Buzón (mensajes/chat)
- 👤 Perfil (datos y cerrar sesión)

### 2.2 Pantallas a Crear
1. **ExplorarScreen** - Lista de propiedades disponibles
2. **AnfitrionScreen** - Formulario para solicitar ser anfitrión
3. **BuzonScreen** - Lista de conversaciones
4. **PerfilScreen** - Datos del usuario y opciones

### 2.3 Pantalla Admin (solo para admin)
- Ver solicitudes pendientes
- Aprobar/rechazar solicitudes de anfitrión

## 🎯 Flujo de Usuario

### Viajero (rol por defecto)
1. Se registra → Rol: Viajero
2. Puede explorar propiedades
3. Puede solicitar ser anfitrión
4. Puede hacer reservas
5. Puede chatear con anfitriones

### Anfitrión (después de aprobación)
1. Envía solicitud con selfie + foto de propiedad
2. Admin aprueba → Rol cambia a Anfitrión
3. Puede registrar propiedades
4. Puede recibir reservas
5. Puede chatear con viajeros

### Admin (cuenta especial)
1. Ve todas las solicitudes pendientes
2. Puede aprobar/rechazar solicitudes
3. Tiene acceso a todas las funcionalidades

## 📊 Estructura de Tablas

```
users_profiles (usuarios)
├── id
├── email
├── nombre
├── telefono
├── foto_perfil_url
├── cedula_url
├── rol_id → roles
└── estado_cuenta

roles
├── id
├── nombre (viajero/anfitrion/admin)
└── descripcion

propiedades (alojamientos)
├── id
├── anfitrion_id → users_profiles
├── titulo
├── descripcion
├── direccion
├── ciudad
├── capacidad_personas
├── foto_principal_url
└── estado

fotos_propiedades
├── id
├── propiedad_id → propiedades
├── url_foto
└── es_principal

solicitudes_anfitrion
├── id
├── usuario_id → users_profiles
├── foto_selfie_url
├── foto_propiedad_url
├── estado (pendiente/aprobada/rechazada)
└── admin_revisor_id

reservas
├── id
├── propiedad_id → propiedades
├── viajero_id → users_profiles
├── fecha_inicio
├── fecha_fin
└── estado

mensajes (chat)
├── id
├── reserva_id → reservas
├── remitente_id → users_profiles
├── destinatario_id → users_profiles
├── contenido
└── leido

resenas (calificaciones)
├── id
├── propiedad_id → propiedades
├── viajero_id → users_profiles
├── calificacion (1-5)
└── comentario
```

## ⚡ Próximos Pasos

1. ✅ Ejecutar scripts SQL en Supabase
2. ✅ Crear buckets de storage
3. ✅ Crear cuenta admin
4. 🔄 Implementar barra de navegación inferior
5. 🔄 Crear las 4 pantallas principales
6. 🔄 Implementar formulario de solicitud de anfitrión
7. 🔄 Implementar panel de admin

¿Listo para continuar con la implementación del código Flutter?
