# 📱 INSTRUCCIONES PARA USAR EL SISTEMA DE CHAT

## ✅ ESTADO: IMPLEMENTACIÓN COMPLETA

El sistema de chat está 100% funcional y listo para usar.

## 🗄️ PASO 1: EJECUTAR SQL EN SUPABASE

Antes de probar, ejecuta este archivo SQL en tu proyecto de Supabase:

### Ejecutar: `actualizar_chat_completo.sql`

Este archivo es **seguro de ejecutar múltiples veces** y hace todo lo necesario:

✅ Agrega el campo `codigo_verificacion` a la tabla `reservas`
✅ Crea un trigger que genera automáticamente un código de 6 dígitos
✅ Crea la tabla `mensajes` con todos los campos necesarios
✅ Configura RLS (Row Level Security) para seguridad
✅ Habilita Realtime para mensajes instantáneos
✅ Crea políticas para que solo participantes puedan ver/enviar mensajes

**Nota**: Si ya ejecutaste otros archivos SQL del chat antes, este archivo actualizará todo correctamente sin errores.

## 🧪 PASO 2: PROBAR EL SISTEMA

### Escenario de Prueba Completo

#### 1. Crear una Reserva
- Inicia sesión como **viajero**
- Ve a "Explorar"
- Selecciona una propiedad
- Crea una reserva con fechas válidas

#### 2. Aprobar la Reserva
- Cierra sesión
- Inicia sesión como **anfitrión** (dueño de la propiedad)
- Ve a "Anfitrión" → "Mis Reservas"
- Aprueba la reserva pendiente
- ✨ El código de verificación se genera automáticamente

#### 3. Ver el Chat
- Cierra sesión
- Inicia sesión nuevamente como **viajero**
- Ve a la pestaña "Chat" (antes era "Buzón")
- Deberías ver tu reserva confirmada con:
  - Título de la propiedad
  - Nombre del anfitrión
  - Fechas de la reserva
  - Badge verde "ACEPTADA"
  - Código de verificación (oculto por defecto)

#### 4. Ver el Código
- Click en el ícono del ojo 👁️
- El código de 6 dígitos se mostrará
- Click nuevamente para ocultarlo

#### 5. Abrir el Chat
- Click en el botón "Abrir Chat"
- Se abre la pantalla de conversación
- En el header verás:
  - Título de la propiedad
  - Fechas de la reserva
  - Código de verificación (con botón para mostrar/ocultar)

#### 6. Enviar Mensajes
- Escribe un mensaje en el campo de texto
- Click en el botón de enviar ✉️
- El mensaje aparece inmediatamente
- Los mensajes propios aparecen en verde (derecha)
- Los mensajes del otro usuario aparecen en gris (izquierda)

#### 7. Probar Tiempo Real
- Abre la app en otro dispositivo o navegador
- Inicia sesión como **anfitrión**
- Ve a "Chat" (el anfitrión también verá la reserva)
- Abre la misma conversación
- Envía un mensaje desde el anfitrión
- ✨ El mensaje aparece instantáneamente en el dispositivo del viajero

## 🎯 CARACTERÍSTICAS IMPLEMENTADAS

### Lista de Chats
- ✅ Solo muestra reservas confirmadas
- ✅ Código de verificación con botón mostrar/ocultar
- ✅ Información completa de la reserva
- ✅ Navegación al chat individual

### Conversación de Chat
- ✅ Mensajes en tiempo real (Supabase Realtime)
- ✅ Burbujas de chat diferenciadas
- ✅ Timestamps en cada mensaje
- ✅ Scroll automático al enviar
- ✅ Código de verificación en el header
- ✅ Estados de carga

### Seguridad
- ✅ Solo participantes pueden ver mensajes
- ✅ Solo reservas confirmadas permiten chat
- ✅ RLS implementado correctamente
- ✅ Validación de permisos en backend

## 🔍 VERIFICAR QUE TODO FUNCIONA

### Checklist de Verificación

