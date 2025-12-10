# 🌐 APIs y Servicios Externos Utilizados

**Proyecto**: Donde Caiga v2  
**Fecha**: 8 de Diciembre de 2025  
**Versión**: 1.0.0

---

## 📋 Resumen

Este documento lista todas las APIs y servicios externos utilizados en el proyecto "Donde Caiga".

---

## 🔑 APIs Principales

### 1. **Supabase** (Backend as a Service)
**Proveedor**: Supabase Inc.  
**Tipo**: BaaS (Backend as a Service)  
**URL Base**: `https://louehuwimvwsoqesjjau.supabase.co`

#### Servicios Utilizados:

#### 🔐 **Supabase Auth**
- **Propósito**: Autenticación y gestión de usuarios
- **Funcionalidades**:
  - Registro de usuarios
  - Login/Logout
  - Gestión de sesiones
  - Recuperación de contraseñas
  - Tokens JWT

#### 🗄️ **Supabase Database (PostgreSQL)**
- **Propósito**: Base de datos relacional
- **Tablas**:
  - `users_profiles` - Perfiles de usuario
  - `roles` - Roles del sistema (viajero, anfitrión, admin)
  - `propiedades` - Alojamientos
  - `fotos_propiedades` - Fotos de propiedades
  - `reservas` - Reservas de alojamientos
  - `mensajes` - Chat entre usuarios
  - `solicitudes_anfitrion` - Solicitudes para ser anfitrión
  - `resenas` - Reseñas y calificaciones

#### 📦 **Supabase Storage**
- **Propósito**: Almacenamiento de archivos
- **Buckets**:
  - `profile-photos` - Fotos de perfil
  - `id-documents` - Documentos de identidad
  - `solicitudes-anfitrion` - Fotos de solicitudes
  - `propiedades-fotos` - Fotos de propiedades

#### ⚡ **Supabase Realtime**
- **Propósito**: Actualizaciones en tiempo real
- **Uso**: Sistema de chat/mensajería
- **Tabla suscrita**: `mensajes`

#### 🔒 **Row Level Security (RLS)**
- **Propósito**: Seguridad a nivel de fila
- **Estado**: Habilitado en producción
- **Políticas**: Definidas para cada tabla

---

### 2. **Nominatim API** (OpenStreetMap)
**Proveedor**: OpenStreetMap Foundation  
**Tipo**: API de Geocodificación Gratuita  
**URL Base**: `https://nominatim.openstreetmap.org`

#### Endpoints Utilizados:

#### 🔍 **Search Endpoint**
- **URL**: `https://nominatim.openstreetmap.org/search`
- **Método**: GET
- **Propósito**: Búsqueda de direcciones y lugares
- **Parámetros**:
  - `q` - Query de búsqueda
  - `format=json` - Formato de respuesta
  - `limit=5` - Límite de resultados
  - `addressdetails=1` - Incluir detalles de dirección
- **Headers**:
  - `User-Agent: DondeCaigaApp/1.0`
- **Uso en la app**: 
  - Búsqueda de direcciones al crear/editar propiedades
  - Autocompletado de direcciones
  - Conversión de texto a coordenadas (geocoding)

#### 📍 **Datos Retornados**:
- `display_name` - Nombre completo de la dirección
- `lat` - Latitud
- `lon` - Longitud
- `address` - Detalles de la dirección

---

### 3. **OpenStreetMap Tiles**
**Proveedor**: OpenStreetMap Contributors  
**Tipo**: Servicio de Mapas (Tiles)  
**URL Base**: `https://tile.openstreetmap.org`

#### Tiles Endpoint:
- **URL Pattern**: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- **Propósito**: Visualización de mapas
- **Parámetros**:
  - `{z}` - Nivel de zoom
  - `{x}` - Coordenada X del tile
  - `{y}` - Coordenada Y del tile
- **Uso en la app**:
  - Mapa interactivo para seleccionar ubicación
  - Visualización de propiedades en el mapa
  - Exploración geográfica

---

## 📦 Dependencias y Paquetes

### Paquetes de Flutter Utilizados:

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| `supabase_flutter` | ^2.0.0 | Cliente de Supabase |
| `image_picker` | ^1.0.7 | Selección de imágenes |
| `table_calendar` | ^3.0.9 | Calendario de reservas |
| `flutter_map` | ^7.0.2 | Visualización de mapas |
| `latlong2` | ^0.9.1 | Manejo de coordenadas |
| `http` | ^1.2.0 | Peticiones HTTP |
| `intl` | ^0.19.0 | Formateo de fechas |
| `shared_preferences` | ^2.2.2 | Almacenamiento local |
| `provider` | ^6.1.1 | Gestión de estado |
| `flutter_dotenv` | ^5.1.0 | Variables de entorno |
| `url_launcher` | ^6.2.5 | Abrir URLs externas |

---

## 🔐 Credenciales y Configuración

### Variables de Entorno (.env):

