-- ========================================
-- PROBAR SISTEMA COMPLETO CON REAL-TIME
-- ========================================

-- 1. PRIMERO EJECUTAR EL TRIGGER FIX
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications;
DROP FUNCTION IF EXISTS send_push_notification_on_insert();

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
            'fcm_token', recipient_fcm_token,
            'title', NEW.title,
            'body', NEW.message
        );
        
        -- Enviar push
        BEGIN
            PERFORM net.http_post(
                url := 'https://louehuwimvwsoqesjjau.supabase.co/functions/v1/send-push-notification',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || current_setting('app.jwt_token', true)
                ),
                body := notification_data
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Push notification failed: %', SQLERRM;
        END;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- CREAR TRIGGER CORRECTO (AFTER INSERT)
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_on_insert();

-- 2. CREAR NOTIFICACIÓN DE PRUEBA REAL-TIME
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    is_read,
    created_at
) VALUES (
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    '🚀 REAL-TIME TEST',
    'Esta notificación debería aparecer automáticamente en la app sin refrescar!',
    'test',
    FALSE,
    NOW()
);

-- 3. VERIFICAR QUE TODO ESTÉ CONFIGURADO
SELECT 
    'Trigger configurado' as check_item,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'trigger_send_push_on_notification'
        AND event_manipulation = 'INSERT'
    ) THEN '✅ OK' ELSE '❌ ERROR' END as status;

-- 4. VERIFICAR FCM TOKEN
SELECT 
    'FCM Token' as check_item,
    CASE WHEN fcm_token IS NOT NULL AND fcm_token != '' 
         THEN '✅ OK' ELSE '❌ SIN TOKEN' END as status,
    email,
    LEFT(fcm_token, 30) || '...' as token_preview
FROM users_profiles 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3';

-- 5. VER ÚLTIMAS NOTIFICACIONES
SELECT 
    title,
    message,
    created_at,
    is_read
FROM notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'
ORDER BY created_at DESC 
LIMIT 5;