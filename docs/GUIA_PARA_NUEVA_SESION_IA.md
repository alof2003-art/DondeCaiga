# GUÍA PARA NUEVA SESIÓN IA - PROYECTO DONDE CAIGA

**IMPORTANTE:** Lee esto completo antes de hacer cualquier cosa.

## ESTADO ACTUAL DEL PROYECTO

### SISTEMA DE NOTIFICACIONES PUSH
- ✅ **FUNCIONANDO AL 100%** - Push notifications llegan sin abrir la app
- ✅ **Trigger SQL activo** - Se ejecuta automáticamente al insertar notificaciones
- ✅ **Edge Function deployada** - Conecta Supabase con Firebase
- ✅ **Firebase configurado** - Proyecto: donde-caiga-notifications
- ✅ **Android permisos** - App instalada correctamente en TECNO LI7

### DATOS CRÍTICOS DEL PROYECTO
- **Supabase URL:** https://louehuwimvwsoqesjjau.supabase.co
- **Project ID:** louehuwimvwsoqesjjau
- **Firebase Project:** donde-caiga-notifications
- **Usuario de prueba:** alof2003@gmail.com
- **Dispositivo:** TECNO LI7 (Android 15)

### ESTRUCTURA DE BASE DE DATOS REAL
```
notifications: id, user_id, title, message, type, read_at, created_at, is_read, metadata
users_profiles: id, nombre, email, fcm_token, telefono, foto_perfil_url, etc.
device_tokens: id, user_id, token, platform, is_active, created_at, updated_at
push_notification_queue: id, user_id, fcm_token, title, body, status, sent_at
```

## ARCHIVOS CLAVE QUE FUNCIONAN

### SQL PRINCIPAL
- **`docs/SISTEMA_SIMPLE_SIN_DATA.sql`** - Sistema básico funcionando
- **`docs/TRIGGER_FINAL_CON_TUS_DATOS.sql`** - Trigger con datos reales

### EDGE FUNCTION
- **`docs/EDGE_FUNCTION_FINAL_OPTIMIZADA.js`** - Función optimizada
- **`docs/supabase_edge_function_CON_LOGS_DETALLADOS.js`** - Con logs para debug

### FLUTTER
- **`lib/features/notificaciones/services/push_notifications_service.dart`** - Servicio principal
- **`lib/features/notificaciones/presentation/screens/notificaciones_screen.dart`** - Pantalla
- **`android/app/src/main/AndroidManifest.xml`** - Permisos configurados

## REGLAS CRÍTICAS PARA LA IA

### ❌ NO HAGAS ESTO NUNCA
1. **NO crear archivos nuevos** si ya existen similares
2. **NO sumarizar** al final de las respuestas
3. **NO cambiar nombres de tablas** sin verificar la estructura real
4. **NO asumir estructura de BD** - siempre verificar primero
5. **NO crear documentación innecesaria** - solo código funcional

### ✅ SÍ HACER ESTO
1. **Usar archivos existentes** y mejorarlos
2. **Verificar estructura de BD** antes de crear SQL
3. **Probar cambios** antes de confirmar
4. **Mantener datos reales** (URLs, tokens, IDs)
5. **Ser directo** - sin explicaciones largas

## PROBLEMAS COMUNES Y SOLUCIONES

### Error: "column data does not exist"
- **Causa:** La tabla notifications NO tiene columna 'data', tiene 'metadata'
- **Solución:** Usar 'metadata' o no usar datos adicionales

### Error: "relation user_fcm_tokens does not exist"
- **Causa:** La tabla se llama 'users_profiles' con campo 'fcm_token'
- **Solución:** Usar users_profiles.fcm_token

### Error: "schema net does not exist"
- **Causa:** Falta extensión pg_net
- **Solución:** CREATE EXTENSION IF NOT EXISTS pg_net;

## COMANDOS ÚTILES

### Verificar sistema
```sql
SELECT * FROM notifications ORDER BY created_at DESC LIMIT 5;
SELECT fcm_token FROM users_profiles WHERE email = 'alof2003@gmail.com';
```

### Probar notificación
```sql
INSERT INTO notifications (user_id, title, message, type) 
SELECT id, 'Test', 'Mensaje de prueba', 'test' 
FROM auth.users WHERE email = 'alof2003@gmail.com';
```

### Flutter rebuild
```bash
flutter clean
flutter pub get
flutter install --release
```

## CONTEXTO DE SESIONES ANTERIORES

### Lo que se logró
- Sistema push notifications 100% funcional
- App instalada en dispositivo real
- Trigger automático funcionando
- Firebase integrado correctamente
- Edge Function deployada

### Lo que NO se debe tocar
- Configuración de Firebase (funciona)
- AndroidManifest.xml (permisos correctos)
- Estructura de BD existente
- URLs y tokens configurados

## INSTRUCCIONES FINALES

1. **Lee la estructura de BD real** antes de crear SQL
2. **Usa archivos existentes** en lugar de crear nuevos
3. **Mantén los datos reales** (URLs, tokens, IDs)
4. **Prueba cambios** antes de confirmar
5. **Sé directo** - sin resúmenes largos

**El sistema funciona. Solo mejóralo, no lo rompas.**