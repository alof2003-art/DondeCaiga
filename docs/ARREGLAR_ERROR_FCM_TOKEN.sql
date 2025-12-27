-- =====================================================
-- ARREGLAR ERROR FCM_TOKEN - VERSIÓN CORREGIDA
-- =====================================================

-- 1. FUNCIÓN CORREGIDA PARA ENVIAR PUSH
CREATE OR REPLACE FUNCTION send_push_notification_final(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT,
    p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS BOOLEAN AS $$
DECLARE
    user_fcm_token TEXT;
    notification_settings RECORD;
    http_request_id BIGINT;
BEGIN
    -- Verificar si el usuario tiene notificaciones push habilitadas
    SELECT * INTO notification_settings 
    FROM public.notification_settings 
    WHERE user_id = p_user_id;
    
    -- Si no tiene configuración o tiene push deshabilitado, no enviar
    IF notification_settings IS NULL OR NOT notification_settings.push_notifications_enabled THEN
        RETURN FALSE;
    END IF;
    
    -- Obtener el token FCM del usuario (CORREGIDO: especificar tabla)
    SELECT up.fcm_token INTO user_fcm_token
    FROM public.users_profiles up
    WHERE up.id = p_user_id AND up.fcm_token IS NOT NULL;
    
    -- Si no tiene token FCM, no se puede enviar push
    IF user_fcm_token IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Llamar directamente a tu Edge Function
    BEGIN
        SELECT net.http_post(
            url := 'https://qjvlnqjqjqjqjqjqjqjq.supabase.co/functions/v1/send-push-notification',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || current_setting('app.supabase_anon_key', true)
            ),
            body := jsonb_build_object(
                'fcm_token', user_fcm_token,
                'title', p_title,
                'body', p_body
            )
        ) INTO http_request_id;
        
        -- Registrar en cola para seguimiento
        INSERT INTO public.push_notification_queue (
            user_id,
            fcm_token,
            title,
            body,
            data,
            created_at,
            status,
            api_version,
            http_request_id
        ) VALUES (
            p_user_id,
            user_fcm_token,
            p_title,
            p_body,
            p_data,
            NOW(),
            'sent',
            'v1_google_auth',
            http_request_id
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
            api_version,
            error_message
        ) VALUES (
            p_user_id,
            user_fcm_token,
            p_title,
            p_body,
            p_data,
            NOW(),
            'failed',
            'v1_google_auth',
            SQLERRM
        );
        
        RETURN FALSE;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. TRIGGER CORREGIDO
CREATE OR REPLACE FUNCTION trigger_send_push_notification_final()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo enviar push para notificaciones nuevas (no leídas)
    IF NEW.is_read = FALSE THEN
        PERFORM send_push_notification_final(
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

-- 3. REEMPLAZAR TRIGGER
DROP TRIGGER IF EXISTS trigger_auto_push_notification ON public.notifications;
DROP TRIGGER IF EXISTS trigger_auto_push_notification_v1 ON public.notifications;
DROP TRIGGER IF EXISTS trigger_auto_push_notification_final ON public.notifications;

CREATE TRIGGER trigger_auto_push_notification_final
    AFTER INSERT ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION trigger_send_push_notification_final();

-- 4. CREAR TABLA DE COLA SI NO EXISTE
CREATE TABLE IF NOT EXISTS public.push_notification_queue (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'failed')),
    api_version TEXT DEFAULT 'v1_google_auth',
    attempts INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    http_request_id BIGINT
);

-- 5. CREAR ÍNDICES SI NO EXISTEN
CREATE INDEX IF NOT EXISTS idx_push_queue_status ON public.push_notification_queue(status);
CREATE INDEX IF NOT EXISTS idx_push_queue_user_id ON public.push_notification_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_push_queue_created_at ON public.push_notification_queue(created_at);

-- 6. HABILITAR RLS
ALTER TABLE public.push_notification_queue ENABLE ROW LEVEL SECURITY;

-- 7. CREAR POLÍTICA RLS
DROP POLICY IF EXISTS "Users can view their own push notifications" ON public.push_notification_queue;
CREATE POLICY "Users can view their own push notifications" ON public.push_notification_queue 
    FOR SELECT USING (user_id = auth.uid());

-- 8. FUNCIÓN DE PRUEBA CORREGIDA
CREATE OR REPLACE FUNCTION test_push_notification(p_user_id UUID)
RETURNS TEXT AS $$
DECLARE
    result BOOLEAN;
BEGIN
    SELECT send_push_notification_final(
        p_user_id,
        'Prueba Manual Corregida 🧪',
        'Esta es una notificación de prueba con el error arreglado'
    ) INTO result;
    
    IF result THEN
        RETURN 'Push notification enviada exitosamente';
    ELSE
        RETURN 'Error: No se pudo enviar la push notification (verifica FCM token)';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 9. CREAR NOTIFICACIÓN DE PRUEBA
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
    'Error Arreglado 🔧',
    'El problema del FCM token ha sido solucionado',
    'general',
    '{"error_fixed": true, "test": true}'::jsonb,
    FALSE,
    NOW()
);

-- 10. VERIFICAR FCM TOKEN DEL USUARIO
SELECT 
    'FCM TOKEN STATUS' as info,
    id,
    fcm_token,
    CASE 
        WHEN fcm_token IS NOT NULL THEN 'Token disponible'
        ELSE 'Token faltante - reinicia la app'
    END as status
FROM public.users_profiles 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 11. VERIFICAR CONFIGURACIÓN DE NOTIFICACIONES
SELECT 
    'NOTIFICATION SETTINGS' as info,
    user_id,
    push_notifications_enabled,
    email_notifications_enabled,
    created_at
FROM public.notification_settings 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 12. VERIFICAR COLA DE PUSH NOTIFICATIONS
SELECT 
    'PUSH QUEUE STATUS' as info,
    COUNT(*) as total_notifications,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
    COUNT(CASE WHEN status = 'sent' THEN 1 END) as sent,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 13. MOSTRAR ÚLTIMAS NOTIFICACIONES EN COLA
SELECT 
    title,
    body,
    status,
    api_version,
    created_at,
    error_message
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
ORDER BY created_at DESC 
LIMIT 3;

-- 14. MENSAJE FINAL
SELECT '✅ ERROR FCM_TOKEN ARREGLADO - ACTUALIZA URL Y PRUEBA' as resultado;

-- INSTRUCCIONES:
-- 1. Reemplaza 'https://qjvlnqjqjqjqjqjqjqjq.supabase.co' con tu URL real
-- 2. Configura FIREBASE_SERVICE_ACCOUNT en Supabase
-- 3. Ejecuta este SQL
-- 4. ¡Debería funcionar sin errores!