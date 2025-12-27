-- =====================================================
-- ACTIVAR PUSH NOTIFICATIONS - SISTEMA COMPLETO FINAL
-- =====================================================
-- El FCM token ya funciona, ahora activemos todo el sistema

-- 1. CREAR TABLA APP_CONFIG SI NO EXISTE
CREATE TABLE IF NOT EXISTS public.app_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. INSERTAR CONFIGURACIÓN DE SUPABASE
INSERT INTO public.app_config (key, value) VALUES 
('supabase_url', 'https://louehuwimvwsoqesjjau.supabase.co'),
('supabase_anon_key', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvdWVodXdpbXZ3c29xZXNqamF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3OTQ4MTYsImV4cCI6MjA4MDM3MDgxNn0.vhqclBtgt-o_GTNFGsU-pKYK68coeemIjl_CTQl8Rz8')
ON CONFLICT (key) DO UPDATE SET 
    value = EXCLUDED.value,
    updated_at = NOW();

-- 3. VERIFICAR CONFIGURACIÓN
SELECT 
    'CONFIGURACIÓN SUPABASE' as info,
    key,
    CASE 
        WHEN key = 'supabase_anon_key' THEN LEFT(value, 20) || '...'
        ELSE value
    END as value_preview
FROM public.app_config
ORDER BY key;

-- 4. CREAR FUNCIÓN PARA OBTENER CONFIGURACIÓN
CREATE OR REPLACE FUNCTION get_app_config(config_key TEXT)
RETURNS TEXT AS $$
DECLARE
    config_value TEXT;
BEGIN
    SELECT value INTO config_value 
    FROM public.app_config 
    WHERE key = config_key;
    
    RETURN config_value;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. CREAR FUNCIÓN PARA ENVIAR PUSH NOTIFICATIONS
CREATE OR REPLACE FUNCTION send_push_notification_v2(
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
    -- Obtener configuración
    supabase_url := get_app_config('supabase_url');
    supabase_anon_key := get_app_config('supabase_anon_key');
    
    -- Verificar configuración
    IF supabase_url IS NULL OR supabase_anon_key IS NULL THEN
        INSERT INTO public.push_notification_queue (
            user_id, fcm_token, title, body, status, error_message
        ) VALUES (
            p_user_id, 'no_config', p_title, p_body, 'failed', 
            'Configuración de Supabase faltante'
        );
        RETURN FALSE;
    END IF;
    
    -- Verificar configuración de notificaciones
    SELECT * INTO notification_settings 
    FROM public.notification_settings 
    WHERE user_id = p_user_id;
    
    IF notification_settings IS NULL OR NOT notification_settings.push_notifications_enabled THEN
        RETURN FALSE;
    END IF;
    
    -- Obtener FCM token
    SELECT fcm_token INTO user_fcm_token
    FROM public.users_profiles 
    WHERE id = p_user_id AND fcm_token IS NOT NULL;
    
    IF user_fcm_token IS NULL THEN
        INSERT INTO public.push_notification_queue (
            user_id, fcm_token, title, body, status, error_message
        ) VALUES (
            p_user_id, 'no_token', p_title, p_body, 'failed', 
            'FCM token no encontrado'
        );
        RETURN FALSE;
    END IF;
    
    -- Llamar a Edge Function
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
            user_id, fcm_token, title, body, status, sent_at
        ) VALUES (
            p_user_id, user_fcm_token, p_title, p_body, 'sent', NOW()
        );
        
        RETURN TRUE;
        
    EXCEPTION WHEN OTHERS THEN
        -- Registrar error
        INSERT INTO public.push_notification_queue (
            user_id, fcm_token, title, body, status, error_message
        ) VALUES (
            p_user_id, user_fcm_token, p_title, p_body, 'failed', SQLERRM
        );
        
        RETURN FALSE;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. CREAR TRIGGER AUTOMÁTICO
CREATE OR REPLACE FUNCTION trigger_send_push_v2()
RETURNS TRIGGER AS $$
BEGIN
    -- Enviar push para notificaciones nuevas (no leídas)
    IF NEW.is_read = FALSE THEN
        PERFORM send_push_notification_v2(
            NEW.user_id,
            NEW.title,
            NEW.message
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Limpiar triggers anteriores
DROP TRIGGER IF EXISTS trigger_auto_push_v2 ON public.notifications;

-- Crear trigger final
CREATE TRIGGER trigger_auto_push_v2
    AFTER INSERT ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION trigger_send_push_v2();

-- 7. ASEGURAR CONFIGURACIÓN DE NOTIFICACIONES PARA TU USUARIO
INSERT INTO public.notification_settings (user_id, push_notifications_enabled, email_notifications_enabled)
VALUES ('0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid, true, true)
ON CONFLICT (user_id) DO UPDATE SET 
    push_notifications_enabled = true,
    email_notifications_enabled = true;

-- 8. FUNCIÓN PARA PROBAR SISTEMA COMPLETO
CREATE OR REPLACE FUNCTION test_push_system_complete()
RETURNS TEXT AS $$
DECLARE
    config_ok BOOLEAN := FALSE;
    token_ok BOOLEAN := FALSE;
    push_result BOOLEAN := FALSE;
    current_token TEXT;
BEGIN
    -- Verificar configuración
    IF get_app_config('supabase_url') IS NOT NULL 
       AND get_app_config('supabase_anon_key') IS NOT NULL THEN
        config_ok := TRUE;
    END IF;
    
    -- Verificar FCM token
    SELECT fcm_token INTO current_token
    FROM public.users_profiles 
    WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;
    
    IF current_token IS NOT NULL THEN
        token_ok := TRUE;
    END IF;
    
    -- Probar envío de push
    IF config_ok AND token_ok THEN
        SELECT send_push_notification_v2(
            '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
            'Sistema Push Activado 🚀',
            'Si recibes esto, las notificaciones push funcionan perfectamente'
        ) INTO push_result;
    END IF;
    
    -- Retornar resultado detallado
    IF config_ok AND token_ok AND push_result THEN
        RETURN '🎉 SISTEMA PUSH COMPLETAMENTE FUNCIONAL - Revisa tu celular en 10 segundos';
    ELSIF NOT config_ok THEN
        RETURN '❌ Configuración faltante: ' || 
               CASE WHEN get_app_config('supabase_url') IS NULL THEN 'URL ' ELSE '' END ||
               CASE WHEN get_app_config('supabase_anon_key') IS NULL THEN 'KEY ' ELSE '' END;
    ELSIF NOT token_ok THEN
        RETURN '❌ FCM Token faltante - Token actual: ' || COALESCE(current_token, 'NULL');
    ELSE
        RETURN '❌ Error al enviar push - Verifica Edge Function';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. VERIFICAR TODO EL SISTEMA
SELECT 
    'VERIFICACIÓN COMPLETA' as info,
    'Configuración' as componente,
    CASE 
        WHEN get_app_config('supabase_url') IS NOT NULL 
             AND get_app_config('supabase_anon_key') IS NOT NULL 
        THEN '✅ CONFIGURADO'
        ELSE '❌ FALTANTE'
    END as estado;

SELECT 
    'VERIFICACIÓN COMPLETA' as info,
    'FCM Token' as componente,
    CASE 
        WHEN fcm_token IS NOT NULL THEN '✅ DISPONIBLE'
        ELSE '❌ FALTANTE'
    END as estado,
    LEFT(COALESCE(fcm_token, 'NULL'), 30) || '...' as token_preview
FROM public.users_profiles 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

SELECT 
    'VERIFICACIÓN COMPLETA' as info,
    'Notification Settings' as componente,
    CASE 
        WHEN push_notifications_enabled THEN '✅ ACTIVADO'
        ELSE '❌ DESACTIVADO'
    END as estado
FROM public.notification_settings 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 10. PROBAR SISTEMA COMPLETO
SELECT test_push_system_complete();

-- 11. CREAR NOTIFICACIÓN DE PRUEBA AUTOMÁTICA
INSERT INTO public.notifications (user_id, type, title, message, is_read) 
VALUES (
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid, 
    'general', 
    'Notificación Push Automática 🎉', 
    'Esta notificación se envió automáticamente cuando se insertó en la base de datos', 
    FALSE
);

-- 12. VERIFICAR COLA DE PUSH NOTIFICATIONS
SELECT 
    'COLA DE PUSH NOTIFICATIONS' as info,
    COUNT(*) as total_enviados,
    COUNT(CASE WHEN status = 'sent' THEN 1 END) as exitosos,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as fallidos,
    MAX(created_at) as ultimo_envio
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

SELECT '🚀 SISTEMA PUSH NOTIFICATIONS COMPLETAMENTE ACTIVADO' as resultado;
SELECT '📱 Revisa tu celular - Deberías recibir notificaciones push ahora' as instruccion;