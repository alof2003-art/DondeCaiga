-- =====================================================
-- PUSH NOTIFICATIONS SIMPLE - SIN ERRORES
-- =====================================================

-- 1. CREAR TABLA SIMPLE DE COLA (SIN API_VERSION)
CREATE TABLE IF NOT EXISTS public.push_notification_queue (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'failed')),
    attempts INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    http_request_id BIGINT
);

-- 2. FUNCIÓN SIMPLE PARA ENVIAR PUSH
CREATE OR REPLACE FUNCTION send_push_notification_simple(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT
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
    
    -- Obtener el token FCM del usuario
    SELECT up.fcm_token INTO user_fcm_token
    FROM public.users_profiles up
    WHERE up.id = p_user_id AND up.fcm_token IS NOT NULL;
    
    -- Si no tiene token FCM, no se puede enviar push
    IF user_fcm_token IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Registrar en cola (sin llamar a Edge Function por ahora)
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
        'pending'
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. TRIGGER SIMPLE
CREATE OR REPLACE FUNCTION trigger_send_push_simple()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo enviar push para notificaciones nuevas (no leídas)
    IF NEW.is_read = FALSE THEN
        PERFORM send_push_notification_simple(
            NEW.user_id,
            NEW.title,
            NEW.message
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. LIMPIAR TRIGGERS ANTERIORES Y CREAR NUEVO
DROP TRIGGER IF EXISTS trigger_auto_push_notification ON public.notifications;
DROP TRIGGER IF EXISTS trigger_auto_push_notification_v1 ON public.notifications;
DROP TRIGGER IF EXISTS trigger_auto_push_notification_final ON public.notifications;

CREATE TRIGGER trigger_auto_push_simple
    AFTER INSERT ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION trigger_send_push_simple();

-- 5. CREAR ÍNDICES
CREATE INDEX IF NOT EXISTS idx_push_queue_status ON public.push_notification_queue(status);
CREATE INDEX IF NOT EXISTS idx_push_queue_user_id ON public.push_notification_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_push_queue_created_at ON public.push_notification_queue(created_at);

-- 6. HABILITAR RLS
ALTER TABLE public.push_notification_queue ENABLE ROW LEVEL SECURITY;

-- 7. CREAR POLÍTICA RLS
DROP POLICY IF EXISTS "Users can view their own push notifications" ON public.push_notification_queue;
CREATE POLICY "Users can view their own push notifications" ON public.push_notification_queue 
    FOR SELECT USING (user_id = auth.uid());

-- 8. FUNCIÓN PARA PROCESAR COLA MANUALMENTE
CREATE OR REPLACE FUNCTION process_push_queue_manual()
RETURNS TABLE(
    notification_id UUID,
    fcm_token TEXT,
    title TEXT,
    body TEXT,
    status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pnq.id,
        pnq.fcm_token,
        pnq.title,
        pnq.body,
        pnq.status
    FROM public.push_notification_queue pnq
    WHERE pnq.status = 'pending'
    ORDER BY pnq.created_at ASC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
    'Sistema Simple Activado ✅',
    'Las notificaciones push están en cola y listas para procesar',
    'general',
    '{"simple_version": true}'::jsonb,
    FALSE,
    NOW()
);

-- 10. VERIFICAR FCM TOKEN
SELECT 
    'FCM TOKEN CHECK' as info,
    id,
    CASE 
        WHEN fcm_token IS NOT NULL THEN 'Token disponible ✅'
        ELSE 'Token faltante ❌ - Reinicia la app'
    END as token_status,
    LEFT(fcm_token, 20) || '...' as token_preview
FROM public.users_profiles 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 11. VERIFICAR CONFIGURACIÓN
SELECT 
    'NOTIFICATION SETTINGS' as info,
    user_id,
    push_notifications_enabled,
    email_notifications_enabled
FROM public.notification_settings 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 12. VERIFICAR COLA
SELECT 
    'PUSH QUEUE STATUS' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
    COUNT(CASE WHEN status = 'sent' THEN 1 END) as sent,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 13. MOSTRAR NOTIFICACIONES EN COLA
SELECT 
    'NOTIFICATIONS IN QUEUE' as info,
    title,
    body,
    status,
    created_at,
    error_message
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
ORDER BY created_at DESC 
LIMIT 5;

-- 14. FUNCIÓN PARA PROBAR MANUALMENTE
CREATE OR REPLACE FUNCTION test_push_simple()
RETURNS TEXT AS $$
DECLARE
    result BOOLEAN;
BEGIN
    SELECT send_push_notification_simple(
        '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
        'Prueba Manual 🧪',
        'Esta es una prueba del sistema simplificado'
    ) INTO result;
    
    IF result THEN
        RETURN '✅ Notificación agregada a la cola exitosamente';
    ELSE
        RETURN '❌ Error: Verifica FCM token y configuración';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 15. EJECUTAR PRUEBA
SELECT test_push_simple() as test_result;

-- 16. MENSAJE FINAL
SELECT '✅ SISTEMA SIMPLE CONFIGURADO - NOTIFICACIONES EN COLA PARA PROCESAR' as resultado;

-- PRÓXIMOS PASOS:
-- 1. Ejecuta este SQL (debería funcionar sin errores)
-- 2. Verifica que las notificaciones aparezcan en la cola
-- 3. Luego configuramos tu Edge Function para procesar la cola
-- 4. ¡Las push notifications funcionarán automáticamente!