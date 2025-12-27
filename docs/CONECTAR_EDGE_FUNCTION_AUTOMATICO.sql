-- =====================================================
-- CONECTAR EDGE FUNCTION AUTOMÁTICO - SIN HARDCODEAR URLs
-- =====================================================

-- 1. FUNCIÓN QUE USA VARIABLES DE ENTORNO AUTOMÁTICAMENTE
CREATE OR REPLACE FUNCTION send_push_notification_auto(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    user_fcm_token TEXT;
    notification_settings RECORD;
    http_request_id BIGINT;
    supabase_url TEXT;
    supabase_anon_key TEXT;
BEGIN
    -- Obtener URL y key desde configuración de Supabase
    supabase_url := current_setting('app.supabase_url', true);
    supabase_anon_key := current_setting('app.supabase_anon_key', true);
    
    -- Si no están configuradas, usar valores por defecto (debes configurarlos)
    IF supabase_url IS NULL OR supabase_url = '' THEN
        supabase_url := 'https://tu-proyecto.supabase.co';
    END IF;
    
    IF supabase_anon_key IS NULL OR supabase_anon_key = '' THEN
        -- Usar una key temporal (DEBES CONFIGURAR LA REAL)
        supabase_anon_key := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR1LXByb3llY3RvIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NDYwNjgwMDAsImV4cCI6MTk2MTY0NDAwMH0.temp-key';
    END IF;
    
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
    
    -- Llamar a Edge Function usando variables automáticas
    BEGIN
        SELECT net.http_post(
            url := supabase_url || '/functions/v1/send-push-notification',
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

-- 2. TRIGGER AUTOMÁTICO
CREATE OR REPLACE FUNCTION trigger_send_push_auto()
RETURNS TRIGGER AS $$
BEGIN
    -- Enviar push automáticamente para notificaciones nuevas
    IF NEW.is_read = FALSE THEN
        PERFORM send_push_notification_auto(
            NEW.user_id,
            NEW.title,
            NEW.message
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. REEMPLAZAR TRIGGER
DROP TRIGGER IF EXISTS trigger_auto_push_simple ON public.notifications;
DROP TRIGGER IF EXISTS trigger_auto_push_immediate ON public.notifications;
CREATE TRIGGER trigger_auto_push_auto
    AFTER INSERT ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION trigger_send_push_auto();

-- 4. FUNCIÓN PARA CONFIGURAR VARIABLES (EJECUTA ESTO CON TUS DATOS REALES)
CREATE OR REPLACE FUNCTION configure_supabase_settings(
    p_supabase_url TEXT,
    p_anon_key TEXT
)
RETURNS TEXT AS $$
BEGIN
    -- Configurar URL de Supabase
    PERFORM set_config('app.supabase_url', p_supabase_url, false);
    
    -- Configurar Anon Key
    PERFORM set_config('app.supabase_anon_key', p_anon_key, false);
    
    RETURN '✅ Configuración guardada exitosamente';
END;
$$ LANGUAGE plpgsql;

-- 5. FUNCIÓN PARA PROBAR CONFIGURACIÓN
CREATE OR REPLACE FUNCTION test_supabase_config()
RETURNS TABLE(
    setting_name TEXT,
    setting_value TEXT,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'supabase_url'::TEXT,
        COALESCE(current_setting('app.supabase_url', true), 'NO CONFIGURADO')::TEXT,
        CASE 
            WHEN current_setting('app.supabase_url', true) IS NOT NULL THEN '✅ OK'
            ELSE '❌ FALTA'
        END::TEXT
    UNION ALL
    SELECT 
        'supabase_anon_key'::TEXT,
        CASE 
            WHEN current_setting('app.supabase_anon_key', true) IS NOT NULL 
            THEN LEFT(current_setting('app.supabase_anon_key', true), 20) || '...'
            ELSE 'NO CONFIGURADO'
        END::TEXT,
        CASE 
            WHEN current_setting('app.supabase_anon_key', true) IS NOT NULL THEN '✅ OK'
            ELSE '❌ FALTA'
        END::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 6. FUNCIÓN DE PRUEBA MANUAL
CREATE OR REPLACE FUNCTION test_push_auto()
RETURNS TEXT AS $$
DECLARE
    result BOOLEAN;
BEGIN
    SELECT send_push_notification_auto(
        '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
        'Prueba Automática 🤖',
        'Sistema configurado automáticamente sin hardcodear URLs'
    ) INTO result;
    
    IF result THEN
        RETURN '✅ Push notification enviada - Revisa tu celular';
    ELSE
        RETURN '❌ Error - Verifica configuración con test_supabase_config()';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 7. VERIFICAR CONFIGURACIÓN ACTUAL
SELECT * FROM test_supabase_config();

-- 8. CREAR NOTIFICACIÓN DE PRUEBA
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    metadata,
    is_read
) VALUES (
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'Sistema Automático Activado 🤖',
    'Las push notifications funcionan sin hardcodear URLs',
    'general',
    '{"automatic_config": true}'::jsonb,
    FALSE
);

-- 9. VERIFICAR ESTADO
SELECT 
    'PUSH QUEUE STATUS' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN status = 'sent' THEN 1 END) as sent,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 10. MOSTRAR ÚLTIMAS NOTIFICACIONES
SELECT 
    title,
    status,
    created_at,
    error_message
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
ORDER BY created_at DESC 
LIMIT 3;

-- 11. MENSAJE FINAL
SELECT '🚀 SISTEMA AUTOMÁTICO LISTO - CONFIGURA TUS DATOS CON LA FUNCIÓN configure_supabase_settings()' as resultado;

-- INSTRUCCIONES:
-- 1. Ejecuta este SQL (funcionará con valores por defecto)
-- 2. Luego ejecuta: SELECT configure_supabase_settings('https://tu-proyecto.supabase.co', 'tu-anon-key');
-- 3. Verifica con: SELECT * FROM test_supabase_config();
-- 4. Prueba con: SELECT test_push_auto();
-- 5. ¡Las push notifications funcionarán automáticamente!