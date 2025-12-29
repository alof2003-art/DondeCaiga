# 🚀 INSTRUCCIONES PARA PROBAR NOTIFICACIONES PUSH - FINAL

## ✅ ESTADO ACTUAL
- **Base de datos**: ✅ Configurada correctamente
- **Edge Function**: ✅ Desplegada y funcionando
- **Código Flutter**: ✅ Actualizado con procesador de cola
- **Notificaciones pendientes**: ✅ Hay 1 notificación esperando ser procesada

## 📱 PASOS PARA PROBAR

### 1. COMPILAR LA APP
```bash
flutter build apk --release
```

### 2. INSTALAR EN TU CELULAR
- Instala la APK generada en `build/app/outputs/flutter-apk/app-release.apk`
- Asegúrate de permitir instalación de fuentes desconocidas

### 3. ABRIR LA APP Y LOGUEARSE
- Abre la app
- Loguéate con tu cuenta: `alof2003@gmail.com`
- **IMPORTANTE**: Mantén la app abierta por al menos 30 segundos

### 4. VERIFICAR FUNCIONAMIENTO
El procesador de cola se ejecuta automáticamente cada 10 segundos. Deberías ver:
- Logs en la consola de Flutter (si tienes debug conectado)
- La notificación push llegando a tu celular
- El status de la notificación cambiando de 'pending' a 'sent'

## 🔍 QUERIES PARA MONITOREAR

### Ver notificaciones pendientes:
```sql
SELECT * FROM get_pending_push_notifications();
```

### Ver todas las notificaciones en cola:
```sql
SELECT 
    id,
    title,
    status,
    attempts,
    created_at,
    sent_at,
    error_message
FROM push_notification_queue 
ORDER BY created_at DESC 
LIMIT 10;
```

### Crear una nueva notificación de prueba:
```sql
SELECT send_push_notification_flutter(
    (SELECT id FROM users_profiles WHERE email = 'alof2003@gmail.com'),
    'PRUEBA MANUAL 🧪',
    'Esta es una notificación de prueba manual'
);
```

## 🧪 PROBAR EL CHAT (FLUJO COMPLETO)

### 1. Enviar mensaje desde otra cuenta
- Loguéate con otra cuenta (ej: myrian)
- Envía un mensaje a Gabriel (alof2003@gmail.com)

### 2. Verificar que se crea la notificación automáticamente
```sql
-- Ver si se creó notificación automática
SELECT 
    n.title,
    n.message,
    n.created_at,
    up.email as destinatario
FROM notifications n
JOIN users_profiles up ON n.user_id = up.id
WHERE up.email = 'alof2003@gmail.com'
ORDER BY n.created_at DESC
LIMIT 5;
```

### 3. Verificar que se agregó a la cola push
```sql
-- Ver si se agregó a cola push automáticamente
SELECT 
    title,
    body,
    status,
    created_at
FROM push_notification_queue
WHERE user_id = (SELECT id FROM users_profiles WHERE email = 'alof2003@gmail.com')
ORDER BY created_at DESC
LIMIT 5;
```

## 🔧 TROUBLESHOOTING

### Si no llegan las notificaciones:

1. **Verificar permisos Android**:
   - Configuración > Apps > Donde Caiga > Notificaciones > Permitir

2. **Verificar token FCM**:
```sql
SELECT 
    email,
    fcm_token IS NOT NULL as tiene_token,
    LEFT(fcm_token, 30) || '...' as token_preview
FROM users_profiles 
WHERE email = 'alof2003@gmail.com';
```

3. **Verificar logs de la app**:
   - Conecta el celular y ejecuta: `flutter logs`
   - Busca mensajes como: "🚀 Procesando X notificaciones pendientes"

4. **Probar Edge Function directamente**:
```bash
curl -X POST https://louehuwimvwsoqesjjau.supabase.co/functions/v1/send-push-notification \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvdWVodXdpbXZ3c29xZXNqamF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3OTQ4MTYsImV4cCI6MjA4MDM3MDgxNn0.vhqclBtgt-o_GTNFGsU-pKYK68coeemIjl_CTQl8Rz8" \
  -H "Content-Type: application/json" \
  -d '{
    "fcm_token": "TU_TOKEN_FCM_AQUI",
    "title": "Prueba Directa",
    "body": "Esta es una prueba directa de la Edge Function"
  }'
```

## 📊 ESTADÍSTICAS DE LA COLA

### Ver estadísticas generales:
```sql
SELECT 
    status,
    COUNT(*) as cantidad,
    MIN(created_at) as primera,
    MAX(created_at) as ultima
FROM push_notification_queue
GROUP BY status
ORDER BY cantidad DESC;
```

## ✅ SEÑALES DE QUE FUNCIONA CORRECTAMENTE

1. **En la base de datos**:
   - Notificaciones cambian de status 'pending' a 'sent'
   - Campo `sent_at` se llena con timestamp
   - Campo `attempts` se incrementa

2. **En el celular**:
   - Llegan notificaciones push a la bandeja
   - Se pueden tocar y abren la app

3. **En los logs de Flutter**:
   - "🚀 Procesando X notificaciones pendientes"
   - "✅ Notificación enviada: TITULO"
   - "✅ Edge Function response: true"

## 🎯 PRÓXIMOS PASOS SI FUNCIONA

1. **Probar flujo completo de chat**
2. **Probar notificaciones de reservas**
3. **Configurar notificaciones para otros usuarios**
4. **Optimizar frecuencia del procesador** (cambiar de 10s a 30s o 1min)

---

**NOTA**: El sistema está completamente configurado. Solo falta compilar, instalar y probar en el celular.