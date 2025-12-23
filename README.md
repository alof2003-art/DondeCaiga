# 🏠 DondeCaiga - Plataforma de Alojamientos

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Una aplicación móvil desarrollada en Flutter que conecta viajeros con anfitriones para alojamientos temporales. Incluye sistema completo de autenticación, reservas, chat, reseñas y administración.

## ✨ Características Principales

- 🔐 **Autenticación completa** con Supabase Auth
- 🏠 **Exploración de propiedades** con búsqueda avanzada
- 📅 **Sistema de reservas** con calendario interactivo
- 💬 **Chat integrado** con filtros inteligentes
- ⭐ **Sistema de reseñas** y calificaciones
- 👑 **Panel de administración** completo
- 🌙 **Modo oscuro** y configuraciones personalizables
- � **Diseeño responsivo** para todos los dispositivos

## � Inicio aRápido

### Prerrequisitos

- Flutter SDK 3.0+
- Dart 3.0+
- Cuenta de Supabase
- Google Places API Key (opcional)

### Instalación

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/alof2003-art/DondeCaiga.git
   cd DondeCaiga
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar variables de entorno**
   ```bash
   cp .env.example .env
   # Editar .env con tus credenciales de Supabase
   ```

4. **Configurar Supabase**
   - Ejecutar el SQL en [`docs/SUPABASE_ESQUEMA_COMPLETO_FINAL.sql`](docs/SUPABASE_ESQUEMA_COMPLETO_FINAL.sql)
   - Configurar Storage buckets
   - Habilitar autenticación por email

5. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 📱 Capturas de Pantalla

| Explorar | Chat | Perfil | Admin |
|----------|------|--------|-------|
| ![Explorar](assets/screenshots/explorar.png) | ![Chat](assets/screenshots/chat.png) | ![Perfil](assets/screenshots/perfil.png) | ![Admin](assets/screenshots/admin.png) |

## 🏗️ Arquitectura

```
lib/
├── core/                    # Funcionalidades centrales
│   ├── config/             # Configuraciones
│   ├── services/           # Servicios globales
│   ├── theme/              # Temas y estilos
│   └── widgets/            # Widgets reutilizables
├── features/               # Características por módulos
│   ├── auth/               # Autenticación
│   ├── explorar/           # Búsqueda de propiedades
│   ├── buzon/              # Sistema de chat
│   ├── perfil/             # Gestión de perfil
│   └── admin/              # Panel de administración
└── services/               # Servicios auxiliares
```

## 🗄️ Base de Datos

### Tablas Principales

- **users_profiles** - Perfiles de usuario
- **propiedades** - Propiedades disponibles
- **reservas** - Reservas realizadas
- **resenas** - Reseñas y calificaciones
- **mensajes** - Sistema de chat
- **admin_audit_log** - Auditoría administrativa

Ver esquema completo: [`docs/SUPABASE_ESQUEMA_COMPLETO_FINAL.sql`](docs/SUPABASE_ESQUEMA_COMPLETO_FINAL.sql)

## 🎯 Funcionalidades

### Para Viajeros
- ✅ Buscar y filtrar propiedades
- ✅ Hacer reservas con calendario
- ✅ Chat con anfitriones
- ✅ Escribir reseñas
- ✅ Gestionar perfil

### Para Anfitriones
- ✅ Publicar propiedades
- ✅ Gestionar reservas
- ✅ Chat con viajeros
- ✅ Ver reseñas recibidas

### Para Administradores
- ✅ Gestionar usuarios
- ✅ Aprobar solicitudes de anfitrión
- ✅ Moderar contenido
- ✅ Auditoría completa

## 🔧 Configuración

### Variables de Entorno (.env)

```env
SUPABASE_URL=tu_supabase_url
SUPABASE_ANON_KEY=tu_supabase_anon_key
GOOGLE_PLACES_API_KEY=tu_google_places_key
```

### Configuración de Supabase

1. Crear proyecto en Supabase
2. Ejecutar SQL del esquema
3. Configurar Storage buckets
4. Habilitar autenticación
5. Configurar RLS policies

## 📚 Documentación

- 📋 [**Documentación Completa**](docs/DOCUMENTACION_PROYECTO_COMPLETA_FINAL.md)
- 🗄️ [**Esquema de Base de Datos**](docs/SUPABASE_ESQUEMA_COMPLETO_FINAL.sql)
- 🔍 [**Validación BD vs Código**](docs/VALIDACION_BASE_DATOS_FINAL.md)
- 📚 [**Índice de Documentación**](docs/INDICE_DOCUMENTACION_FINAL.md)

## 🧪 Testing

```bash
# Ejecutar tests
flutter test

# Generar coverage
flutter test --coverage
```

## 🚀 Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contribuir

1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## � Cuhangelog

### v1.0.0 (Diciembre 2024)
- ✅ Sistema completo de autenticación
- ✅ CRUD de propiedades con calificaciones
- ✅ Sistema de reservas con validaciones
- ✅ Chat con filtros inteligentes
- ✅ Sistema de reseñas completo
- ✅ Panel de administración
- ✅ Modo oscuro y configuraciones
- ✅ Diseño responsivo

## 🐛 Reportar Bugs

Si encuentras un bug, por favor crea un [issue](https://github.com/alof2003-art/DondeCaiga/issues) con:

- Descripción del problema
- Pasos para reproducir
- Comportamiento esperado
- Screenshots (si aplica)
- Información del dispositivo

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 👥 Equipo

- **Desarrollador Principal**: [alof2003-art](https://github.com/alof2003-art)

## �  Agradecimientos

- [Flutter](https://flutter.dev/) - Framework de desarrollo
- [Supabase](https://supabase.com/) - Backend as a Service
- [Google Places API](https://developers.google.com/maps/documentation/places/web-service) - Búsqueda de direcciones

## 📊 Estadísticas del Proyecto

- **Líneas de código**: ~15,000+
- **Pantallas**: 20+ pantallas principales
- **Modelos de datos**: 8 modelos principales
- **Servicios**: 10+ servicios
- **Documentación**: 80+ archivos

---

**Desarrollado con ❤️ usando Flutter y Supabase**

*¿Te gusta el proyecto? ¡Dale una ⭐ en GitHub!*