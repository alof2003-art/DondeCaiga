# 📱 PLAN DE IMPLEMENTACIÓN DEL CHAT

## 🎯 OBJETIVO
Convertir el "Buzón" en un sistema de "Chat" con las siguientes características:

### 1. **Lista de Chats (Reservas Confirmadas)**
- ✅ Solo mostrar reservas con estado "confirmada"
- ✅ Mostrar foto, nombre del otro usuario (viajero o anfitrión)
- ✅ Mostrar título de la propiedad
- ✅ Mostrar fechas de la reserva

### 2. **Código de Verificación**
- ✅ Generar automáticamente cuando se confirma una reserva
- ✅ Código de 6 dígitos numéricos
- ✅ Botón para mostrar/ocultar el código (ícono de ojo)
- ✅ Texto: "Muestra este código al anfitrión al llegar"

### 3. **Chat en Tiempo Real**
- 📝 Mensajes entre viajero y anfitrión
- 📝 Solo disponible para reservas confirmadas
- 📝 Usar Supabase Realtime para mensajes

## 📋 TAREAS PENDIENTES

### Fase 1: Base de Datos ✅
- [x] Agregar campo `codigo_verificacion` a tabla `reservas`
- [x] Crear trigger para generar código automáticamente
- [x] Actualizar modelo `Reserva` en Flutter

### Fase 2: Interfaz de Lista de Chats
- [ ] Renombrar "Buzón" a "Chat" en la navegación
- [ ] Actualizar `buzon_screen.dart` para mostrar solo reservas confirmadas
- [ ] Mostrar código de verificación con botón mostrar/ocultar
- [ ] Diseño según la imagen proporcionada

### Fase 3: Pantalla de Chat Individual
- [ ] Crear `chat_conversacion_screen.dart`
- [ ] Mostrar información de la reserva en el header
- [ ] Mostrar código de verificación en la parte superior
- [ ] Área de mensajes
- [ ] Input para enviar mensajes

### Fase 4: Sistema de Mensajes
- [ ] Crear tabla `mensajes` en Supabase
- [ ] Crear modelo `Mensaje` en Flutter
- [ ] Crear repositorio `MensajeRepository`
- [ ] Implementar envío de mensajes
- [ ] Implementar recepción en tiempo real con Supabase Realtime

## 🗄️ ESTRUCTURA DE BASE DE DATOS

### Tabla: mensajes
```sql
CREATE TABLE mensajes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reserva_id UUID NOT NULL REFERENCES reservas(id) ON DELETE CASCADE,
    remitente_id UUID NOT NULL REFERENCES users_profiles(id),
    mensaje TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    leido BOOLEAN DEFAULT FALSE
);
```

## 📁 ARCHIVOS A CREAR/MODIFICAR

### Crear:
1. `lib/features/chat/data/models/mensaje.dart`
2. `lib/features/chat/data/repositories/mensaje_repository.dart`
3. `lib/features/chat/presentation/screens/chat_conversacion_screen.dart`
4. `lib/features/chat/presentation/widgets/mensaje_bubble.dart`
5. `lib/features/chat/presentation/widgets/codigo_verificacion_widget.dart`

### Modificar:
1. `lib/features/buzon/presentation/screens/buzon_screen.dart` → Renombrar a chat
2. `lib/features/main/presentation/screens/main_screen.dart` → Cambiar "Buzón" por "Chat"

## 🎨 DISEÑO SEGÚN IMAGEN

### Lista de Chats:
```
┌─────────────────────────────────────┐
│ Chat                                │
├─────────────────────────────────────┤
│ 🏠 Reserva en playa        ACEPTADA │
│ Anfitrión: Anfitrión • 2026-01-03  │
│ ┌─────────────────────────────────┐ │
│ │ ✓ Código de Verificación        │ │
│ │   573939  👁                    │ │
│ │ Muestra este código al anfitrión│ │
│ └─────────────────────────────────┘ │
│                              💬     │
├─────────────────────────────────────┤
│ 🏠 Reserva en casa         ACEPTADA │
│ Anfitrión: Anfitrión • 2025-12-26  │
│ ┌─────────────────────────────────┐ │
│ │ ✓ Código de Verificación        │ │
│ │   ••••••  👁                    │ │
│ │ Muestra este código al anfitrión│ │
│ └─────────────────────────────────┘ │
│                              💬     │
└─────────────────────────────────────┘
```

## 🚀 PRÓXIMOS PASOS

1. **Ejecutar SQL** en Supabase:
   - `agregar_codigo_verificacion_reservas.sql`

2. **Actualizar interfaz de lista de chats**
   - Mostrar solo reservas confirmadas
   - Agregar widget de código de verificación

3. **Crear pantalla de chat individual**
   - Header con info de reserva
   - Código de verificación
   - Lista de mensajes
   - Input de mensaje

4. **Implementar sistema de mensajes**
   - Tabla en Supabase
   - Realtime subscriptions
   - Envío y recepción

¿Por dónde quieres empezar?
