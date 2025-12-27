-- =====================================================
-- ACTIVAR PUSH NOTIFICATIONS CON TU EDGE FUNCTION
-- =====================================================

-- 1. FUNCIÓN PARA ENVIAR PUSH USANDO TU EDGE FUNCTION
CREATE OR REPLACE FUNCTION send_push_notification_final(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT,
    p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS BOOLEAN AS $$
DECLARE
    fcm_token TEXT;
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
    
    -- Obtener el token FCM del usuario
    SELECT fcm_token INTO fcm_token 
    FROM public.users_profiles 
    WHERE id = p_user_id AND fcm_token IS NOT NULL;
    
    -- Si no tiene token FCM, no se puede enviar push
    IF fcm_token IS NULL THEN
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
                'fcm_token', fcm_token,
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
            fcm_token,
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
            fcm_token,
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

-- 2. ACTUALIZAR TRIGGER PARA USAR TU FUNCIÓN
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
CREATE TRIGGER trigger_auto_push_notification_final
    AFTER INSERT ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION trigger_send_push_notification_final();

-- 4. ACTUALIZAR TABLA DE COLA SI NO EXISTE
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

-- 8. CONFIGURAR VARIABLE DE SUPABASE ANON KEY (REEMPLAZA CON TU CLAVE REAL)
-- Nota: Esto debe configurarse en el dashboard de Supabase como variable de entorno
-- ALTER DATABASE postgres SET app.supabase_anon_key = 'tu-anon-key-aqui';

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
    'Push Notifications Activadas 🚀',
    'Tu Edge Function con Google Auth está funcionando perfectamente',
    'general',
    '{"edge_function": "google_auth", "test": true}'::jsonb,
    FALSE,
    NOW()
);

-- 10. VERIFICAR ESTADO DE LA COLA
SELECT 
    'PUSH NOTIFICATIONS STATUS' as info,
    COUNT(*) as total_notifications,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
    COUNT(CASE WHEN status = 'sent' THEN 1 END) as sent,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 11. MOSTRAR ÚLTIMAS NOTIFICACIONES
SELECT 
    id,
    title,
    body,
    status,
    api_version,
    created_at,
    sent_at,
    error_message
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
ORDER BY created_at DESC 
LIMIT 5;

-- 12. FUNCIÓN PARA PROBAR MANUALMENTE
CREATE OR REPLACE FUNCTION test_push_notification(p_user_id UUID)
RETURNS TEXT AS $$
DECLARE
    result BOOLEAN;
BEGIN
    SELECT send_push_notification_final(
        p_user_id,
        'Prueba Manual 🧪',
        'Esta es una notificación de prueba enviada manualmente'
    ) INTO result;
    
    IF result THEN
        RETURN 'Push notification enviada exitosamente';
    ELSE
        RETURN 'Error: No se pudo enviar la push notification';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 13. MENSAJE FINAL
SELECT '✅ PUSH NOTIFICATIONS CON GOOGLE AUTH CONFIGURADAS - ACTUALIZA URL EN FUNCIÓN' as resultado;

-- INSTRUCCIONES FINALES:
-- 1. Reemplaza 'https://qjvlnqjqjqjqjqjqjqjq.supabase.co' con tu URL real de Supabase
-- 2. Configura FIREBASE_SERVICE_ACCOUNT en variables de entorno de Supabase
-- 3. Configura app.supabase_anon_key en variables de entorno
-- 4. Ejecuta este SQL
-- 5. ¡Las push notifications funcionarán automáticamente!