```env
SUPABASE_URL=https://louehuwimvwsoqesjjau.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

⚠️ **IMPORTANTE**: 
- Las credenciales de Supabase están en el archivo `.env`
- Este archivo NO debe subirse a repositorios públicos
- Usar `.gitignore` para excluir `.env`

---

## 📊 Flujo de Datos

### Arquitectura de APIs:

```
┌─────────────────┐
│   Flutter App   │
└────────┬────────┘
         │
         ├──────────────────┐
         │                  │
         ▼                  ▼
┌─────────────────┐  ┌──────────────────┐
│    Supabase     │  │  Nominatim API   │
│                 │  │  (OpenStreetMap) │
├─────────────────┤  └──────────────────┘
│ • Auth          │         │
│ • Database      │         │
│ • Storage       │         ▼
│ • Realtime      │  ┌──────────────────┐
└─────────────────┘  │  OSM Tile Server │
                     │  (Map Tiles)     │
                     └──────────────────┘
```

---

## 🌍 Servicios por Funcionalidad

### 🔐 Autenticación
- **API**: Supabase Auth
- **Endpoints**: `/auth/v1/*`

### 🏠 Gestión de Propiedades
- **APIs**: 
  - Supabase Database (CRUD)
  - Supabase Storage (Fotos)
  - Nominatim (Geocoding)
  - OpenStreetMap (Mapas)

### 📅 Sistema de Reservas
- **API**: Supabase Database
- **Tablas**: `reservas`, `propiedades`, `users_profiles`

### 💬 Chat/Mensajería
- **APIs**:
  - Supabase Database (Almacenamiento)
  - Supabase Realtime (Tiempo real)
- **Tabla**: `mensajes`

### 📸 Subida de Imágenes
- **API**: Supabase Storage
- **Buckets**: Múltiples según tipo de imagen

### 🗺️ Mapas y Ubicación
- **APIs**:
  - Nominatim (Búsqueda de direcciones)
  - OpenStreetMap (Tiles de mapa)
- **Librería**: flutter_map

---

## 💰 Costos y Límites

### Supabase (Plan Actual):
- **Plan**: Free Tier / Pro (verificar en dashboard)
- **Límites Free**:
  - 500 MB de base de datos
  - 1 GB de almacenamiento
  - 2 GB de transferencia
  - 50,000 usuarios activos mensuales
  - Realtime: 200 conexiones concurrentes

### Nominatim (OpenStreetMap):
- **Costo**: Gratuito
- **Límites**:
  - 1 petición por segundo
  - Requiere User-Agent válido
  - Uso justo (fair use)
- **Política**: https://operations.osmfoundation.org/policies/nominatim/

### OpenStreetMap Tiles:
- **Costo**: Gratuito
- **Límites**: Uso justo
- **Política**: https://operations.osmfoundation.org/policies/tiles/

---

## 🔒 Seguridad

### Medidas Implementadas:

1. **Supabase**:
   - ✅ Row Level Security (RLS) habilitado
   - ✅ Políticas de acceso por rol
   - ✅ JWT tokens para autenticación
   - ✅ HTTPS en todas las peticiones

2. **Nominatim**:
   - ✅ User-Agent personalizado
   - ✅ Rate limiting respetado
   - ✅ HTTPS

3. **Variables de Entorno**:
   - ✅ Credenciales en `.env`
   - ✅ `.env` en `.gitignore`
   - ⚠️ Anon key expuesta (es seguro, es pública)

---

## 📝 Notas Importantes

### Dependencias de APIs:

1. **Supabase es CRÍTICO**:
   - Sin Supabase, la app no funciona
   - Contiene toda la lógica de backend
   - Almacena todos los datos

2. **Nominatim es OPCIONAL**:
   - Se puede ingresar coordenadas manualmente
   - Mejora UX pero no es esencial

3. **OpenStreetMap Tiles es REEMPLAZABLE**:
   - Se puede usar Google Maps
   - Se puede usar Mapbox
   - Actualmente gratuito

### Recomendaciones:

- ✅ Monitorear uso de Supabase
- ✅ Respetar límites de Nominatim
- ✅ Considerar caché para búsquedas frecuentes
- ✅ Implementar manejo de errores robusto
- ⚠️ Considerar migrar a API de pago si escala

---

## 🔄 Alternativas

### Si necesitas cambiar de proveedor:

| Servicio Actual | Alternativas |
|----------------|--------------|
| Supabase | Firebase, AWS Amplify, Appwrite |
| Nominatim | Google Geocoding API, Mapbox Geocoding |
| OSM Tiles | Google Maps, Mapbox, HERE Maps |

---

## 📞 Soporte y Documentación

### Enlaces Útiles:

- **Supabase Docs**: https://supabase.com/docs
- **Nominatim Docs**: https://nominatim.org/release-docs/latest/
- **OpenStreetMap**: https://www.openstreetmap.org/
- **Flutter Map**: https://docs.fleaflet.dev/

---

**Última Actualización**: 8 de Diciembre de 2025  
**Mantenido por**: Equipo de Desarrollo Donde Caiga
