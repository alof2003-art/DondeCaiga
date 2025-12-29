-- =====================================================
-- ARREGLAR FUNCIÓN HTTP PARA NOTIFICACIONES PUSH
-- =====================================================

-- Función corregida usando http_post directamente (sin schema net)
CREATE OR REPLACE FUNCTION process_push_queue_real_fixed()
RETURNS INTEGER AS $$
DECLARE
    notification_record RECORD;
    processed_count INTEGER := 0;
    http_response http_response;
    supabase_url TEXT;
    supabase_anon_key TEXT;
BEGIN
    -- Obtener configuración real
    SELECT value INTO supabase_url FROM public.app_config WHERE key = 'supabase_url';
    SELECT value INTO supabase_anon_key FROM public.app_config WHERE key = 'supabase_anon_key';
    
    -- Procesar notificaciones pendientes
    FOR notification_record IN 
        SELECT * FROM public.push_notification_queue 
        WHERE status = 'pending' 
        AND attempts < 3
        ORDER BY created_at ASC 
        LIMIT 5
    LOOP
        BEGIN
            -- Llamar a tu Edge Function real (SIN net. prefix)
            SELECT http_post(
                supabase_url || '/functions/v1/send-push-notification',
                jsonb_build_object(
                    'fcm_token', notification_record.fcm_token,
                    'title', notification_record.title,
                    'body', notification_record.body
                )::text,
                'application/json',
                jsonb_build_object(
                    'Authorization', 'Bearer ' || supabase_anon_key
                )
            ) INTO http_response;
            
            -- Marcar como enviado
            UPDATE public.push_notification_queue 
            SET 
                status = 'sent',
                sent_at = NOW(),
                attempts = attempts + 1
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
$$ LANGUAGE plpgsql;

-- Probar la función corregida
SELECT process_push_queue_real_fixed();