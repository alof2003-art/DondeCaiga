# 📱 DondeCaiga - Documentación Completa del Proyecto

## 🏠 **Descripción General**

DondeCaiga es una aplicación móvil desarrollada en Flutter que conecta viajeros con anfitriones para alojamientos temporales. La aplicación permite a los usuarios buscar propiedades, hacer reservas, gestionar chats y reseñas, todo con un sistema completo de autenticación y administración.

## 🏗️ **Arquitectura del Proyecto**

### **Stack Tecnológico**
- **Frontend**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Edge Functions)
- **Autenticación**: Supabase Auth
- **Base de Datos**: PostgreSQL (Supabase)
- **Storage**: Supabase Storage
- **Estado**: Provider
- **Navegación**: Navigator 2.0

### **Estructura del Proyecto**
```
lib/
├── core/                    # Funcionalidades centrales
│   ├── config/             # Configuraciones
│   ├── services/           # Servicios globales
│   ├── theme/              # Temas y estilos
│   ├── utils/              # Utilidades
│   └── widgets/            # Widgets reutilizables
├── features/               # Características por módulos
│   ├── admin/              # Panel de administración
│   ├── anfitrion/          # Gestión de anfitriones
│   ├── auth/               # Autenticación
│   ├── buzon/              # Sistema de chat/mensajería
│   ├── explorar/           # Búsqueda de propiedades
│   ├── perfil/             # Gestión de perfil
│   ├── propiedades/        # Gestión de propiedades
│   ├── resenas/            # Sistema de reseñas
│   └── reservas/           # Gestión de reservas
└── services/               # Servicios auxiliares
```

## 🎯 **Funcionalidades Principales**

### **1. Sistema de Autenticación**
- ✅ Registro de usuarios con email y contraseña
- ✅ Login con validación
- ✅ Splash screen con verificación de sesión
- ✅ Gestión de perfiles de usuario
- ✅ Sistema de roles (Viajero, Anfitrión, Admin)

### **2. Exploración de Propiedades**
- ✅ Lista de propiedades disponibles
- ✅ Búsqueda por ubicación con Google Places API
- ✅ Filtros avanzados
- ✅ Vista detallada de propiedades
- ✅ Sistema de calificaciones y reseñas
- ✅ Galería de fotos

### **3. Sistema de Reservas**
- ✅ Calendario de disponibilidad
- ✅ Creación de reservas
- ✅ Gestión de estados (pendiente, confirmada, completada, etc.)
- ✅ Validación de fechas y disponibilidad
- ✅ Historial de reservas

### **4. Sistema de Chat/Mensajería**
- ✅ Chat entre viajeros y anfitriones
- ✅ Filtros inteligentes (vigentes, pasadas, con reseñas pendientes)
- ✅ Apartados separados: "Mis Viajes" y "Mis Reservas"
- ✅ Estados de reservas en tiempo real
- ✅ Interfaz adaptativa según filtros

### **5. Sistema de Reseñas**
- ✅ Creación de reseñas por viajeros
- ✅ Calificaciones de 1-5 estrellas
- ✅ Comentarios opcionales
- ✅ Visualización en perfil de usuario
- ✅ Filtros por reseñas recibidas/hechas

### **6. Gestión de Anfitriones**
- ✅ Solicitudes para convertirse en anfitrión
- ✅ Subida de documentos (selfie, foto de propiedad)
- ✅ Aprobación por administradores
- ✅ Gestión de propiedades

### **7. Panel de Administración**
- ✅ Gestión de usuarios
- ✅ Aprobación de solicitudes de anfitrión
- ✅ Bloqueo/desbloqueo de cuentas
- ✅ Degradación de roles
- ✅ Auditoría de acciones administrativas

### **8. Características Adicionales**
- ✅ Modo oscuro/claro
- ✅ Tamaños de fuente configurables (4 niveles)
- ✅ Diseño responsivo
- ✅ Optimizaciones de rendimiento
- ✅ Manejo de errores robusto

## 🗄️ **Base de Datos**

### **Tablas Principales**

#### **users_profiles**
- Perfiles de usuario con información personal
- Roles y estados de cuenta
- Verificación de email

#### **propiedades**
- Información de propiedades
- Ubicación y características
- Estados y fotos

#### **reservas**
- Reservas entre viajeros y anfitriones
- Estados y fechas
- Códigos de verificación

#### **resenas**
- Reseñas de viajeros sobre propiedades
- Calificaciones y comentarios

#### **mensajes**
- Sistema de chat entre usuarios
- Mensajes por reserva

#### **solicitudes_anfitrion**
- Solicitudes para convertirse en anfitrión
- Documentos y estados de aprobación

#### **admin_audit_log**
- Registro de acciones administrativas
- Auditoría completa

