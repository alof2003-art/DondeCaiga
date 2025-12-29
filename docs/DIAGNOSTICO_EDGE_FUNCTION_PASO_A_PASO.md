# 🔍 DIAGNÓSTICO EDGE FUNCTION PASO A PASO

**Problema:** Firebase funciona directamente, pero no desde Supabase  
**Objetivo:** Encontrar exactamente dónde está fallando el sistema

---

## 🎯 **SITUACIÓN ACTUAL**

✅ **Firebase funciona:** Campaña manual envía push notifications  
✅ **Token correcto:** Tu dispositivo recibe notificaciones de Firebase  
❌ **Supabase → Firebase:** No funciona la cadena automática  

**Posibles causas:**
1. Trigger no se ejecuta
2. Edge Function no se llama
3. Edge Function falla internamente
4. Configuración incorrecta

---

## 🚀 **PASO 1: ACTUALIZAR EDGE FUNCTION CON LOGS**

### **1.1 Ir a Supabase Dashboard**
```
1. https://supabase.com/dashboard
2. Tu proyecto → Edge Functions
3. send-push-notification (o crear si no existe)
```

### **1.2 Reemplazar código con versión con logs**
Usar el código de: `docs/supabase_edge_function_CON_LOGS_DETALLADOS.js`

### **1.3 Deploy la función**
```
1. Pegar el código nuevo
2. Save and Deploy
3. Verificar que no hay errores de sintaxis
```

---

## 🔍 **PASO 2: EJECUTAR DIAGNÓSTICO SQL**

### **2.1 Abrir SQL Editor en Supabase**

### **2.2 Ejecutar script de diagnóstico**
Usar: `docs/DIAGNOSTICAR_TRIGGER_Y_EDGE_FUNCTION.sql`

**IMPORTANTE:** Cambiar `'tu_email@gmail.com'` por tu email real

### **2.3 Verificar resultados**
```sql
-- Debe mostrar:
-- ✅ Trigger existe y está activo
-- ✅ Función del trigger existe
-- ✅ Edge Function está deployada
-- ✅ Notificación de prueba se creó
-- ✅ FCM Token existe para tu usuario
```

---

## 📊 **PASO 3: REVISAR LOGS EN TIEMPO REAL**

### **3.1 Abrir logs de Edge Function**
```
1. Supabase Dashboard → Edge Functions
2. send-push-notification → Logs tab
3. Mantener abierto en tiempo real
```

### **3.2 Ejecutar notificación de prueba**
```sql
-- En SQL Editor, ejecutar:
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    created_at
) 
SELECT 
    au.id,
    '🔍 Test en Vivo',
    'Probando logs en tiempo real - ' || NOW(),
    'live_test',
    NOW()
FROM auth.users au 
WHERE au.email = 'tu_email@gmail.com';  -- 👈 TU EMAIL
```

### **3.3 Observar qué pasa**

**Escenario A: NO aparecen logs**
- ❌ El trigger no se está ejecutando
- **Solución:** Revisar y recrear trigger

**Escenario B: Aparecen logs con 🚀🚀🚀**
- ✅ Trigger funciona, Edge Function se ejecuta
- **Revisar:** Logs detallados para ver dónde falla

**Escenario C: Error en logs**
- ✅ Sistema funciona hasta cierto punto
- **Revisar:** Error específico en los logs

---

## 🛠️ **PASO 4: SOLUCIONES SEGÚN DIAGNÓSTICO**

### **Si NO hay logs (Trigger no funciona):**
```sql
-- Recrear trigger
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications;
DROP FUNCTION IF EXISTS send_push_notification_on_insert();

-- Crear función nueva
CREATE OR REPLACE FUNCTION send_push_notification_on_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Llamar a la Edge Function
    PERFORM
        net.http_post(
            url := 'https://TU_PROJECT_ID.supabase.co/functions/v1/send-push-notification',
            headers := '{"Content-Type": "application/json", "Authorization": "Bearer TU_ANON_KEY"}'::jsonb,
            body := json_build_object(
                'user_id', NEW.user_id,
                'title', NEW.title,
                'message', NEW.message
            )::jsonb
        );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_on_insert();
```

### **Si hay logs pero falla la Edge Function:**
- Revisar logs detallados
- Verificar FIREBASE_SERVICE_ACCOUNT
- Verificar URL del proyecto
- Verificar formato de datos

### **Si Edge Function funciona pero no llega push:**
- Verificar FCM Token
- Verificar configuración Firebase
- Verificar permisos Android

---

## 📋 **CHECKLIST DE VERIFICACIÓN**

### **Base de datos:**
- [ ] Trigger existe y está activo
- [ ] Función del trigger existe
- [ ] Notificaciones se insertan correctamente
- [ ] FCM Tokens existen para usuarios

### **Edge Function:**
- [ ] Función deployada en Supabase
- [ ] FIREBASE_SERVICE_ACCOUNT configurado
- [ ] URL correcta en trigger
- [ ] Logs aparecen al insertar notificación

### **Firebase:**
- [ ] Proyecto configurado correctamente
- [ ] Service Account JSON válido
- [ ] FCM v1 API habilitada
- [ ] Token FCM válido y actual

### **Android:**
- [ ] App instalada con permisos
- [ ] Firebase inicializado
- [ ] Canal de notificaciones configurado
- [ ] Dispositivo conectado a internet

---

## 🎯 **RESULTADO ESPERADO**

Después de este diagnóstico sabremos exactamente:

1. **¿Se ejecuta el trigger?** (Logs aparecen o no)
2. **¿Llega a la Edge Function?** (Logs con 🚀🚀🚀)
3. **¿Dónde falla exactamente?** (Error específico en logs)
4. **¿Qué hay que arreglar?** (Solución específica)

**¡Ejecuta estos pasos y me cuentas qué ves en los logs!** 🔍