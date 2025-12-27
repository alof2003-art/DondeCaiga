# 🚀 GUÍA: TU EDGE FUNCTION CON GOOGLE AUTH

## ✅ TU CÓDIGO ES PERFECTO

Tu implementación es excelente porque:
- ✅ Usa `google-auth-library` (más limpio que JWT manual)
- ✅ Maneja automáticamente la autenticación OAuth 2.0
- ✅ Código más corto y mantenible
- ✅ Usa una sola variable de entorno con todo el JSON

## 📋 CONFIGURACIÓN PASO A PASO

### PASO 1: OBTENER EL JSON DE FIREBASE

1. **Firebase Console** → Tu proyecto → Configuración → Cuentas de servicio
2. **"Generar nueva clave privada"** → Descargar JSON
3. **Copiar todo el contenido del archivo JSON**

### PASO 2: CONFIGURAR VARIABLE EN SUPABASE

1. **Supabase Dashboard** → Edge Functions → Variables de entorno
2. **Crear variable:**
   - **Nombre:** `FIREBASE_SERVICE_ACCOUNT`
   - **Valor:** Todo el JSON (ejemplo abajo)

```json
{
  "type": "service_account",
  "project_id": "donde-caiga-notifications",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@donde-caiga-notifications.iam.gserviceaccount.com",
  "client_id": "123456789...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40donde-caiga-notifications.iam.gserviceaccount.com"
}
```

### PASO 3: CREAR EDGE FUNCTION EN SUPABASE

1. **Supabase Dashboard** → Edge Functions
2. **Nueva función:** `send-push-notification`
3. **Copiar tu código exacto:**

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { JWT } from "https://esm.sh/google-auth-library@9.0.0"

serve(async (req) => {
  try {
    // Solo permitir POST
    if (req.method !== 'POST') return new Response('Method not allowed', { status: 405 })
    
    const { fcm_token, title, body } = await req.json()
    
    // 1. Obtener el JSON desde el Secret
    const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '{}')
    
    // 2. Generar el Token de acceso automático de Google
    const jwtClient = new JWT(
      serviceAccount.client_email,
      null,
      serviceAccount.private_key,
      ['https://www.googleapis.com/auth/cloud-platform']
    )
    
    const credentials = await jwtClient.authorize()
    
    // 3. Enviar a Firebase V1 (La URL moderna)
    const firebaseResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/donde-caiga-notifications/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${credentials.access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token: fcm_token,
            notification: { title, body },
            android: {
              notification: {
                channel_id: 'donde_caiga_notifications',
                priority: 'high'
              }
            }
          }
        })
      }
    )
    
    const result = await firebaseResponse.json()
    return new Response(JSON.stringify(result), { 
      status: 200, 
      headers: { 'Content-Type': 'application/json' } 
    })
    
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), { 
      status: 500, 
      headers: { 'Content-Type': 'application/json' } 
    })
  }
})
```

### PASO 4: ACTUALIZAR SQL

1. **Editar el archivo:** `docs/ACTIVAR_PUSH_CON_TU_EDGE_FUNCTION.sql`
2. **Cambiar la URL** en línea 42:
   ```sql
   url := 'https://TU-PROYECTO-REAL.supabase.co/functions/v1/send-push-notification',
   ```
3. **Ejecutar todo el SQL** en Supabase SQL Editor

### PASO 5: CONFIGURAR ANON KEY

En Supabase Dashboard → Configuración → API:
1. Copiar tu **anon key**
2. Agregar como variable de entorno: `SUPABASE_ANON_KEY`

## 🧪 PROBAR EL SISTEMA

### PRUEBA 1: Ejecutar SQL
```sql
-- El SQL ya incluye una notificación de prueba automática
-- Solo ejecuta: docs/ACTIVAR_PUSH_CON_TU_EDGE_FUNCTION.sql
```

### PRUEBA 2: Prueba Manual
```sql
SELECT test_push_notification('0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid);
```

### PRUEBA 3: Desde Edge Function directamente
```bash
curl -X POST 'https://tu-proyecto.supabase.co/functions/v1/send-push-notification' \
-H 'Authorization: Bearer tu-anon-key' \
-H 'Content-Type: application/json' \
-d '{
  "fcm_token": "tu-fcm-token",
  "title": "Prueba Directa 🚀",
  "body": "Edge Function funcionando"
}'
```

## ✅ RESULTADO FINAL

Una vez configurado:
- ✅ **Notificaciones automáticas** cuando se crea cualquier notificación
- ✅ **App cerrada** → Push notification llega al celular
- ✅ **App en background** → Push + badge actualizado
- ✅ **App abierta** → Notificación in-app + badge
- ✅ **Escalable** para miles de usuarios
- ✅ **API moderna** de Firebase FCM v1

## 🎯 VENTAJAS DE TU IMPLEMENTACIÓN

1. **Más simple** - Una sola variable de entorno
2. **Más seguro** - Google maneja la autenticación
3. **Más mantenible** - Menos código personalizado
4. **Más confiable** - Librería oficial de Google
5. **Mejor debugging** - Errores más claros

¡Tu código es la forma más profesional de implementar FCM v1! 🎉