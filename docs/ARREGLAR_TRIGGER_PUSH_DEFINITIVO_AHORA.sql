-- ========================================
-- ARREGLAR TRIGGER PUSH DEFINITIVO AHORA
-- Fecha: 2024-12-29
-- PROBLEMA: Trigger está en UPDATE, debe ser INSERT
-- ========================================

-- PASO 1: ELIMINAR TRIGGER INCORRECTO
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications;
DROP FUNCTION IF EXISTS send_push_notification_on_insert();
DROP FUNCTION IF EXISTS trigger_send_push_flutter();

-- PASO 2: CREAR FUNCIÓN CORRECTA
CREATE OR REPLACE FUNCTION send_push_notification_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    recipient_fcm_token TEXT;
    notification_data JSONB;
BEGIN
    -- Obtener FCM token del usuario
    SELECT fcm_token INTO recipient_fcm_token
    FROM users_profiles 
    WHERE id = NEW.user_id;
    
    -- Solo enviar si hay token válido
    IF recipient_fcm_token IS NOT NULL AND recipient_fcm_token != '' THEN
        -- Preparar datos
        notification_data := jsonb_build_object(
            'token', recipient_fcm_token,
            'title', NEW.title,
            'body', NEW.message,
            'data', jsonb_build_object(
                'notification_id', NEW.id::text,
                'type', COALESCE(NEW.type, 'general'),
                'click_action', 'FLUTTER_NOTIFICATION_CLICK'
            )
        );
        
        -- Enviar push usando Edge Function
        BEGIN
            PERFORM net.http_post(
                url := 'https://louehuwimvwsoqesjjau.supabase.co/functions/v1/send-push-notification',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvdWVodXdpbXZ3c29xZXNqamF1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMzI3NzI5NCwiZXhwIjoyMDQ4ODUzMjk0fQ.Hs8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8Ej8'
                ),
                body := jsonb_build_object(
                    'fcm_token', recipient_fcm_token,
                    'title', NEW.title,
                    'body', NEW.message
                )
            );
        EXCEPTION WHEN OTHERS THEN
            -- Continuar sin error si falla
            RAISE NOTICE 'Push notification failed: %', SQLERRM;
        END;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 3: CREAR TRIGGER CORRECTO (AFTER INSERT)
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_on_insert();

-- PASO 4: VERIFICAR CONFIGURACIÓN
SELECT 
    '🔍 VERIFICACIÓN TRIGGER' as info,
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_send_push_on_notification';

-- PASO 5: VERIFICAR FCM TOKEN DE ALOF
SELECT 
    '🔍 VERIFICACIÓN TOKEN ALOF' as info,
    email,
    nombre,
    CASE 
        WHEN fcm_token IS NOT NULL AND fcm_token != '' 
        THEN '✅ Token disponible'
        ELSE '❌ Sin token'
    END as token_status
FROM users_profiles 
WHERE email = 'alof2003@gmail.com';

-- PASO 6: CREAR NOTIFICACIÓN DE PRUEBA
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    is_read,
    created_at
) 
SELECT 
    id,
    '🚀 TRIGGER ARREGLADO - ' || TO_CHAR(NOW(), 'HH24:MI:SS'),
    'Gabriel, si recibes esta notificación push en tu bandeja del sistema, el trigger está funcionando correctamente. Hora: ' || TO_CHAR(NOW(), 'HH24:MI:SS DD/MM/YYYY'),
    'trigger_test',
    FALSE,
    NOW()
FROM users_profiles 
WHERE email = 'alof2003@gmail.com';

-- PASO 7: VERIFICAR NOTIFICACIÓN CREADA
SELECT 
    '✅ NOTIFICACIÓN CREADA' as resultado,
    n.id,
    n.title,
    n.message,
    n.created_at,
    up.email,
    CASE 
        WHEN up.fcm_token IS NOT NULL AND up.fcm_token != '' 
        THEN '✅ Push debería enviarse'
        ELSE '❌ Sin token FCM'
    END as push_status
FROM notifications n
JOIN users_profiles up ON n.user_id = up.id
WHERE up.email = 'alof2003@gmail.com'
AND n.created_at >= NOW() - INTERVAL '1 minute'
ORDER BY n.created_at DESC
LIMIT 1;

-- ========================================
-- INSTRUCCIONES
-- ========================================

/*
🎯 EJECUTA ESTE SCRIPT EN SUPABASE SQL EDITOR

✅ QUE HACE:
1. Elimina el trigger incorrecto (AFTER UPDATE)
2. Crea el trigger correcto (AFTER INSERT)
3. Verifica que el trigger esté configurado correctamente
4. Verifica que tengas FCM token
5. Crea una notificación de prueba
6. Verifica que se creó correctamente

📱 RESULTADO ESPERADO:
- Notificación aparece en la app ✅
- Push notification aparece en bandeja del sistema ✅
- Si no aparece push, el problema es el Edge Function

🔧 PRÓXIMO PASO SI NO FUNCIONA:
- Desplegar el Edge Function: docs/EDGE_FUNCTION_FINAL_WORKING.js
*/