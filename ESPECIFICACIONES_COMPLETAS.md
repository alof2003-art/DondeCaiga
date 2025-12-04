# Especificaciones Completas - Donde Caiga

## 🎯 Sistema de Roles

### 1. Viajero (rol_id = 1) - ROL POR DEFECTO
- Todos los usuarios nuevos son viajeros
- Pueden ver alojamientos en "Explorar"
- Pueden hacer reservas
- Pueden solicitar ser anfitrión
- Pueden chatear con anfitriones

### 2. Anfitrión (rol_id = 2)
- Pueden crear y gestionar alojamientos
- Pueden aceptar/rechazar reservas
- Pueden chatear con viajeros
- Mantienen funcionalidades de viajero

### 3. Admin (rol_id = 3)
- Todas las funcionalidades desbloqueadas
- Pueden ver y aprobar solicitudes para ser anfitrión
- Pueden crear alojamientos directamente
- Panel especial de administración

---

## 📱 Funcionalidades por Pantalla

### EXPLORAR (Viajeros)
**Lista de alojamientos disponibles**
- Mostrar tarjetas con:
  - Foto principal del alojamiento
  - Título
  - Ciudad
  - Capacidad de personas

**Al hacer clic en un alojamiento:**
- Pantalla de detalle con:
  - Galería de fotos
  - Nombre del anfitrión
  - Descripción completa
  - Ubicación en mapa (Google Maps / Flutter Maps)
  - Capacidad, habitaciones, baños
  - Botón "Reservar"

**Proceso de reserva:**
1. Click en "Reservar"
2. Mostrar calendario para seleccionar:
   - Fecha de inicio
   - Fecha de fin
3. Confirmar reserva
4. Reserva creada en estado "pendiente"

---

### ANFITRIÓN

**Para Viajeros (rol_id = 1):**
- Mostrar mensaje: "Solicita ser anfitrión"
- Botón para enviar solicitud
- Formulario de solicitud:
  - Foto selfie del usuario
  - Foto del establecimiento
  - Mensaje opcional

**Para Anfitriones (rol_id = 2):**
- Lista de sus alojamientos
- Botón "Crear nuevo alojamiento"
- Formulario para crear alojamiento:
  - Título
  - Descripción
  - Dirección completa
  - Ciudad, País
  - Coordenadas (latitud, longitud)
  - Capacidad de personas
  - Número de habitaciones
  - Número de baños
  - Fotos (múltiples)

**Para Admin (rol_id = 3):**
- Todas las funciones de anfitrión
- Panel adicional: "Solicitudes pendientes"
- Lista de solicitudes con:
  - Nombre del solicitante
  - Email
  - Foto selfie (descargar)
  - Foto establecimiento (descargar)
  - Botones: Aprobar / Rechazar

---

### BUZÓN (Mensajería y Reservas)

**Para Viajeros:**
- Lista de reservas realizadas:
  - Pendientes (esperando aprobación)
  - Confirmadas
  - Rechazadas
  - Completadas
- Al hacer clic en una reserva confirmada:
  - Abrir chat con el anfitrión

**Para Anfitriones:**
- Lista de reservas recibidas:
  - Pendientes (con botones Aceptar/Rechazar)
  - Confirmadas
  - Rechazadas
  - Completadas
- Al aceptar una reserva:
  - Se abre automáticamente un chat
  - Mensaje automático: "Reserva confirmada"

**Chat:**
- Mensajería en tiempo real
- Mostrar:
  - Nombre del otro usuario
  - Foto de perfil
  - Mensajes con timestamp
  - Input para escribir
  - Botón enviar

---

### PERFIL

**Para todos los usuarios:**
- Foto de perfil
- Nombre
- Email
- Rol actual
- Botón "Cerrar sesión"

**Adicional para Viajeros:**
- Botón "Solicitar ser anfitrión"
  - Redirige a formulario de solicitud

**Adicional para Admin:**
- Badge o indicador de "Administrador"
- Acceso rápido a panel de solicitudes

---

## 🗄️ Base de Datos

### Tablas existentes:
- ✅ `roles`
- ✅ `users_profiles`
- ✅ `propiedades`
- ✅ `fotos_propiedades`
- ✅ `solicitudes_anfitrion`
- ✅ `reservas`
- ✅ `mensajes`
- ✅ `resenas`

### Buckets de Storage:
- ✅ `profile-photos`
- ✅ `id-documents`
- ✅ `solicitudes-anfitrion`
- ✅ `propiedades-fotos`

---

## 🔄 Flujos Principales

### Flujo 1: Usuario se convierte en Anfitrión
1. Usuario viajero va a "Perfil" o "Anfitrión"
2. Click en "Solicitar ser anfitrión"
3. Sube foto selfie + foto establecimiento
4. Envía solicitud (estado: pendiente)
5. Admin revisa solicitud
6. Admin aprueba → Usuario pasa a rol_id = 2
7. Usuario ahora puede crear alojamientos

### Flujo 2: Reservar un Alojamiento
1. Viajero busca en "Explorar"
2. Click en alojamiento
3. Ve detalles + mapa
4. Click "Reservar"
5. Selecciona fechas en calendario
6. Confirma reserva (estado: pendiente)
7. Aparece en "Buzón" del viajero
8. Aparece en "Buzón" del anfitrión
9. Anfitrión acepta/rechaza
10. Si acepta → Se abre chat automáticamente

### Flujo 3: Chat entre Viajero y Anfitrión
1. Reserva confirmada
2. Ambos pueden acceder al chat desde "Buzón"
3. Mensajes en tiempo real
4. Historial guardado en BD

---

## 📦 Dependencias Necesarias

```yaml
dependencies:
  # Ya tienes:
  supabase_flutter: ^2.0.0
  image_picker: ^1.0.0
  
  # Necesitas agregar:
  google_maps_flutter: ^2.5.0  # Para mapas
  table_calendar: ^3.0.9       # Para calendario de reservas
  intl: ^0.18.0                # Para formatear fechas
```

---

## 🎨 Consideraciones de UI/UX

- Usar colores consistentes (Color(0xFF4DB6AC) como principal)
- Iconos claros para cada rol
- Badges para indicar estado de reservas
- Notificaciones visuales para nuevas solicitudes (admin)
- Loading states en todas las operaciones async
- Manejo de errores con SnackBars

---

## 🔐 Seguridad

- RLS deshabilitado en `users_profiles` (ya configurado)
- Validar rol en el código Flutter antes de mostrar funcionalidades
- Solo admins pueden aprobar solicitudes
- Solo anfitriones pueden crear alojamientos
- Solo el viajero y anfitrión de una reserva pueden ver el chat

---

## 📝 Orden de Implementación Sugerido

1. ✅ Sistema de autenticación (COMPLETADO)
2. ✅ Convertir cuenta en admin (COMPLETADO)
3. 🔄 Formulario de solicitud para ser anfitrión
4. 🔄 Panel de admin para ver/aprobar solicitudes
5. 🔄 Formulario para crear alojamientos
6. 🔄 Lista de alojamientos en "Explorar"
7. 🔄 Detalle de alojamiento con mapa
8. 🔄 Sistema de reservas con calendario
9. 🔄 Lista de reservas en "Buzón"
10. 🔄 Sistema de chat en tiempo real

