# 🔔 SISTEMA DE NOTIFICACIONES COMPLETO - DONDE CAIGA

## 📋 ÍNDICE
1. [Descripción General](#descripción-general)
2. [Características Principales](#características-principales)
3. [Arquitectura del Sistema](#arquitectura-del-sistema)
4. [Tipos de Notificaciones](#tipos-de-notificaciones)
5. [Componentes Implementados](#componentes-implementados)
6. [Base de Datos](#base-de-datos)
7. [Notificaciones Push](#notificaciones-push)
8. [Integración en la App](#integración-en-la-app)
9. [Configuración](#configuración)
10. [Uso y Navegación](#uso-y-navegación)
11. [Mantenimiento](#mantenimiento)

---

## 🎯 DESCRIPCIÓN GENERAL

El sistema de notificaciones de **Donde Caiga** es una solución completa y robusta que mantiene a los usuarios informados sobre todas las actividades importantes de la plataforma. Está diseñado para ser **no intrusivo**, **organizado** y **eficiente**.

### ✨ Filosofía del Sistema
- **Relevancia**: Solo notificaciones importantes y útiles
- **Organización**: Agrupadas por tipo para fácil navegación
- **Acción directa**: Cada notificación lleva a la pantalla correspondiente
- **Tiempo real**: Actualizaciones instantáneas via WebSockets
- **Multiplataforma**: Notificaciones push nativas

---

## 🚀 CARACTERÍSTICAS PRINCIPALES

### 🎨 Interfaz de Usuario
- **Icono de campanita** en la esquina superior derecha
- **Badge rojo** con contador de notificaciones no leídas
- **Diseño adaptativo** para modo claro y oscuro
- **Animaciones suaves** y transiciones fluidas

### 📱 Funcionalidades
- ✅ **Vista de todas las notificaciones** ordenadas cronológicamente
- ✅ **Vista agrupada por tipo** para mejor organización
- ✅ **Filtros inteligentes** (por tipo, solo no leídas, fechas)
- ✅ **Navegación directa** a pantallas relevantes
- ✅ **Marcar como leída** individual o masivamente
- ✅ **Eliminar notificaciones** con confirmación
- ✅ **Actualización en tiempo real** via Supabase Realtime
- ✅ **Notificaciones push** para dispositivos móviles

### 🔄 Tiempo Real
- **WebSockets** para actualizaciones instantáneas
- **Sincronización automática** entre dispositivos
- **Contador dinámico** que se actualiza al instante

---

## 🏗️ ARQUITECTURA DEL SISTEMA

```
┌─────────────────────────────────────────────────────────────┐
│                    SISTEMA DE NOTIFICACIONES                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   SUPABASE DB   │    │  PUSH SERVICE   │                │
│  │                 │    │                 │                │
│  │ • Notificaciones│    │ • Firebase FCM  │                │
│  │ • Triggers      │    │ • Local Notifs  │                │
│  │ • Functions     │    │ • Permissions   │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                        │
│           └───────────┬───────────┘                        │
│                       │                                    │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              FLUTTER APP LAYER                          │ │
│  │                                                         │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │ │
│  │  │  PROVIDER   │  │ REPOSITORY  │  │   WIDGETS   │    │ │
│  │  │             │  │             │  │             │    │ │
│  │  │ • Estado    │  │ • API Calls │  │ • Icono     │    │ │
│  │  │ • Filtros   │  │ • Realtime  │  │ • Cards     │    │ │
│  │  │ • Contador  │  │ • CRUD Ops  │  │ • Pantallas │    │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘    │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📬 TIPOS DE NOTIFICACIONES

### 🏠 **Reservas y Propiedades**
| Tipo | Descripción | Navegación |
|------|-------------|------------|
| `solicitudReserva` | Nueva solicitud para tu propiedad | → Mis Reservas (Anfitrión) |
| `reservaAceptada` | Tu reserva fue aceptada | → Mis Reservas |
| `reservaRechazada` | Tu reserva fue rechazada | → Mis Reservas |
| `llegadaHuesped` | Tu huésped ha llegado | → Mis Reservas (Anfitrión) |
| `finEstadia` | La estadía ha terminado | → Mis Reservas (Anfitrión) |

### ⭐ **Reseñas**
| Tipo | Descripción | Navegación |
|------|-------------|------------|
| `nuevaResena` | Recibiste una nueva reseña | → Perfil |

### 👤 **Anfitrión**
| Tipo | Descripción | Navegación |
|------|-------------|------------|
| `solicitudAnfitrion` | Solicitud para ser anfitrión | → Modal con detalles |
| `anfitrionAceptado` | Solicitud aprobada | → Modal con comentarios |
| `anfitrionRechazado` | Solicitud rechazada | → Modal con comentarios |

### 💬 **Mensajes**
| Tipo | Descripción | Navegación |
|------|-------------|------------|
| `nuevoMensaje` | Nuevo mensaje en chat | → Chat específico |

### ⏰ **Recordatorios**
| Tipo | Descripción | Navegación |
|------|-------------|------------|
| `recordatorioCheckin` | Recordatorio de check-in | → Mis Reservas |
| `recordatorioCheckout` | Recordatorio de check-out | → Mis Reservas |

### ℹ️ **General**
| Tipo | Descripción | Navegación |
|------|-------------|------------|
| `general` | Notificaciones del sistema | → Modal con detalles |

---

## 🧩 COMPONENTES IMPLEMENTADOS

### 📁 Estructura de Archivos
```
lib/features/notificaciones/
├── data/
│   ├── models/
│   │   └── notificacion.dart              # Modelo de datos
│   └── repositories/
│       └── notificaciones_repository.dart # Lógica de datos
├── presentation/
│   ├── providers/
│   │   └── notificaciones_provider.dart   # Estado global
│   ├── screens/
│   │   └── notificaciones_screen.dart     # Pantalla principal
│   └── widgets/
│       ├── icono_notificaciones.dart      # Icono con badge
│       ├── notificacion_card.dart         # Tarjeta individual
│       └── filtro_notificaciones.dart     # Panel de filtros
└── services/
    └── push_notifications_service.dart    # Servicio de push
```

### 🎨 Widgets Principales

#### 1. **IconoNotificaciones**
```dart
// Icono principal con badge
IconoNotificaciones(
  size: 24,
  color: Colors.white,
  padding: EdgeInsets.all(8),
)

// Versión compacta para AppBar
IconoNotificacionesCompacto()
```

#### 2. **NotificacionCard**
- Diseño adaptativo (claro/oscuro)
- Indicador visual de no leída
- Navegación automática según tipo
- Menú contextual (marcar leída, eliminar)
- Formateo inteligente de tiempo

#### 3. **NotificacionesScreen**
- Dos pestañas: "Todas" y "Por Tipo"
- Pull-to-refresh
- Filtros avanzados
- Marcar todas como leídas
- Estados de carga y error

---

## 🗄️ BASE DE DATOS

### 📊 Tabla Principal
```sql
CREATE TABLE notificaciones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id),
    tipo VARCHAR(50) NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    mensaje TEXT NOT NULL,
    datos JSONB,                    -- Datos adicionales
    imagen_url TEXT,                -- URL de imagen opcional
    leida BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 🔐 Seguridad (RLS)
- **Políticas de seguridad** a nivel de fila
- Los usuarios **solo ven sus propias notificaciones**
- **Sistema puede insertar** notificaciones para cualquier usuario
- **Usuarios pueden actualizar/eliminar** sus notificaciones

### ⚡ Optimizaciones
```sql
-- Índices para consultas rápidas
CREATE INDEX idx_notificaciones_usuario_id ON notificaciones(usuario_id);
CREATE INDEX idx_notificaciones_tipo ON notificaciones(tipo);
CREATE INDEX idx_notificaciones_leida ON notificaciones(leida);
CREATE INDEX idx_notificaciones_fecha_creacion ON notificaciones(fecha_creacion DESC);
```

### 🔄 Triggers Automáticos
- **Nueva reserva** → Notificación al anfitrión
- **Estado de reserva cambia** → Notificación al viajero
- **Nueva reseña** → Notificación al usuario reseñado

### 🛠️ Funciones Utilitarias
```sql
-- Crear notificaciones específicas
crear_notificacion_solicitud_reserva()
crear_notificacion_decision_reserva()
crear_notificacion_nueva_resena()
crear_notificacion_decision_anfitrion()
crear_notificacion_nuevo_mensaje()

-- Utilidades
marcar_todas_notificaciones_leidas()
limpiar_notificaciones_antiguas()
```

---

## 📱 NOTIFICACIONES PUSH

### 🔧 Configuración
```dart
// Inicialización automática en main.dart
final pushService = PushNotificationsService();
await pushService.initialize();
```

### 📋 Características
- **Firebase Cloud Messaging** (FCM) para Android/iOS
- **Notificaciones locales** como fallback
- **Permisos automáticos** con manejo de errores
- **Token management** para targeting específico
- **Payload personalizado** para navegación directa

### 🎯 Funcionalidades
```dart
// Mostrar notificación local
await pushService.showLocalNotification(
  title: 'Nueva reserva',
  body: 'Juan quiere reservar tu propiedad',
  payload: {'reserva_id': '123', 'tipo': 'solicitudReserva'},
);

// Desde modelo de notificación
await pushService.showNotificationFromModel(notificacion);
```

### 🔔 Estados de la App
- **Primer plano**: Notificación local + actualización en tiempo real
- **Segundo plano**: Notificación push nativa
- **App cerrada**: Notificación push que abre la app

---

## 🔗 INTEGRACIÓN EN LA APP

### 1. **Provider Global**
```dart
// En main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => NotificacionesProvider()),
    // ... otros providers
  ],
  child: MyApp(),
)
```

### 2. **Inicialización Automática**
```dart
// Al hacer login
await context.read<NotificacionesProvider>().inicializar();

// Al hacer logout
context.read<NotificacionesProvider>().limpiar();
```

### 3. **Uso en Pantallas**
```dart
// Agregar icono a cualquier AppBar
AppBar(
  title: Text('Mi Pantalla'),
  actions: [
    IconoNotificacionesCompacto(),
  ],
)

// Acceder al contador
Consumer<NotificacionesProvider>(
  builder: (context, provider, child) {
    return Text('${provider.contadorNoLeidas} nuevas');
  },
)
```

---

## ⚙️ CONFIGURACIÓN

### 📦 Dependencias Requeridas
```yaml
dependencies:
  flutter_local_notifications: ^17.0.0
  firebase_messaging: ^14.7.10
  firebase_core: ^2.24.2
  supabase_flutter: ^2.0.0
  provider: ^6.1.1
```

### 🔧 Configuración Android
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 🍎 Configuración iOS
```xml
<!-- ios/Runner/Info.plist -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### 🔥 Firebase Setup
1. Crear proyecto en Firebase Console
2. Agregar apps Android/iOS
3. Descargar `google-services.json` y `GoogleService-Info.plist`
4. Configurar en `android/app/` e `ios/Runner/`

---

## 🧭 USO Y NAVEGACIÓN

### 📱 Flujo de Usuario

#### 1. **Recibir Notificación**
```
Usuario recibe notificación → Badge aparece en icono → Contador se actualiza
```

#### 2. **Ver Notificaciones**
```
Tap en icono → Pantalla de notificaciones → Dos pestañas disponibles
```

#### 3. **Interactuar con Notificación**
```
Tap en notificación → Marcar como leída → Navegar a pantalla relevante
```

#### 4. **Gestionar Notificaciones**
```
Filtrar por tipo → Marcar todas como leídas → Eliminar individuales
```

### 🎯 Navegación Automática

| Tipo de Notificación | Destino |
|---------------------|---------|
| Solicitud de reserva | Mis Reservas (Anfitrión) |
| Reserva aceptada/rechazada | Mis Reservas |
| Nueva reseña | Perfil del usuario |
| Nuevo mensaje | Chat específico |
| Decisión anfitrión | Modal con detalles |
| Llegada/salida huésped | Mis Reservas (Anfitrión) |

### 🔍 Filtros Disponibles
- **Solo no leídas**: Mostrar únicamente notificaciones sin leer
- **Por tipo**: Filtrar por uno o varios tipos específicos
- **Por fecha**: Rango de fechas personalizado
- **Combinados**: Múltiples filtros simultáneos

---

## 🛠️ MANTENIMIENTO

### 📊 Monitoreo
```sql
-- Estadísticas de notificaciones
SELECT 
    tipo,
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE leida = false) as no_leidas,
    AVG(EXTRACT(EPOCH FROM (fecha_actualizacion - fecha_creacion))) as tiempo_promedio_lectura
FROM notificaciones 
WHERE fecha_creacion > NOW() - INTERVAL '30 days'
GROUP BY tipo;
```

### 🧹 Limpieza Automática
```sql
-- Ejecutar mensualmente
SELECT limpiar_notificaciones_antiguas(); -- Elimina notificaciones > 30 días
```

### 📈 Optimización
- **Índices** optimizados para consultas frecuentes
- **Paginación** en listas largas de notificaciones
- **Lazy loading** para mejor rendimiento
- **Cache local** para reducir llamadas a la API

### 🔧 Troubleshooting

#### Problema: Notificaciones no llegan
```dart
// Verificar permisos
final hasPermissions = await PushNotificationsService().areNotificationsEnabled();
if (!hasPermissions) {
  await PushNotificationsService().requestPermissions();
}
```

#### Problema: Contador incorrecto
```dart
// Refrescar contador manualmente
await context.read<NotificacionesProvider>().actualizarContadorNoLeidas();
```

#### Problema: Navegación no funciona
```dart
// Verificar datos de la notificación
debugPrint('Datos notificación: ${notificacion.datos}');
```

---

## 🎉 CONCLUSIÓN

El sistema de notificaciones de **Donde Caiga** es una solución completa que:

✅ **Mantiene informados** a los usuarios sobre actividades importantes  
✅ **Organiza inteligentemente** las notificaciones por tipo y relevancia  
✅ **Facilita la navegación** directa a pantallas relacionadas  
✅ **Funciona en tiempo real** con actualizaciones instantáneas  
✅ **Soporta notificaciones push** nativas multiplataforma  
✅ **Es escalable y mantenible** con arquitectura modular  

### 🚀 Próximas Mejoras
- **Notificaciones programadas** para recordatorios
- **Configuración personalizada** de tipos de notificación
- **Notificaciones por email** como backup
- **Analytics** de engagement con notificaciones
- **A/B testing** para optimizar mensajes

---

**¡El sistema está listo para mantener a tus usuarios siempre conectados con Donde Caiga! 🔔✨**