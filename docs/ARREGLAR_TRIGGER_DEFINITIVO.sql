-- ========================================
-- ARREGLAR TRIGGER DEFINITIVO
-- Cambiar de AFTER UPDATE a AFTER INSERT
-- ========================================

-- PASO 1: ELIMINAR TRIGGER INCORRECTO
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications;
DROP FUNCTION IF EXISTS send_push_notification_on_insert();

-- PASO 2: CREAR FUNCIÓN CORRECTA PARA ENVIAR PUSH
CREATE OR REPLACE FUNCTION send_push_notification_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    recipient_fcm_token TEXT;
    notification_data JSONB;
BEGIN
    -- Obtener FCM token del usuario (TU TABLA: users_profiles)
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
        
        -- Enviar push (manejo de errores)
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

-- PASO 4: CREAR NOTIFICACIÓN DE PRUEBA PARA TU USUARIO
SELECT crear_notificacion_prueba('0dc7b2bc-04c7-430e-8725-19f6cdb55ee3');

-- PASO 5: VERIFICAR SISTEMA
SELECT * FROM diagnosticar_sistema_push();