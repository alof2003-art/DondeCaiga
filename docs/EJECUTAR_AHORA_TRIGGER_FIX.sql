-- ========================================
-- EJECUTAR AHORA - ARREGLAR TRIGGER
-- ========================================

-- 1. ELIMINAR TRIGGER INCORRECTO
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications;
DROP FUNCTION IF EXISTS send_push_notification_on_insert();

-- 2. CREAR FUNCIÓN CORRECTA
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

-- 3. CREAR TRIGGER CORRECTO (AFTER INSERT)
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_on_insert();

-- 4. CREAR NOTIFICACIÓN DE PRUEBA
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    is_read,
    created_at
) VALUES (
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    '🎯 TRIGGER ARREGLADO',
    'Si recibes esto en la bandeja, el sistema funciona!',
    'test',
    FALSE,
    NOW()
);

-- 5. VERIFICAR TRIGGER
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_send_push_on_notification';