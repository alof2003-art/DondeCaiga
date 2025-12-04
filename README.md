# 🏠 Donde Caiga

Aplicación móvil de alojamiento que conecta viajeros con anfitriones, desarrollada con Flutter y Supabase.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)
![Estado](https://img.shields.io/badge/Estado-Producción-success.svg)

---

## 📋 Descripción

**Donde Caiga** es una plataforma móvil que permite a los viajeros encontrar alojamiento y a los anfitriones ofrecer sus propiedades. Similar a Airbnb, incluye funcionalidades completas de gestión de reservas, chat en tiempo real, y sistema de verificación.

### ✨ Características Principales

- 🔐 **Autenticación completa** con Supabase Auth
- 🏡 **Gestión de propiedades** con múltiples fotos
- 📅 **Sistema de reservas** con calendario
- 💬 **Chat en tiempo real** entre viajeros y anfitriones
- 🔢 **Códigos de verificación** automáticos para check-in
- 👥 **Sistema de roles** (Viajero, Anfitrión, Admin)
- 📱 **Solicitudes de anfitrión** con aprobación por admin
- 🔒 **Seguridad con RLS** (Row Level Security)

---

## 🚀 Inicio Rápido

### Prerrequisitos

- Flutter 3.0 o superior
- Dart 3.0 o superior
- Cuenta de Supabase
- Android Studio / VS Code

### Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/tu-usuario/donde_caigav2.git
cd donde_caigav2
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Configurar Supabase**
   - Crear proyecto en [Supabase](https://supabase.com)
   - Ejecutar `BASE_DATOS_COMPLETA_FINAL.sql` en el SQL Editor
   - Crear archivo `.env` con tus credenciales:
```env
SUPABASE_URL=tu_url_de_supabase
SUPABASE_ANON_KEY=tu_anon_key
```

4. **Ejecutar la aplicación**
```bash
flutter run
```

---

## 📚 Documentación

### 🌟 Documentos Principales

| Documento | Descripción |
|-----------|-------------|
| **[INDICE_DOCUMENTACION.md](INDICE_DOCUMENTACION.md)** | Índice maestro de toda la documentación |
| **[DOCUMENTACION_COMPLETA_PROYECTO.md](DOCUMENTACION_COMPLETA_PROYECTO.md)** | Documentación completa del proyecto |
| **[BASE_DATOS_COMPLETA_FINAL.sql](BASE_DATOS_COMPLETA_FINAL.sql)** | Esquema completo de base de datos |
| **[ESPECIFICACIONES_COMPLETAS.md](ESPECIFICACIONES_COMPLETAS.md)** | Especificaciones técnicas |

### 📖 Documentación por Funcionalidad

- **Chat**: [SISTEMA_CHAT_DOCUMENTACION_FINAL.md](SISTEMA_CHAT_DOCUMENTACION_FINAL.md)
- **Reservas**: [SISTEMA_RESERVAS_COMPLETO.md](SISTEMA_RESERVAS_COMPLETO.md)
- **Errores**: [ERRORES_Y_SOLUCIONES_SQL.sql](ERRORES_Y_SOLUCIONES_SQL.sql)

### 🔍 Guías Rápidas

- **Setup inicial**: Ver [DOCUMENTACION_COMPLETA_PROYECTO.md](DOCUMENTACION_COMPLETA_PROYECTO.md) → Sección "Setup Inicial"
- **Probar reservas**: Ver [COMO_PROBAR_RESERVAS.md](COMO_PROBAR_RESERVAS.md)
- **Verificar BD**: Ver [verificar_base_datos.md](verificar_base_datos.md)

---

## 🏗️ Arquitectura

### Estructura del Proyecto

```
lib/
├── core/                    # Utilidades y configuración
├── services/                # Servicios compartidos
└── features/                # Funcionalidades por módulo
    ├── auth/                # Autenticación
    ├── explorar/            # Búsqueda de propiedades
    ├── propiedades/         # Gestión de propiedades
    ├── reservas/            # Sistema de reservas
    ├── chat/                # Mensajería en tiempo real
    ├── buzon/               # Lista de chats
    ├── perfil/              # Perfil de usuario
    └── anfitrion/           # Solicitudes de anfitrión
```

### Base de Datos

8 tablas principales:
- `users_profiles` - Perfiles de usuario
- `roles` - Roles del sistema
- `propiedades` - Propiedades publicadas
- `reservas` - Reservas de alojamiento
- `mensajes` - Chat en tiempo real
- `solicitudes_anfitrion` - Solicitudes para ser anfitrión
- `fotos_propiedades` - Galería de fotos
- `resenas` - Reseñas de propiedades

Ver esquema completo en [BASE_DATOS_COMPLETA_FINAL.sql](BASE_DATOS_COMPLETA_FINAL.sql)

---

## 🔧 Tecnologías

### Frontend
- **Flutter** - Framework de UI
- **Dart** - Lenguaje de programación
- **Material Design** - Sistema de diseño

### Backend
- **Supabase** - Backend as a Service
- **PostgreSQL** - Base de datos
- **Supabase Auth** - Autenticación
- **Supabase Storage** - Almacenamiento de archivos
- **Supabase Realtime** - Mensajería en tiempo real

### Seguridad
- **Row Level Security (RLS)** - Políticas de seguridad a nivel de fila
- **JWT Tokens** - Autenticación segura
- **Storage Policies** - Control de acceso a archivos

---

## 👥 Roles de Usuario

### 🧳 Viajero (rol_id: 1)
- Buscar propiedades
- Crear reservas
- Chat con anfitriones
- Ver código de verificación
- Solicitar ser anfitrión

### 🏠 Anfitrión (rol_id: 2)
- Publicar propiedades
- Gestionar reservas
- Confirmar/rechazar solicitudes
- Chat con viajeros
- Ver código de verificación

### 👨‍💼 Administrador (rol_id: 3)
- Aprobar solicitudes de anfitrión
- Acceso completo a todas las tablas
- Gestión de usuarios

---

## 📱 Funcionalidades Detalladas

### 🔐 Autenticación
- Registro con email y contraseña
- Subida de foto de perfil
- Subida de documento de identidad
- Login persistente
- Recuperación de contraseña

### 🏡 Propiedades
- Crear/editar propiedades
- Subir múltiples fotos
- Información detallada (ubicación, capacidad, amenidades)
- Activar/desactivar publicación

### 📅 Reservas
- Calendario de disponibilidad
- Estados: pendiente, confirmada, rechazada, completada, cancelada
- Código de verificación automático (6 dígitos)
- Notificaciones de estado

### 💬 Chat
- Mensajes en tiempo real (Supabase Realtime)
- Solo para reservas confirmadas
- Código de verificación visible en header
- Burbujas diferenciadas por remitente
- Marca mensajes como leídos

---

## 🐛 Solución de Problemas

### Errores Comunes

**Error: No se puede conectar a Supabase**
- Verificar credenciales en `.env`
- Verificar que el proyecto de Supabase está activo

**Error: No se pueden subir imágenes**
- Verificar políticas de Storage
- Ejecutar `storage_policies_final.sql`

**Error: Mensajes no llegan en tiempo real**
- Verificar que Realtime está habilitado en tabla `mensajes`
- Verificar suscripción en código Flutter

Ver más soluciones en [ERRORES_Y_SOLUCIONES_SQL.sql](ERRORES_Y_SOLUCIONES_SQL.sql)

---

## 📊 Estado del Proyecto

### ✅ Completado
- Sistema de autenticación
- Gestión de propiedades
- Sistema de reservas
- Chat en tiempo real
- Códigos de verificación
- Solicitudes de anfitrión
- Panel de administración

### 🚧 En Desarrollo
- Sistema de reseñas (tabla creada, falta UI)
- Notificaciones push
- Búsqueda avanzada con filtros

### 📋 Planeado
- Sistema de pagos
- Calendario de disponibilidad avanzado
- Búsqueda por mapa
- Sistema de favoritos

---

## 🤝 Contribuir

### Para Nuevos Desarrolladores

1. Lee [DOCUMENTACION_COMPLETA_PROYECTO.md](DOCUMENTACION_COMPLETA_PROYECTO.md)
2. Revisa [INDICE_DOCUMENTACION.md](INDICE_DOCUMENTACION.md)
3. Configura el entorno siguiendo la sección "Instalación"
4. Revisa [ERRORES_Y_SOLUCIONES_SQL.sql](ERRORES_Y_SOLUCIONES_SQL.sql)

### Convenciones de Código

- **Dart**: Seguir [Effective Dart](https://dart.dev/guides/language/effective-dart)
- **SQL**: Nombres en snake_case
- **Commits**: Mensajes descriptivos en español

---

## 📞 Contacto

**Desarrollador Principal**: alof2003@gmail.com

---

## 📄 Licencia

Este proyecto es privado y confidencial.

---

## 🙏 Agradecimientos

- [Flutter](https://flutter.dev/) - Framework de desarrollo
- [Supabase](https://supabase.com/) - Backend as a Service
- [Material Design](https://material.io/) - Sistema de diseño

---

## 📝 Notas de Versión

### Versión 1.0.0 (2025-12-04)
- ✅ Sistema completo de autenticación
- ✅ Gestión de propiedades
- ✅ Sistema de reservas con códigos de verificación
- ✅ Chat en tiempo real
- ✅ Solicitudes de anfitrión
- ✅ Panel de administración
- ✅ Documentación completa

---

## 🔗 Enlaces Útiles

- [Documentación de Flutter](https://flutter.dev/docs)
- [Documentación de Supabase](https://supabase.com/docs)
- [Documentación de Dart](https://dart.dev/guides)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)

---

**Última Actualización**: 2025-12-04  
**Versión**: 1.0.0  
**Estado**: ✅ Producción
