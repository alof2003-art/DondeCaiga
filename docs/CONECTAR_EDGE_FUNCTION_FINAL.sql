-- =====================================================
-- CONECTAR EDGE FUNCTION PARA PROCESAR COLA
-- =====================================================

-- 1. FUNCIÓN PARA PROCESAR COLA CON TU EDGE FUNCTION
CREATE OR REPLACE FUNCTION process_push_queue_with_edge_function()
RETURNS INTEGER AS $$
DECLARE
    notification_record RECORD;
    processed_count INTEGER := 0;
    http_request_id BIGINT;
    edge_function_url TEXT := 'https://TU-PROYECTO.supabase.co/functions/v1/send-push-notification';
    supabase_anon_key TEXT := 'TU-ANON-KEY';
BEGIN
    -- Procesar notificaciones pendientes (máximo 10 por vez)
    FOR notification_record IN 
        SELECT * FROM public.push_notification_queue 
        WHERE status = 'pending' 
        AND attempts < 3
        ORDER BY created_at ASC 
        LIMIT 10
    LOOP
        BEGIN
            -- Llamar a tu Edge Function
            SELECT net.http_post(
                url := edge_function_url,
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || supabase_anon_key
                ),
                body := jsonb_build_object(
                    'fcm_token', notification_record.fcm_token,
                    'title', notification_record.title,
                    'body', notification_record.body
                )
            ) INTO http_request_id;
            
            -- Marcar como enviado
            UPDATE public.push_notification_queue 
            SET 
                status = 'sent',
                sent_at = NOW(),
                attempts = attempts + 1,
                http_request_id = http_request_id
            WHERE id = notification_record.id;
            
            processed_count := processed_count + 1;
            
        EXCEPTION WHEN OTHERS THEN
            -- Marcar como fallido si hay error
            UPDATE public.push_notification_queue 
            SET 
                status = 'failed',
                attempts = attempts + 1,
                error_message = SQLERRM
            WHERE id = notification_record.id;
        END;
    END LOOP;
    
    RETURN processed_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. FUNCIÓN AUTOMÁTICA QUE LLAMA A EDGE FUNCTION INMEDIATAMENTE
CREATE OR REPLACE FUNCTION send_push_notification_immediate(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    user_fcm_token TEXT;
    notification_settings RECORD;
    http_request_id BIGINT;
    edge_function_url TEXT := 'https://TU-PROYECTO.supabase.co/functions/v1/send-push-notification';
    supabase_anon_key TEXT := 'TU-ANON-KEY';
BEGIN
    -- Verificar configuración de notificaciones
    SELECT * INTO notification_settings 
    FROM public.notification_settings 
    WHERE user_id = p_user_id;
    
    IF notification_settings IS NULL OR NOT notification_settings.push_notifications_enabled THEN
        RETURN FALSE;
    END IF;
    
    -- Obtener FCM token
    SELECT up.fcm_token INTO user_fcm_token
    FROM public.users_profiles up
    WHERE up.id = p_user_id AND up.fcm_token IS NOT NULL;
    
    IF user_fcm_token IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Llamar inmediatamente a Edge Function
    BEGIN
        SELECT net.http_post(
            url := edge_function_url,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || supabase_anon_key
            ),
            body := jsonb_build_object(
                'fcm_token', user_fcm_token,
                'title', p_title,
                'body', p_body
            )
        ) INTO http_request_id;
        
        -- Registrar como enviado
        INSERT INTO public.push_notification_queue (
            user_id,
            fcm_token,
            title,
            body,
            status,
            sent_at,
            http_request_id
        ) VALUES (
            p_user_id,
            user_fcm_token,
            p_title,
            p_body,
            'sent',
            NOW(),
            http_request_id
        );
        
        RETURN TRUE;
        
    EXCEPTION WHEN OTHERS THEN
        -- Registrar error
        INSERT INTO public.push_notification_queue (
            user_id,
            fcm_token,
            title,
            body,
            status,
            error_message
        ) VALUES (
            p_user_id,
            user_fcm_token,
            p_title,
            p_body,
            'failed',
            SQLERRM
        );
        
        RETURN FALSE;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. ACTUALIZAR TRIGGER PARA USAR FUNCIÓN INMEDIATA
CREATE OR REPLACE FUNCTION trigger_send_push_immediate()
RETURNS TRIGGER AS $$
BEGIN
    -- Enviar push inmediatamente para notificaciones nuevas
    IF NEW.is_read = FALSE THEN
        PERFORM send_push_notification_immediate(
            NEW.user_id,
            NEW.title,
            NEW.message
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. REEMPLAZAR TRIGGER
DROP TRIGGER IF EXISTS trigger_auto_push_simple ON public.notifications;
CREATE TRIGGER trigger_auto_push_immediate
    AFTER INSERT ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION trigger_send_push_immediate();

-- 5. FUNCIÓN PARA PROBAR EDGE FUNCTION DIRECTAMENTE
CREATE OR REPLACE FUNCTION test_edge_function_direct()
RETURNS TEXT AS $$
DECLARE
    result BOOLEAN;
BEGIN
    SELECT send_push_notification_immediate(
        '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
        'Prueba Edge Function 🚀',
        'Probando conexión directa con Firebase FCM v1'
    ) INTO result;
    
    IF result THEN
        RETURN '✅ Edge Function llamada exitosamente - Revisa tu celular';
    ELSE
        RETURN '❌ Error en Edge Function - Verifica configuración';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 6. CREAR NOTIFICACIÓN DE PRUEBA AUTOMÁTICA
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    metadata,
    is_read
) VALUES (
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'Edge Function Conectada 🔗',
    'Tu sistema de push notifications está completamente configurado',
    'general',
    '{"edge_function_connected": true}'::jsonb,
    FALSE
);

-- 7. VERIFICAR ESTADO ACTUAL
SELECT 
    'PUSH NOTIFICATIONS STATUS' as info,
    COUNT(*) as total_notifications,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
    COUNT(CASE WHEN status = 'sent' THEN 1 END) as sent,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 8. MOSTRAR ÚLTIMAS NOTIFICACIONES
SELECT 
    'LATEST PUSH NOTIFICATIONS' as info,
    title,
    body,
    status,
    created_at,
    sent_at,
    error_message
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
ORDER BY created_at DESC 
LIMIT 5;

-- 9. MENSAJE FINAL
SELECT '🚀 EDGE FUNCTION CONECTADA - ACTUALIZA URLs Y PRUEBA' as resultado;

-- INSTRUCCIONES IMPORTANTES:
-- 1. Reemplaza 'TU-PROYECTO' con tu URL real de Supabase
-- 2. Reemplaza 'TU-ANON-KEY' con tu clave anon real
-- 3. Asegúrate de que tu Edge Function esté desplegada
-- 4. Configura FIREBASE_SERVICE_ACCOUNT en Supabase
-- 5. ¡Las push notifications funcionarán automáticamente!