# 🔍 INSTRUCCIONES PARA DEBUG DEL TOKEN FCM

## 📋 PASOS PARA DIAGNOSTICAR POR QUÉ NO SE ENVÍA EL TOKEN

### **PASO 1: Ejecutar SQL de Debug**
```sql
-- Ejecutar en Supabase SQL Editor:
-- docs/DEBUG_TOKEN_FCM_LOGS.sql
```

### **PASO 2: Compilar App con Logs Detallados**
```bash
flutter run --release
```

### **PASO 3: Revisar Logs de Flutter**
Busca en la consola estos logs:
- `🔄 === INICIANDO ACTUALIZACIÓN DE TOKEN FCM ===`
- `👤 Usuario autenticado: [ID]`
- `🔑 Token obtenido: SÍ/NO`
- `🔑 Token FCM: [preview]`
- `✅ UPDATE ejecutado`
- `📊 Resultado UPDATE: [resultado]`
- `🎉 TOKEN FCM GUARDADO EXITOSAMENTE`

### **PASO 4: Usar Métodos de Debug en Flutter**
Agrega esto en tu código donde inicializas las notificaciones:

```dart
// Para obtener información de debug
final debugInfo = await NotificationsService().getTokenDebugInfo();
print('DEBUG INFO: $debugInfo');

// Para forzar actualización
await NotificationsService().forceUpdateToken();
```

### **PASO 5: Verificar en Supabase**
Ejecuta en SQL Editor:
```sql
-- Ver estado actual del token
SELECT * FROM debug_token_changes();

-- Simular actualización
SELECT simular_flutter_token_update();

-- Verificar permisos RLS
SELECT * FROM verificar_permisos_rls();
```

## 🚨 PROBLEMAS COMUNES Y SOLUCIONES

### **Problema 1: "Usuario no autenticado"**
- **Causa:** Usuario no está logueado
- **Solución:** Verificar que el login funcione correctamente

### **Problema 2: "Token obtenido: NO"**
- **Causa:** Firebase no puede generar token
- **Solución:** 
  - Verificar configuración de Firebase
  - Verificar permisos de notificaciones
  - Verificar google-services.json

### **Problema 3: "UPDATE no afectó ninguna fila"**
- **Causa:** RLS (Row Level Security) bloqueando la actualización
- **Solución:** Verificar políticas RLS en users_profiles

### **Problema 4: "Error en UPDATE directo"**
- **Causa:** Problema de conexión o permisos
- **Solución:** Verificar conexión a Supabase y políticas

## 📊 INTERPRETACIÓN DE LOGS

### **✅ LOGS EXITOSOS:**
```
🔄 === INICIANDO ACTUALIZACIÓN DE TOKEN FCM ===
👤 Usuario autenticado: 0dc7b2bc-04c7-430e-8725-19f6cdb55ee3
📧 Email usuario: alof2003@gmail.com
🔑 Token obtenido: SÍ
🔑 Token FCM: fGHJ123...890XYZ
📏 Longitud del token: 163 caracteres
💾 Token guardado en memoria local
🔄 Intentando UPDATE directo en users_profiles...
✅ UPDATE ejecutado
📊 Resultado UPDATE: [{id: ..., fcm_token: ...}]
📈 Filas afectadas: 1
🎉 TOKEN FCM GUARDADO EXITOSAMENTE EN users_profiles
🏁 === FIN ACTUALIZACIÓN TOKEN FCM ===
```

### **❌ LOGS PROBLEMÁTICOS:**
```
🔄 === INICIANDO ACTUALIZACIÓN DE TOKEN FCM ===
👤 Usuario autenticado: NULL
❌ FALLO: Usuario no autenticado
```

O:

```
🔑 Token obtenido: NO
❌ FALLO: No se pudo obtener token FCM del dispositivo
```

O:

```
📈 Filas afectadas: 0
⚠️ UPDATE no afectó ninguna fila - posible problema de RLS
```

## 🔧 COMANDOS ÚTILES

### **Limpiar token para forzar regeneración:**
```sql
SELECT limpiar_token_usuario('alof2003@gmail.com');
```

### **Ver todos los tokens actuales:**
```sql
SELECT * FROM ver_tokens_usuarios();
```

### **Monitorear cambios en tiempo real:**
```sql
SELECT NOW() as momento, * FROM debug_token_changes();
```

## 📱 TESTING EN DISPOSITIVO

1. **Instalar app** → `flutter install`
2. **Abrir app** → Iniciar sesión
3. **Revisar logs** → En consola de Flutter
4. **Verificar BD** → Ejecutar queries de debug
5. **Probar notificación** → Usar queries de prueba

**Con estos logs detallados podrás ver exactamente dónde está fallando el proceso.**