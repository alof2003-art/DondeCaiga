-- =====================================================
-- SISTEMA PUSH FINAL SIMPLIFICADO
-- =====================================================
-- En lugar de usar HTTP desde SQL, Flutter llamará directamente a la Edge Function

-- 1. Función simplificada que solo marca como "ready_for_push"
CREATE OR REPLACE FUNCTION send_push_notification_flutter(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    user_fcm_token TEXT;
    notification_settings RECORD;
BEGIN
    -- Verificar si el usuario tiene notificaciones push habilitadas
    SELECT * INTO notification_settings 
    FROM public.notification_settings 
    WHERE user_id = p_user_id;
    
    -- Si no tiene configuración o tiene push deshabilitado, no enviar
    IF notification_settings IS NULL OR NOT notification_settings.push_notifications_enabled THEN
        RETURN FALSE;
    END IF;
    
    -- Obtener el token FCM del usuario
    SELECT up.fcm_token INTO user_fcm_token
    FROM public.users_profiles up
    WHERE up.id = p_user_id AND up.fcm_token IS NOT NULL;
    
    -- Si no tiene token FCM, no se puede enviar push
    IF user_fcm_token IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Registrar en cola con status "ready_for_push" para que Flutter lo procese
    INSERT INTO public.push_notification_queue (
        user_id,
        fcm_token,
        title,
        body,
        data,
        created_at,
        status
    ) VALUES (
        p_user_id,
        user_fcm_token,
        p_title,
        p_body,
        '{}'::jsonb,
        NOW(),
        'ready_for_push'  -- Flutter buscará este status
    );
    
    RETURN TRUE;
    
EXCEPTION WHEN OTHERS THEN
    -- Si falla, registrar error
    INSERT INTO public.push_notification_queue (
        user_id,
        fcm_token,
        title,
        body,
        data,
        created_at,
        status,
        error_message
    ) VALUES (
        p_user_id,
        COALESCE(user_fcm_token, 'no_token'),
        p_title,
        p_body,
        '{}'::jsonb,
        NOW(),
        'failed',
        SQLERRM
    );
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- 2. Función para que Flutter obtenga notificaciones pendientes
CREATE OR REPLACE FUNCTION get_pending_push_notifications()
RETURNS TABLE(
    id UUID,
    user_id UUID,
    fcm_token TEXT,
    title TEXT,
    body TEXT,
    data JSONB,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pnq.id,
        pnq.user_id,
        pnq.fcm_token,
        pnq.title,
        pnq.body,
        pnq.data,
        pnq.created_at
    FROM public.push_notification_queue pnq
    WHERE pnq.status = 'ready_for_push'
    ORDER BY pnq.created_at ASC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- 3. Función para marcar notificación como procesada
CREATE OR REPLACE FUNCTION mark_push_notification_sent(notification_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.push_notification_queue 
    SET 
        status = 'sent',
        sent_at = NOW(),
        attempts = attempts + 1
    WHERE id = notification_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- 4. Actualizar trigger para usar la nueva función
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON public.notifications;
CREATE OR REPLACE FUNCTION trigger_send_push_flutter()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo enviar push para notificaciones nuevas (no leídas)
    IF NEW.is_read = FALSE THEN
        PERFORM send_push_notification_flutter(
            NEW.user_id,
            NEW.title,
            NEW.message
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION trigger_send_push_flutter();

-- 5. Probar el sistema
SELECT send_push_notification_flutter(
    (SELECT id FROM users_profiles WHERE email = 'alof2003@gmail.com'),
    'SISTEMA FLUTTER 🚀',
    'Esta notificación será procesada por Flutter'
);

-- Ver notificaciones pendientes
SELECT * FROM get_pending_push_notifications();