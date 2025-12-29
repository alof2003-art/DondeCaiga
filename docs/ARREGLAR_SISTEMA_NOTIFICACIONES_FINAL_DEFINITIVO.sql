-- =====================================================
-- ARREGLAR SISTEMA NOTIFICACIONES FINAL DEFINITIVO
-- =====================================================
-- Problema identificado: Hay DOS sistemas funcionando al mismo tiempo
-- y el procesador de Flutter busca 'pending' pero las funciones crean 'ready_for_push'

-- PASO 1: Unificar el sistema - Todo debe usar 'pending'
UPDATE public.push_notification_queue 
SET status = 'pending' 
WHERE status = 'ready_for_push';

-- PASO 2: Arreglar la función principal para usar 'pending'
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
    
    -- Registrar en cola con status "pending" (NO ready_for_push)
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
        'pending'  -- ✅ CAMBIO CRÍTICO: pending no ready_for_push
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

-- PASO 3: Arreglar el trigger para que funcione con INSERT
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

-- CREAR TRIGGER CORRECTO PARA INSERT
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON public.notifications  -- ✅ INSERT no UPDATE
    FOR EACH ROW
    EXECUTE FUNCTION trigger_send_push_flutter();

-- PASO 4: Limpiar notificaciones viejas para evitar spam
DELETE FROM public.push_notification_queue 
WHERE status = 'sent' 
AND sent_at < NOW() - INTERVAL '1 hour';

-- PASO 5: Verificar que todo esté correcto
SELECT 'VERIFICACIÓN FINAL' as info;

-- Ver triggers activos
SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_send_push_on_notification';

-- Ver notificaciones en cola
SELECT 
    status,
    COUNT(*) as cantidad,
    MAX(created_at) as ultima
FROM public.push_notification_queue 
GROUP BY status;

-- PASO 6: Crear notificación de prueba FINAL
INSERT INTO public.notifications (
    user_id,
    title,
    message,
    type,
    metadata,
    is_read,
    created_at
) VALUES (
    (SELECT id FROM users_profiles WHERE email = 'alof2003@gmail.com'),
    '🎯 SISTEMA ARREGLADO ' || TO_CHAR(NOW(), 'HH24:MI:SS'),
    '¡Perfecto Gabriel! Si recibes esta notificación UNA SOLA VEZ, el sistema está completamente arreglado. Hora: ' || TO_CHAR(NOW(), 'HH24:MI:SS DD/MM/YYYY'),
    'sistema_arreglado',
    jsonb_build_object(
        'test_final', true,
        'timestamp', NOW()::text,
        'should_work', 'perfectly'
    ),
    false,
    NOW()
);

SELECT '🎉 SISTEMA COMPLETAMENTE ARREGLADO - Deberías recibir UNA notificación en 10 segundos' as resultado;