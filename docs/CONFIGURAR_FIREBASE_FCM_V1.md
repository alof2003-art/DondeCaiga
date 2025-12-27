# 🚀 CONFIGURAR FIREBASE CLOUD MESSAGING API V1

## ⚠️ IMPORTANTE: 
Firebase deprecó la API antigua. Ahora usamos **Firebase Cloud Messaging API v1** que es más segura y moderna.

## 📋 PASOS PARA CONFIGURAR:

### PASO 1: GENERAR CLAVE DE CUENTA DE SERVICIO

1. **Ve a Firebase Console** → Tu proyecto
2. **Configuración del proyecto** (ícono de engranaje)
3. **Pestaña "Cuentas de servicio"**
4. **"Generar nueva clave privada"**
5. **Descargar archivo JSON**

### PASO 2: EXTRAER DATOS DEL ARCHIVO JSON

Del archivo JSON descargado, necesitas estos 3 valores:

```json
{
  "project_id": "tu-proyecto-12345",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@tu-proyecto.iam.gserviceaccount.com"
}
```

### PASO 3: CONFIGURAR VARIABLES EN SUPABASE

1. **Ve a Supabase Dashboard** → Edge Functions → Variables de entorno
2. **Agrega estas 3 variables:**

```
FIREBASE_PROJECT_ID = tu-proyecto-12345
FIREBASE_PRIVATE_KEY = -----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC...
-----END PRIVATE KEY-----
FIREBASE_CLIENT_EMAIL = firebase-adminsdk-xxxxx@tu-proyecto.iam.gserviceaccount.com
```

⚠️ **IMPORTANTE:** La clave privada debe incluir los saltos de línea `\n`

### PASO 4: CREAR EDGE FUNCTION EN SUPABASE

1. **Supabase Dashboard** → Edge Functions
2. **Nueva función:** `send-push-notification`
3. **Copiar código de:** `docs/supabase_edge_function_fcm_v1.js`
4. **Desplegar función**

### PASO 5: ACTUALIZAR SQL PARA USAR NUEVA API

```sql
-- Ejecuta en Supabase SQL Editor:
docs/ACTIVAR_NOTIFICACIONES_PUSH_AUTOMATICAS.sql
```

## 🔄 DIFERENCIAS CON LA API ANTIGUA:

### ❌ API ANTIGUA (DEPRECADA):
- Usaba Server Key
- URL: `https://fcm.googleapis.com/fcm/send`
- Autenticación: `Authorization: key=SERVER_KEY`

### ✅ API NUEVA (FCM V1):
- Usa OAuth 2.0 con JWT
- URL: `https://fcm.googleapis.com/v1/projects/PROJECT_ID/messages:send`
- Autenticación: `Authorization: Bearer ACCESS_TOKEN`

## 🧪 PROBAR LA CONFIGURACIÓN:

### PRUEBA 1: Desde Supabase Edge Function
```bash
curl -X POST 'https://tu-proyecto.supabase.co/functions/v1/send-push-notification' \
-H 'Authorization: Bearer tu-anon-key' \
-H 'Content-Type: application/json' \
-d '{
  "fcm_token": "tu-fcm-token-aqui",
  "title": "Prueba FCM v1 🚀",
  "body": "Nueva API funcionando correctamente"
}'
```

### PRUEBA 2: Crear notificación en Supabase
```sql
INSERT INTO notifications (
    user_id, title, message, type, is_read
) VALUES (
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'Prueba API v1 🚀',
    'Notificación con Firebase Cloud Messaging v1',
    'general',
    FALSE
);
```

## ✅ VENTAJAS DE LA NUEVA API:

1. **Más segura** - OAuth 2.0 en lugar de claves estáticas
2. **Mejor rendimiento** - Optimizada para alto volumen
3. **Más funciones** - Soporte para nuevas características
4. **Futuro-proof** - No se deprecará pronto
5. **Mejor debugging** - Errores más descriptivos

## 🎯 RESULTADO FINAL:

Una vez configurado correctamente:
- ✅ Notificaciones push automáticas
- ✅ Funciona con app cerrada/background/abierta
- ✅ Compatible con Android e iOS
- ✅ Escalable para miles de usuarios
- ✅ Usa la API más moderna de Firebase

¡Tu app tendrá notificaciones push de nivel profesional! 🎉