#### **notifications** (preparada para futuro)
- Sistema de notificaciones
- Configuraciones por usuario

## 🔧 **Configuración y Servicios**

### **Servicios Core**
- **ThemeService**: Gestión de tema oscuro/claro
- **FontSizeService**: Configuración de tamaños de fuente
- **AuthService**: Autenticación y sesiones
- **StorageService**: Gestión de archivos

### **Configuraciones**
- **AppConfig**: Variables de entorno y configuración
- **PerformanceConfig**: Optimizaciones de rendimiento
- **ResponsiveUtils**: Utilidades para diseño responsivo

## 📱 **Pantallas Principales**

### **Autenticación**
- `SplashScreen`: Pantalla de carga inicial
- `LoginScreen`: Inicio de sesión
- `RegisterScreen`: Registro de usuarios

### **Navegación Principal**
- `MainScreen`: Navegación con tabs
- `ExplorarScreen`: Búsqueda de propiedades
- `AnfitrionScreen`: Panel de anfitrión
- `ChatListaScreen`: Sistema de mensajería
- `PerfilScreen`: Gestión de perfil

### **Funcionalidades Específicas**
- `DetallePropiedad`: Vista detallada de propiedades
- `ReservaCalendario`: Selección de fechas
- `CrearResena`: Creación de reseñas
- `AdminPanel`: Panel de administración

## 🔄 **Flujos de Usuario**

### **Flujo de Registro/Login**
1. SplashScreen verifica sesión existente
2. Si no hay sesión → LoginScreen
3. Si hay sesión → MainScreen
4. Registro crea perfil en users_profiles

### **Flujo de Reserva**
1. Usuario explora propiedades
2. Selecciona propiedad y fechas
3. Crea reserva (estado: pendiente)
4. Anfitrión confirma/rechaza
5. Si confirmada → aparece en chat

### **Flujo de Reseña**
1. Reserva completada o pasada su fecha
2. Viajero puede crear reseña
3. Reseña se asocia a propiedad y anfitrión
4. Aparece en perfil y cálculos de calificación

## 🛠️ **Mejoras y Arreglos Implementados**

### **Últimas Mejoras (Diciembre 2024)**
- ✅ Arreglo completo del sistema de filtros en chat
- ✅ Ocultación inteligente de secciones vacías
- ✅ Navegación de reseñas corregida
- ✅ Textos visibles en modo oscuro
- ✅ Lógica de filtrado optimizada
- ✅ Limpieza de logs de debug

### **Mejoras de UI/UX**
- ✅ Colores consistentes entre "Mis Viajes" y "Mis Reservas"
- ✅ Modo oscuro completo y funcional
- ✅ Tamaños de fuente globales
- ✅ Diseño responsivo completo
- ✅ Optimizaciones de rendimiento

### **Mejoras de Backend**
- ✅ Consultas SQL optimizadas
- ✅ Manejo robusto de errores
- ✅ Validaciones de datos
- ✅ Sistema de auditoría completo

## 🚀 **Estado Actual del Proyecto**

### **✅ Completado**
- Sistema de autenticación completo
- CRUD de propiedades funcional
- Sistema de reservas operativo
- Chat con filtros inteligentes
- Sistema de reseñas completo
- Panel de administración funcional
- Modo oscuro y configuraciones
- Diseño responsivo

### **🔄 En Preparación**
- Sistema de notificaciones (estructura lista)
- Mejoras de performance adicionales
- Funcionalidades de chat en tiempo real

## 📋 **Instrucciones de Desarrollo**

### **Requisitos**
- Flutter SDK 3.0+
- Dart 3.0+
- Cuenta de Supabase configurada
- Google Places API key

### **Configuración**
1. Clonar repositorio
2. Configurar variables de entorno en `.env`
3. Ejecutar `flutter pub get`
4. Configurar Supabase con el SQL proporcionado
5. Ejecutar `flutter run`

### **Estructura de Desarrollo**
- Seguir arquitectura por features
- Usar Provider para gestión de estado
- Implementar tests unitarios
- Documentar cambios importantes

## 📊 **Métricas del Proyecto**

- **Líneas de código**: ~15,000+
- **Pantallas**: 20+ pantallas principales
- **Modelos de datos**: 8 modelos principales
- **Servicios**: 10+ servicios
- **Widgets reutilizables**: 15+ widgets
- **Documentación**: 80+ archivos de documentación

## 🎯 **Próximos Pasos**

1. **Implementar notificaciones push**
2. **Mejorar sistema de chat en tiempo real**
3. **Añadir más filtros de búsqueda**
4. **Implementar sistema de pagos**
5. **Optimizaciones adicionales de performance**

---

**Proyecto desarrollado con ❤️ usando Flutter y Supabase**

*Última actualización: Diciembre 2024*