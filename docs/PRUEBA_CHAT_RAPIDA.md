# 🧪 PRUEBA RÁPIDA DEL SISTEMA DE CHAT

## ✅ Pre-requisitos
- [x] Ejecutaste `arreglar_tabla_mensajes.sql` en Supabase
- [ ] Tienes dos usuarios de prueba (viajero y anfitrión)
- [ ] Tienes al menos una propiedad creada

## 📝 PASOS PARA PROBAR

### 1. Crear una Reserva (Como Viajero)
1. Inicia sesión como **viajero**
2. Ve a "Explorar"
3. Selecciona una propiedad
4. Click en "Reservar"
5. Selecciona fechas (inicio y fin)
6. Confirma la reserva
7. ✅ La reserva se crea con estado "pendiente"

### 2. Aprobar la Reserva (Como Anfitrión)
1. Cierra sesión
2. Inicia sesión como **anfitrión** (dueño de la propiedad)
3. Ve a "Anfitrión" → "Mis Reservas"
4. Deberías ver la reserva pendiente
5. Click en "Aprobar"
6. ✅ La reserva cambia a "confirmada"
7. ✅ Se genera automáticamente el código de verificación (6 dígitos)

### 3. Ver el Chat (Como Viajero)
1. Cierra sesión
2. Inicia sesión como **viajero**
3. Ve a la pestaña "Chat" (ícono de chat en la barra inferior)
4. ✅ Deberías ver la reserva confirmada
5. ✅ Deberías ver el código de verificación (oculto con puntos)
6. Click en el ícono del ojo 👁️
7. ✅ El código de 6 dígitos se muestra

### 4. Abrir la Conversación
1. Click en "Abrir Chat"
2. ✅ Se abre la pantalla de conversación
3. ✅ En el header ves:
   - Título de la propiedad
   - Fechas de la reserva
   - Código de verificación (con botón para mostrar/ocultar)

### 5. Enviar Mensajes (Como Viajero)
1. Escribe un mensaje: "Hola, ¿a qué hora puedo hacer check-in?"
2. Click en el botón de enviar ✉️
3. ✅ El mensaje aparece inmediatamente
4. ✅ El mensaje aparece en verde (derecha) porque es tuyo

### 6. Responder Mensajes (Como Anfitrión)
1. **SIN CERRAR LA APP DEL VIAJERO**
2. En otro dispositivo/navegador, inicia sesión como **anfitrión**
3. Ve a "Chat"
4. ✅ Deberías ver la misma reserva
5. Click en "Abrir Chat"
6. ✅ Deberías ver el mensaje del viajero
7. Escribe una respuesta: "Puedes hacer check-in a partir de las 3 PM"
8. Click en enviar
9. ✅ El mensaje aparece en gris (izquierda) porque es del otro usuario

### 7. Verificar Tiempo Real
1. Vuelve al dispositivo del **viajero**
2. ✅ El mensaje del anfitrión debería aparecer automáticamente
3. ✅ Sin necesidad de recargar o hacer pull-to-refresh

## ✅ CHECKLIST DE FUNCIONALIDADES

- [ ] La reserva se crea correctamente
- [ ] Al aprobar, se genera el código de verificación
- [ ] El código aparece en la lista de chats
- [ ] El código se puede mostrar/ocultar
- [ ] Se puede abrir la conversación
- [ ] El código aparece en el header del chat
- [ ] Se pueden enviar mensajes
- [ ] Los mensajes propios aparecen en verde (derecha)
- [ ] Los mensajes del otro usuario aparecen en gris (izquierda)
- [ ] Los mensajes aparecen en tiempo real
- [ ] Los timestamps se muestran correctamente

## 🐛 SI ALGO NO FUNCIONA

### No aparecen reservas en el Chat
- Verifica que la reserva esté en estado "confirmada"
- Revisa que estás logueado como el viajero de esa reserva

### No se pueden enviar mensajes
- Abre la consola de Flutter y busca errores
- Verifica que ejecutaste `arreglar_tabla_mensajes.sql`
- Verifica que la tabla `mensajes` tiene los campos correctos

### Los mensajes no aparecen en tiempo real
- Verifica que Realtime está habilitado en Supabase
- Ejecuta en Supabase:
  ```sql
  SELECT tablename FROM pg_publication_tables 
  WHERE pubname = 'supabase_realtime' AND tablename = 'mensajes';
  ```
- Debería devolver 1 fila

### Error al cargar mensajes
- Revisa la consola de Flutter
- Verifica que las políticas RLS están configuradas
- Ejecuta en Supabase:
  ```sql
  SELECT policyname FROM pg_policies WHERE tablename = 'mensajes';
  ```
- Deberías ver 4 políticas

## 📸 CAPTURAS ESPERADAS

### Lista de Chats:
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

### Conversación:
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

**¡Listo para probar!** 🚀

Sigue los pasos en orden y marca cada checklist cuando funcione.
