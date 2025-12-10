# 📱 SISTEMA DE CHAT - DOCUMENTACIÓN COMPLETA FINAL

## 🎯 DESCRIPCIÓN GENERAL

Sistema de chat en tiempo real para la aplicación "Donde Caiga", que permite la comunicación entre viajeros y anfitriones a través de reservas confirmadas. Incluye códigos de verificación de 6 dígitos generados automáticamente.

---

## 📋 TABLA DE CONTENIDOS

1. [Características Implementadas](#características-implementadas)
2. [Estructura de Base de Datos](#estructura-de-base-de-datos)
3. [Arquitectura Flutter](#arquitectura-flutter)
4. [Instalación y Configuración](#instalación-y-configuración)
5. [Guía de Uso](#guía-de-uso)
6. [Solución de Problemas](#solución-de-problemas)

---

## ✅ CARACTERÍSTICAS IMPLEMENTADAS

### 1. Códigos de Verificación
- Generación automática de códigos de 6 dígitos
- Se genera cuando una reserva pasa a estado "confirmada"
- Botón para mostrar/ocultar el código
- Visible tanto para viajero como para anfitrión

### 2. Lista de Chats
- Muestra todas las reservas confirmadas
- Funciona para viajeros (ven sus reservas)
- Funciona para anfitriones (ven reservas de sus propiedades)
- Información de la propiedad y fechas
- Badge "ACEPTADA" en verde
- Código de verificación destacado

### 3. Conversación de Chat
- Mensajes en tiempo real con Supabase Realtime
- Burbujas de chat diferenciadas (propias/ajenas)
- Timestamps en cada mensaje
- Scroll automático al enviar
- Código de verificación en el header
- Estados de carga

### 4. Seguridad
- RLS (Row Level Security) implementado
- Solo participantes pueden ver/enviar mensajes
- Solo reservas confirmadas permiten chat
- Validación de permisos en backend

---

## 🗄️ ESTRUCTURA DE BASE DE DATOS

### Tabla: `reservas`
```sql
- id (UUID, PK)
- propiedad_id (UUID, FK → propiedades)
- viajero_id (UUID, FK → users_profiles)
- fecha_inicio (DATE)
- fecha_fin (DATE)
- estado (TEXT) → 'pendiente', 'confirmada', 'rechazada', 'cancelada'
- codigo_verificacion (TEXT) → 6 dígitos, generado automáticamente
- created_at (TIMESTAMPTZ)
- updated_at (TIMESTAMPTZ)
```

### Tabla: `mensajes`
```sql
- id (UUID, PK)
- reserva_id (UUID, FK → reservas)
- remitente_id (UUID, FK → users_profiles)
- mensaje (TEXT)
- leido (BOOLEAN)
- created_at (TIMESTAMPTZ)
```

### Triggers
- `trigger_asignar_codigo_verificacion`: Genera código al confirmar reserva
- Función: `generar_codigo_verificacion()`: Genera código aleatorio de 6 dígitos
- Función: `asignar_codigo_verificacion()`: Lógica del trigger

### Políticas RLS
1. **Participantes pueden ver mensajes de su reserva**: Viajeros y anfitriones ven mensajes de sus reservas
2. **Participantes pueden enviar mensajes**: Solo en reservas confirmadas
3. **Usuarios pueden actualizar estado de lectura**: Marcar mensajes como leídos
4. **Admins tienen acceso completo**: Para moderación

---

## 🏗️ ARQUITECTURA FLUTTER

### Estructura de Carpetas
```
lib/features/
├── chat/
│   ├── data/
│   │   ├── models/
│   │   │   └── mensaje.dart
│   │   └── repositories/
│   │       └── mensaje_repository.dart
│   └── presentation/
│       └── screens/
│           └── chat_conversacion_screen.dart
├── buzon/
│   └── presentation/
│       └── screens/
│           └── chat_lista_screen.dart
└── reservas/
    ├── data/
    │   ├── models/
    │   │   └── reserva.dart
    │   └── repositories/
    │       └── reserva_repository.dart
    └── presentation/
        └── screens/
            └── reserva_calendario_screen.dart
```

### Componentes Principales

#### 1. `mensaje.dart` - Modelo de Mensaje
```dart
class Mensaje {
  final String id;
  final String reservaId;
  final String remitenteId;
  final String mensaje;
  final bool leido;
  final DateTime createdAt;
}
```

#### 2. `mensaje_repository.dart` - Repositorio de Mensajes
Métodos:
- `enviarMensaje()`: Envía un mensaje
- `obtenerMensajes()`: Obtiene mensajes de una reserva
- `suscribirseAMensajes()`: Suscripción Realtime
- `marcarComoLeido()`: Marca mensaje como leído

#### 3. `chat_lista_screen.dart` - Lista de Chats
Funcionalidades:
- Obtiene reservas del viajero
- Obtiene reservas del anfitrión
- Combina ambas listas
- Muestra código de verificación
- Navegación a conversación

#### 4. `chat_conversacion_screen.dart` - Conversación
Funcionalidades:
- Carga mensajes existentes
- Suscripción Realtime para nuevos mensajes
- Envío de mensajes
- Scroll automático
- Código de verificación en header

#### 5. `reserva_repository.dart` - Repositorio de Reservas
Métodos relevantes:
- `obtenerReservasViajero()`: Reservas confirmadas del viajero
- `obtenerReservasAnfitrion()`: Reservas confirmadas del anfitrión

---

## 🚀 INSTALACIÓN Y CONFIGURACIÓN

### Paso 1: Ejecutar SQL en Supabase

1. Abre tu proyecto en Supabase
2. Ve a SQL Editor
3. Ejecuta el archivo `SISTEMA_CHAT_FINAL.sql`
4. Verifica que no haya errores

### Paso 2: Verificar Configuración

Ejecuta estas consultas para verificar:

```sql
-- Verificar tabla mensajes
SELECT * FROM mensajes LIMIT 1;

-- Verificar políticas
SELECT policyname FROM pg_policies WHERE tablename = 'mensajes';

-- Verificar Realtime
SELECT tablename FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' AND tablename = 'mensajes';

-- Verificar código de verificación
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'reservas' AND column_name = 'codigo_verificacion';
```

### Paso 3: Código Flutter

El código Flutter ya está implementado en:
- `lib/features/chat/` - Sistema de mensajes
- `lib/features/buzon/presentation/screens/chat_lista_screen.dart` - Lista de chats
- `lib/features/reservas/` - Sistema de reservas

---

## 📖 GUÍA DE USO

### Para Viajeros

1. **Crear una Reserva**
   - Ve a "Explorar"
   - Selecciona una propiedad
   - Elige fechas y confirma
   - Estado inicial: "pendiente"

2. **Esperar Aprobación**
   - El anfitrión debe aprobar la reserva
   - Recibirás notificación cuando se apruebe

3. **Acceder al Chat**
   - Ve a la pestaña "Chat"
   - Verás tu reserva confirmada
   - Click en el ícono del ojo para ver el código
   - Click en "Abrir Chat"

4. **Chatear**
   - Escribe mensajes al anfitrión
   - Los mensajes aparecen en tiempo real
   - Muestra el código al llegar a la propiedad

### Para Anfitriones

1. **Aprobar Reserva**
   - Ve a "Anfitrión" → "Mis Reservas"
   - Verás reservas pendientes
   - Click en "Aprobar"
   - Se genera automáticamente el código

2. **Acceder al Chat**
   - Ve a la pestaña "Chat"
   - Verás reservas de tus propiedades
   - Click en "Abrir Chat"

3. **Chatear**
   - Responde mensajes del viajero
   - Los mensajes aparecen en tiempo real
   - Verifica el código cuando el viajero llegue

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### Problema: No aparecen reservas en el Chat

**Causa**: La reserva no está en estado "confirmada"

**Solución**:
1. Verifica el estado de la reserva en Supabase
2. Asegúrate de que el anfitrión haya aprobado la reserva
3. Ejecuta en Supabase:
```sql
SELECT id, estado FROM reservas WHERE viajero_id = 'TU_USER_ID';
```

### Problema: No se pueden enviar mensajes

**Causa**: Tabla mensajes no existe o RLS mal configurado

**Solución**:
1. Ejecuta `SISTEMA_CHAT_FINAL.sql` completo
2. Verifica que la tabla existe:
```sql
SELECT * FROM mensajes LIMIT 1;
```
3. Verifica políticas RLS:
```sql
SELECT policyname FROM pg_policies WHERE tablename = 'mensajes';
```

### Problema: Los mensajes no aparecen en tiempo real

**Causa**: Realtime no está habilitado

**Solución**:
1. Ejecuta en Supabase:
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE mensajes;
```
2. Reinicia la app Flutter
3. Verifica:
```sql
SELECT tablename FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' AND tablename = 'mensajes';
```

### Problema: El código de verificación no se genera

**Causa**: Trigger no está creado

**Solución**:
1. Ejecuta la sección de triggers del SQL
2. Verifica que existe:
```sql
SELECT tgname FROM pg_trigger WHERE tgname = 'trigger_asignar_codigo_verificacion';
```
3. Prueba manualmente:
```sql
UPDATE reservas SET estado = 'confirmada' WHERE id = 'RESERVA_ID';
SELECT codigo_verificacion FROM reservas WHERE id = 'RESERVA_ID';
```

### Problema: El anfitrión no ve chats

**Causa**: Código solo obtenía reservas del viajero

**Solución**: Ya está corregido en la versión final. El código ahora obtiene:
- Reservas como viajero
- Reservas como anfitrión (de sus propiedades)
- Combina ambas listas

### Problema: Error "policy already exists"

**Causa**: Intentaste ejecutar el SQL dos veces

**Solución**: Usa `SISTEMA_CHAT_FINAL.sql` que incluye `DROP POLICY IF EXISTS`

---

## 📊 FLUJO COMPLETO DEL SISTEMA

```
1. Viajero crea reserva
   ↓
2. Estado: "pendiente"
   ↓
3. Anfitrión aprueba
   ↓
4. Estado: "confirmada" + Código generado (trigger)
   ↓
5. Aparece en "Chat" para ambos
   ↓
6. Ambos pueden ver el código
   ↓
7. Ambos pueden chatear en tiempo real
   ↓
8. Viajero muestra código al llegar
```

---

## 🎨 DISEÑO DE INTERFAZ

### Lista de Chats
```
┌─────────────────────────────────────┐
│ Chat                                │
├─────────────────────────────────────┤
│ 🏠 Casa en la playa       ACEPTADA  │
│ Anfitrión: Juan • 15/01 - 20/01    │
│ ┌─────────────────────────────────┐ │
│ │ ✓ Código de Verificación        │ │
│ │   573939  👁                    │ │
│ │ Muestra este código al anfitrión│ │
│ └─────────────────────────────────┘ │
│                      [Abrir Chat]   │
└─────────────────────────────────────┘
```

### Conversación
```
┌─────────────────────────────────────┐
│ ← Casa en la playa                  │
│   15/01 - 20/01                     │
├─────────────────────────────────────┤
│ Código: 573939 👁                   │
├─────────────────────────────────────┤
│                                     │
│  ┌──────────────────────┐           │
│  │ Hola, ¿a qué hora    │           │
│  │ puedo hacer check-in?│           │
│  │                 10:30│           │
│  └──────────────────────┘           │
│                                     │
│           ┌──────────────────────┐  │
│           │ Puedes hacer check-in│  │
│           │ a partir de las 3 PM │  │
│           │                 10:32│  │
│           └──────────────────────┘  │
│                                     │
├─────────────────────────────────────┤
│ [Escribe un mensaje...        ] ✉️ │
└─────────────────────────────────────┘
```

---

## 🔐 SEGURIDAD

### Políticas RLS Implementadas

1. **Ver Mensajes**: Solo participantes de la reserva
2. **Enviar Mensajes**: Solo en reservas confirmadas
3. **Actualizar Mensajes**: Solo marcar como leído
4. **Admins**: Acceso completo para moderación

### Validaciones

- Usuario autenticado requerido
- Verificación de participación en reserva
- Estado de reserva debe ser "confirmada"
- Remitente debe ser el usuario actual

---

## 📈 MEJORAS FUTURAS OPCIONALES

- [ ] Notificaciones push para nuevos mensajes
- [ ] Indicador "escribiendo..."
- [ ] Mensajes leídos con doble check
- [ ] Adjuntar imágenes en el chat
- [ ] Búsqueda de mensajes
- [ ] Eliminar mensajes
- [ ] Reacciones a mensajes
- [ ] Mensajes de voz

---

## ✅ CHECKLIST DE VERIFICACIÓN

- [x] Tabla `reservas` con campo `codigo_verificacion`
- [x] Trigger para generar códigos automáticamente
- [x] Tabla `mensajes` con estructura correcta
- [x] Políticas RLS configuradas
- [x] Realtime habilitado
- [x] Modelo `Mensaje` en Flutter
- [x] Repositorio `MensajeRepository`
- [x] Pantalla `ChatListaScreen`
- [x] Pantalla `ChatConversacionScreen`
- [x] Navegación completa
- [x] Funciona para viajeros
- [x] Funciona para anfitriones
- [x] Mensajes en tiempo real
- [x] Código de verificación visible
- [x] Sin warnings de compilación

---

## 📝 NOTAS TÉCNICAS

### Dependencias Flutter
- `supabase_flutter`: Cliente de Supabase
- `intl`: Formateo de fechas

### Configuración Supabase
- RLS habilitado en todas las tablas
- Realtime habilitado en tabla `mensajes`
- Triggers para automatización

### Rendimiento
- Índices en campos frecuentemente consultados
- Paginación no implementada (agregar si hay muchos mensajes)
- Realtime optimizado con filtros

---

**Sistema de Chat: 100% Funcional** ✅

Fecha de última actualización: 2025-12-04
Versión: 1.0.0
