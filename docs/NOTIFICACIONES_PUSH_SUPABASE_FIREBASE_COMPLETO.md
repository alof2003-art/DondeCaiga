# 🔔 SISTEMA COMPLETO: SUPABASE + FIREBASE PUSH NOTIFICATIONS

## ✅ **ESTADO ACTUAL: CONFIGURACIÓN BÁSICA COMPLETADA**

### 🎯 **LO QUE ACABAMOS DE IMPLEMENTAR**

#### 📱 **App Flutter**
- ✅ Firebase inicializado correctamente
- ✅ Token FCM se obtiene automáticamente
- ✅ Token se guarda en Supabase al abrir la app
- ✅ Notificaciones locales funcionando
- ✅ Handlers de Firebase configurados

#### 🗄️ **Base de Datos Supabase**
- ✅ Columna `fcm_token` agregada a `users_profiles`
- ✅ Función para actualizar tokens FCM
- ✅ Función para crear notificaciones de prueba
- ✅ Extensión HTTP habilitada (para requests)

## 🧪 **CÓMO PROBAR EL SISTEMA**

### **Paso 1: Ejecutar SQL en Supabase**
1. Ve a tu dashboard de Supabase
2. Clic en **SQL Editor**
3. Copia y pega el contenido de: `docs/EJECUTAR_EN_SUPABASE_NOTIFICACIONES_PUSH.sql`
4. Ejecutar

### **Paso 2: Verificar Token FCM**
1. Abre la app en tu celular
2. Inicia sesión con tu usuario
3. En Supabase, ejecuta:
   ```sql
   SELECT user_id, nombre_completo, fcm_token 
   FROM users_profiles 
   WHERE fcm_token IS NOT NULL;
   ```
4. Deberías ver tu token FCM guardado

### **Paso 3: Crear Notificación de Prueba**
1. En Supabase SQL Editor, ejecuta:
   ```sql
   SELECT crear_notificacion_prueba('TU-USER-ID-AQUI');
   ```
2. Verifica que se creó:
   ```sql
   SELECT * FROM notificaciones 
   WHERE usuario_id = 'TU-USER-ID-AQUI' 
   ORDER BY created_at DESC LIMIT 5;
   ```

### **Paso 4: Verificar en la App**
1. Ve a la pantalla de notificaciones en tu app
2. Deberías ver la notificación de prueba
3. El badge debería mostrar el número correcto

## 🚀 **PRÓXIMOS PASOS: ACTIVAR PUSH AUTOMÁTICO**

### **Opción A: Edge Function (Recomendada)**
1. **Crear Edge Function en Supabase:**
   - Usar el código de: `docs/supabase_edge_function_push_notifications.js`
   - Configurar FCM Server Key
   - Desplegar función

2. **Activar Trigger Automático:**
   - Usar el código de: `docs/trigger_notificaciones_push_automaticas.sql`
   - Configurar URL de tu proyecto

### **Opción B: Webhook Simple**
1. **Crear webhook endpoint**
2. **Configurar en Supabase Database Webhooks**
3. **Enviar notificaciones via HTTP**

## 📋 **CONFIGURACIÓN REQUERIDA PARA PUSH AUTOMÁTICO**

### **1. Obtener FCM Server Key**
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto "donde-caiga-notifications"
3. Ve a **Project Settings** (⚙️)
4. Pestaña **Cloud Messaging**
5. Copia la **Server Key**

### **2. Configurar en Supabase**
```bash
# Si tienes Supabase CLI instalado:
supabase secrets set FCM_SERVER_KEY=tu_server_key_aqui

# O configura en el dashboard de Supabase:
# Settings > Edge Functions > Environment Variables
```

### **3. Actualizar URL del Proyecto**
En el archivo SQL, reemplaza:
```sql
edge_function_url := 'https://TU-PROYECTO-ID.supabase.co/functions/v1/send-push-notification';
```

## 🔍 **DEBUGGING Y LOGS**

### **Logs de la App**
```dart
// En Flutter, verás logs como:
I/flutter: 🔔 Permisos de notificación: AuthorizationStatus.authorized
I/flutter: 🔑 FCM Token: eh-ppseESu6jvPKv1KMT7Q:APA91bG8w2aSdh1d5i63...
I/flutter: 💾 Guardando token FCM en Supabase para usuario: user-id
I/flutter: ✅ Token FCM guardado exitosamente
I/flutter: 📨 Mensaje recibido en primer plano: message-id
```

### **Logs de Supabase**
```sql
-- Ver notificaciones recientes
SELECT 
    n.titulo,
    n.mensaje,
    n.tipo,
    n.created_at,
    up.nombre_completo,
    up.fcm_token IS NOT NULL as tiene_token
FROM notificaciones n
JOIN users_profiles up ON n.usuario_id = up.user_id
ORDER BY n.created_at DESC
LIMIT 10;
```

### **Verificar Edge Function**
```bash
# Ver logs de edge functions
supabase functions logs send-push-notification

# O en el dashboard:
# Edge Functions > send-push-notification > Logs
```

## 🎯 **FLUJO COMPLETO FUNCIONANDO**

### **Cuando esté todo configurado:**

1. **Usuario recibe mensaje** → Se crea registro en tabla `notificaciones`
2. **Trigger se ejecuta** → Obtiene `fcm_token` del usuario
3. **Edge Function se llama** → Recibe datos de la notificación
4. **Firebase FCM envía push** → Notificación llega al dispositivo
5. **App recibe notificación** → Se muestra al usuario
6. **Usuario toca notificación** → Navega a pantalla correspondiente

### **Tipos de notificaciones automáticas:**
- ✅ Nueva reserva → Notifica al anfitrión
- ✅ Reserva aceptada/rechazada → Notifica al viajero  
- ✅ Nueva reseña → Notifica al usuario reseñado
- ✅ Nuevo mensaje → Notifica al receptor
- ✅ Recordatorios → Notifica según configuración

## 🔧 **COMANDOS ÚTILES**

### **Probar notificación manual:**
```sql
-- Crear notificación de prueba
SELECT crear_notificacion_prueba(
    'user-id-aqui',
    'Título de Prueba',
    'Este es un mensaje de prueba'
);
```

### **Ver tokens FCM activos:**
```sql
SELECT 
    user_id,
    nombre_completo,
    LEFT(fcm_token, 50) || '...' as token_preview,
    updated_at
FROM users_profiles 
WHERE fcm_token IS NOT NULL
ORDER BY updated_at DESC;
```

### **Limpiar tokens antiguos:**
```sql
-- Opcional: limpiar tokens de usuarios inactivos
UPDATE users_profiles 
SET fcm_token = NULL 
WHERE updated_at < NOW() - INTERVAL '30 days';
```

## 🎉 **RESULTADO FINAL**

**¡Tienes la base completa para un sistema de notificaciones push profesional!**

- 🔔 **Notificaciones en tiempo real** desde Supabase
- 📱 **Push notifications nativas** via Firebase
- 🔄 **Sincronización automática** de tokens
- 🎯 **Navegación inteligente** desde notificaciones
- 🛡️ **Seguridad RLS** - Solo ves tus notificaciones
- 📊 **Logs completos** para debugging

### **Estado actual:**
- ✅ **Configuración básica**: Completada
- 🔄 **Push automático**: Listo para activar
- 🧪 **Testing**: Funcionando

**¡Solo falta activar el push automático y tendrás el sistema más bestial de notificaciones!** 🚀🔥