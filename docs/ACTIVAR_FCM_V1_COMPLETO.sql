-- =====================================================
-- ACTIVAR FIREBASE CLOUD MESSAGING API V1 COMPLETO
-- =====================================================

-- 1. ACTUALIZAR FUNCIÓN PARA LLAMAR A EDGE FUNCTION FCM V1
CREATE OR REPLACE FUNCTION send_push_notification_v1(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT,
    p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS BOOLEAN AS $$
DECLARE
    fcm_token TEXT;
    notification_settings RECORD;
    edge_function_url TEXT;
    edge_function_response TEXT;
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
    SELECT fcm_token INTO fcm_token 
    FROM public.users_profiles 
    WHERE id = p_user_id AND fcm_token IS NOT NULL;
    
    -- Si no tiene token FCM, no se puede enviar push
    IF fcm_token IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Agregar a cola para procesamiento
    INSERT INTO public.push_notification_queue (
        user_id,
        fcm_token,
        title,
        body,
        data,
        created_at,
        status,
        api_version
    ) VALUES (
        p_user_id,
        fcm_token,
        p_title,
        p_body,
        p_data,
        NOW(),
        'pending',
        'v1'
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. ACTUALIZAR TABLA DE COLA PARA INCLUIR VERSIÓN DE API
ALTER TABLE public.push_notification_queue 
ADD COLUMN IF NOT EXISTS api_version TEXT DEFAULT 'v1';

-- 3. CREAR FUNCIÓN PARA PROCESAR COLA CON FCM V1
CREATE OR REPLACE FUNCTION process_push_notification_queue_v1()
RETURNS INTEGER AS $$
DECLARE
    notification_record RECORD;
    processed_count INTEGER := 0;
    edge_function_response TEXT;
    http_request_id BIGINT;
BEGIN
    -- Procesar notificaciones pendientes (máximo 20 por vez para evitar rate limits)
    FOR notification_record IN 
        SELECT * FROM public.push_notification_queue 
        WHERE status = 'pending' 
        AND attempts < 3
        AND api_version = 'v1'
        ORDER BY created_at ASC 
        LIMIT 20
    LOOP
        BEGIN
            -- Llamar a la Edge Function de Supabase
            SELECT net.http_post(
                url := 'https://tu-proyecto.supabase.co/functions/v1/send-push-notification',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || current_setting('app.supabase_anon_key', true)
                ),
                body := jsonb_build_object(
                    'fcm_token', notification_record.fcm_token,
                    'title', notification_record.title,
                    'body', notification_record.body,
                    'data', notification_record.data
                )
            ) INTO http_request_id;
            
            -- Marcar como enviado (la respuesta se procesará asíncronamente)
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

-- 4. ACTUALIZAR TRIGGER PARA USAR NUEVA FUNCIÓN
CREATE OR REPLACE FUNCTION trigger_send_push_notification_v1()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo enviar push para notificaciones nuevas (no leídas)
    IF NEW.is_read = FALSE THEN
        PERFORM send_push_notification_v1(
            NEW.user_id,
            NEW.title,
            NEW.message,
            jsonb_build_object(
                'notification_id', NEW.id,
                'type', NEW.type,
                'metadata', NEW.metadata
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. REEMPLAZAR TRIGGER ANTERIOR
DROP TRIGGER IF EXISTS trigger_auto_push_notification ON public.notifications;
CREATE TRIGGER trigger_auto_push_notification_v1
    AFTER INSERT ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION trigger_send_push_notification_v1();

-- 6. AGREGAR COLUMNA PARA HTTP REQUEST ID
ALTER TABLE public.push_notification_queue 
ADD COLUMN IF NOT EXISTS http_request_id BIGINT;

-- 7. CREAR FUNCIÓN PARA PROCESAR RESPUESTAS HTTP
CREATE OR REPLACE FUNCTION process_http_responses()
RETURNS INTEGER AS $$
DECLARE
    response_record RECORD;
    processed_count INTEGER := 0;
BEGIN
    -- Procesar respuestas HTTP pendientes
    FOR response_record IN 
        SELECT pnq.*, hr.status_code, hr.content
        FROM public.push_notification_queue pnq
        JOIN net.http_response hr ON hr.id = pnq.http_request_id
        WHERE pnq.status = 'sent' 
        AND pnq.http_request_id IS NOT NULL
        LIMIT 50
    LOOP
        -- Actualizar estado basado en respuesta HTTP
        IF response_record.status_code = 200 THEN
            UPDATE public.push_notification_queue 
            SET status = 'delivered'
            WHERE id = response_record.id;
        ELSE
            UPDATE public.push_notification_queue 
            SET 
                status = 'failed',
                error_message = 'HTTP ' || response_record.status_code || ': ' || response_record.content
            WHERE id = response_record.id;
        END IF;
        
        processed_count := processed_count + 1;
    END LOOP;
    
    RETURN processed_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. CREAR NOTIFICACIÓN DE PRUEBA CON FCM V1
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    metadata,
    is_read,
    created_at
) VALUES (
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'Firebase FCM v1 Activado 🚀',
    'Tu app ahora usa la API más moderna de Firebase Cloud Messaging',
    'general',
    '{"fcm_version": "v1", "test": true}'::jsonb,
    FALSE,
    NOW()
);

-- 9. VERIFICAR COLA DE NOTIFICACIONES
SELECT 
    'FCM V1 QUEUE STATUS' as info,
    COUNT(*) as total_notifications,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
    COUNT(CASE WHEN status = 'sent' THEN 1 END) as sent,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 10. MOSTRAR ÚLTIMAS NOTIFICACIONES EN COLA
SELECT 
    id,
    title,
    body,
    status,
    api_version,
    attempts,
    created_at,
    sent_at,
    error_message
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
ORDER BY created_at DESC 
LIMIT 5;

-- 11. PROCESAR COLA MANUALMENTE (OPCIONAL)
-- SELECT process_push_notification_queue_v1();

-- 12. MENSAJE FINAL
SELECT '✅ FIREBASE CLOUD MESSAGING API V1 CONFIGURADO - CONFIGURA EDGE FUNCTION' as resultado;