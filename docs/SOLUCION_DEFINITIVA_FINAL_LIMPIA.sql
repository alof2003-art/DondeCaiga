-- ========================================
-- SOLUCIÓN DEFINITIVA FINAL LIMPIA
-- Fecha: 2024-12-28
-- BASADO EN TUS TABLAS REALES
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

-- PASO 4: FUNCIÓN DE DIAGNÓSTICO
CREATE OR REPLACE FUNCTION diagnosticar_sistema_push()
RETURNS TABLE(
    problema TEXT,
    estado TEXT,
    detalles TEXT
) AS $$
BEGIN
    -- Verificar trigger
    RETURN QUERY
    SELECT 
        'Trigger'::TEXT,
        CASE WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'trigger_send_push_on_notification'
            AND event_manipulation = 'INSERT'
        ) THEN '✅ OK' ELSE '❌ ERROR' END,
        'Debe ser AFTER INSERT'::TEXT;
    
    -- Verificar FCM tokens
    RETURN QUERY
    SELECT 
        'FCM Tokens'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN '✅ OK' ELSE '❌ SIN TOKENS' END,
        'Usuarios con token: ' || COUNT(*)::TEXT
    FROM users_profiles 
    WHERE fcm_token IS NOT NULL AND fcm_token != '';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 5: FUNCIÓN PARA CREAR NOTIFICACIÓN DE PRUEBA
CREATE OR REPLACE FUNCTION crear_notificacion_prueba(target_user_id UUID)
RETURNS UUID AS $$
DECLARE
    new_notification_id UUID;
BEGIN
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        created_at
    ) VALUES (
        target_user_id,
        '🎯 Prueba Push',
        'Si recibes esto, el sistema funciona!',
        'test',
        FALSE,
        NOW()
    ) RETURNING id INTO new_notification_id;
    
    RETURN new_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- INSTRUCCIONES
-- ========================================

/*
🎯 EJECUTAR EN SUPABASE:

1. Ejecuta todo este script

2. Verifica:
   SELECT * FROM diagnosticar_sistema_push();

3. Prueba:
   SELECT crear_notificacion_prueba('tu-user-id');

✅ PROBLEMA SOLUCIONADO:
- Trigger cambiado de AFTER UPDATE a AFTER INSERT
- Usando tu tabla real: users_profiles
*/