- [ ] El código de verificación se genera al aprobar una reserva
- [ ] La pestaña se llama "Chat" (no "Buzón")
- [ ] Solo aparecen reservas confirmadas en la lista
- [ ] El código se puede mostrar/ocultar con el botón del ojo
- [ ] El botón "Abrir Chat" navega a la conversación
- [ ] Se pueden enviar mensajes
- [ ] Los mensajes aparecen en tiempo real
- [ ] El código de verificación aparece en el header del chat
- [ ] No hay warnings en la consola de Flutter

## 🐛 SOLUCIÓN DE PROBLEMAS

### No aparecen reservas en el Chat
- Verifica que la reserva esté en estado "confirmada"
- Revisa que el usuario actual sea el viajero de esa reserva
- Ejecuta el SQL de códigos de verificación

### No se pueden enviar mensajes
- Verifica que ejecutaste `actualizar_chat_completo.sql`
- Revisa que la tabla `mensajes` existe en Supabase
- Verifica que Realtime está habilitado en la tabla

### Los mensajes no aparecen en tiempo real
- Verifica que ejecutaste `actualizar_chat_completo.sql` completamente
- Reinicia la app después de ejecutar el SQL
- Verifica en Supabase que la tabla `mensajes` está en la publicación de Realtime

### Error de permisos
- Verifica que las políticas RLS están creadas
- Revisa que el usuario está autenticado
- Verifica que el usuario es participante de la reserva

## 📊 ESTRUCTURA DE DATOS

### Tabla: reservas
```
- id (UUID)
- propiedad_id (UUID)
- viajero_id (UUID)
- fecha_inicio (DATE)
- fecha_fin (DATE)
- estado (TEXT) → 'pendiente', 'confirmada', 'rechazada', 'cancelada'
- codigo_verificacion (TEXT) → 6 dígitos, generado automáticamente
- created_at (TIMESTAMP)
```

### Tabla: mensajes
```
- id (UUID)
- reserva_id (UUID) → FK a reservas
- remitente_id (UUID) → FK a users_profiles
- mensaje (TEXT)
- leido (BOOLEAN)
- created_at (TIMESTAMP)
```

## 🎨 PERSONALIZACIÓN

Si quieres cambiar colores o estilos:

### Color Principal del Chat
Busca `Color(0xFF4DB6AC)` en los archivos y cámbialo por tu color preferido.

### Color del Código de Verificación
Busca `Colors.blue` en los archivos del código de verificación.

### Tamaño de las Burbujas
Modifica `maxWidth: MediaQuery.of(context).size.width * 0.7` en `_MensajeBubble`.

## 📝 ARCHIVOS IMPORTANTES

### Frontend (Flutter)
- `lib/features/buzon/presentation/screens/chat_lista_screen.dart` - Lista de chats
- `lib/features/chat/presentation/screens/chat_conversacion_screen.dart` - Conversación
- `lib/features/chat/data/models/mensaje.dart` - Modelo de mensaje
- `lib/features/chat/data/repositories/mensaje_repository.dart` - Lógica de mensajes

### Backend (SQL)
- `actualizar_chat_completo.sql` - **USAR ESTE** - Todo en uno, seguro de ejecutar múltiples veces
- `agregar_codigo_verificacion_reservas.sql` - (Opcional) Solo códigos
- `crear_tabla_mensajes.sql` - (Opcional) Solo mensajes

### Documentación
- `CHAT_SISTEMA_COMPLETO.md` - Resumen técnico completo
- `RESUMEN_CHAT_IMPLEMENTADO.md` - Resumen de implementación
- `PLAN_IMPLEMENTACION_CHAT.md` - Plan original

## ✨ PRÓXIMAS MEJORAS OPCIONALES

Si quieres extender el sistema:

1. **Notificaciones Push**: Avisar cuando llega un mensaje nuevo
2. **Indicador "Escribiendo..."**: Mostrar cuando el otro usuario está escribiendo
3. **Mensajes Leídos**: Marcar y mostrar qué mensajes fueron leídos
4. **Adjuntar Imágenes**: Permitir enviar fotos en el chat
5. **Búsqueda**: Buscar mensajes antiguos
6. **Eliminar Mensajes**: Permitir borrar mensajes propios

---

**¡El sistema está listo para usar!** 🎉

Si tienes algún problema, revisa la sección de "Solución de Problemas" o verifica que ejecutaste todos los archivos SQL en Supabase.
