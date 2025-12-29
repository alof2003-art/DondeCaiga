# 🔧 SISTEMA DE DEBUG FCM TOKENS MEJORADO

## 📋 **RESUMEN DE MEJORAS**

### **✅ NUEVO SISTEMA IMPLEMENTADO:**
1. **Tabla de logs detallados** (`debug_fcm_logs`) - Registra cada acción
2. **Funciones SQL con logs** - Todas las operaciones se registran automáticamente
3. **Debug mejorado en Flutter** - Información completa en tiempo real
4. **Monitoreo estadístico** - Métricas del sistema completo
5. **Verificación automática** - Confirma que tokens se guardan correctamente

## 🚀 **CÓMO USAR EL SISTEMA**

### **PASO 1: EJECUTAR SCRIPT SQL**
```sql
-- En Supabase SQL Editor, ejecutar:
docs/DEBUG_TOKEN_FCM_ULTRA_DETALLADO.sql
```

### **PASO 2: VERIFICAR INSTALACIÓN**
```sql
-- Ejecutar para verificar que todo está instalado:
docs/PROBAR_SISTEMA_LOGS_DETALLADOS.sql
```

### **PASO 3: COMPILAR Y PROBAR APP**
```bash
flutter run --release
```

### **PASO 4: USAR DEBUG EN LA APP**
1. Ir a **Perfil** → Botón **"🔧 Debug FCM Token"**
2. Revisar logs en consola de Flutter
3. Ejecutar comandos SQL para ver logs en base de datos

## 📊 **COMANDOS SQL PARA MONITOREO**

### **VER LOGS DE UN USUARIO:**
```sql
SELECT * FROM ver_logs_fcm_debug('mpattydaquilema@gmail.com');
```

### **VER ESTADÍSTICAS GENERALES:**
```sql
SELECT * FROM estadisticas_tokens_fcm();
```

### **MONITOREO EN TIEMPO REAL:**
```sql
SELECT * FROM monitoreo_tiempo_real_tokens();
```

### **VER SOLO ERRORES:**
```sql
SELECT * FROM debug_fcm_logs 
WHERE success = false 
ORDER BY created_at DESC;
```

### **VER LOGS RECIENTES (ÚLTIMA HORA):**
```sql
SELECT * FROM debug_fcm_logs 
WHERE created_at > NOW() - INTERVAL '1 hour' 
ORDER BY created_at DESC;
```

## 🔍 **QUÉ BUSCAR EN LOS LOGS**

### **✅ LOGS EXITOSOS:**
- `token_received` - Token llegó desde Flutter
- `token_saved` - Token guardado en base de datos
- `token_cleared` - Token limpiado en logout

### **❌ LOGS DE ERROR:**
- `token_error` - Problemas en el proceso
- Mensajes como "Usuario no encontrado"
- "No se actualizó ninguna fila - posible problema RLS"

### **🔧 LOGS DE DEBUG EN FLUTTER:**
```
🔄 === INICIANDO ACTUALIZACIÓN DE TOKEN FCM ===
👤 Usuario autenticado: 58e28dd4-b952-4176-9753-21edd24bccae
📧 Email usuario: mpattydaquilema@gmail.com
🔑 Token obtenido: SÍ
📏 Longitud del token: 142 caracteres
🔄 Usando función con logs detallados...
📊 Resultado función con logs: ✅ Token actualizado para mpattydaquilema@gmail.com
🎉 TOKEN GUARDADO EXITOSAMENTE CON LOGS
🔍 Verificando que el token se guardó...
✅ VERIFICACIÓN EXITOSA: Token confirmado en base de datos
```

## 🚨 **DIAGNÓSTICO DE PROBLEMAS**

### **PROBLEMA: No se ven logs en la base de datos**
**Causa:** Flutter no está llamando las funciones correctamente
**Solución:** 
1. Verificar que las funciones SQL existen
2. Revisar logs de Flutter para errores de RPC
3. Verificar permisos de usuario en Supabase

### **PROBLEMA: Logs muestran errores "Usuario no encontrado"**
**Causa:** Problema de autenticación o user_id incorrecto
**Solución:**
1. Verificar que el usuario está autenticado
2. Comprobar que el user_id es correcto
3. Revisar políticas RLS

### **PROBLEMA: Logs muestran "No se actualizó ninguna fila"**
**Causa:** Problema de permisos RLS
**Solución:**
1. Verificar políticas RLS en `users_profiles`
2. Comprobar que el usuario puede actualizar su propio perfil
3. Revisar si hay restricciones de seguridad

### **PROBLEMA: Token se guarda pero notificaciones no llegan**
**Causa:** Problema en el sistema de envío de notificaciones
**Solución:**
1. Verificar configuración de Firebase
2. Revisar función `send_push_notification_on_insert()`
3. Comprobar que las notificaciones se filtran por user_id

## 📈 **MÉTRICAS A MONITOREAR**

### **ESTADÍSTICAS IMPORTANTES:**
- **Total usuarios:** Cuántos usuarios hay en el sistema
- **Usuarios con token:** Cuántos tienen token FCM activo
- **Tokens duplicados:** Cuántos tokens están duplicados (debería ser 0)
- **Último token actualizado:** Cuándo fue la última actividad

### **LOGS POR USUARIO:**
- **Frecuencia de `token_received`:** ¿Llegan tokens desde Flutter?
- **Ratio `token_saved`/`token_received`:** ¿Se guardan correctamente?
- **Errores recurrentes:** ¿Hay patrones de error?

## 🎯 **PRÓXIMOS PASOS DESPUÉS DEL DEBUG**

### **SI TODO FUNCIONA CORRECTAMENTE:**
1. Implementar sistema multi-dispositivo
2. Verificar seguridad de notificaciones
3. Optimizar rendimiento

### **SI HAY PROBLEMAS:**
1. Identificar la causa exacta con los logs
2. Corregir el problema específico
3. Volver a probar con el sistema de debug

## 📝 **COMANDOS RÁPIDOS DE REFERENCIA**

```sql
-- Ver estado actual de tu usuario
SELECT * FROM ver_logs_fcm_debug('tu_email@gmail.com', 5);

-- Ver si hay problemas
SELECT * FROM debug_fcm_logs WHERE success = false AND created_at > NOW() - INTERVAL '1 day';

-- Estadísticas rápidas
SELECT * FROM estadisticas_tokens_fcm();

-- Limpiar logs antiguos (opcional)
DELETE FROM debug_fcm_logs WHERE created_at < NOW() - INTERVAL '7 days';
```

## 🔧 **NOTAS TÉCNICAS**

- **Tabla `debug_fcm_logs`:** Almacena todos los eventos relacionados con tokens
- **Función `log_fcm_debug()`:** Registra eventos automáticamente
- **Funciones con logs:** Todas las operaciones importantes registran su actividad
- **Verificación automática:** El sistema confirma que los tokens se guardan correctamente

**El sistema ahora te dará visibilidad completa de qué está pasando con los tokens FCM. ¡No más adivinanzas!** 🎉