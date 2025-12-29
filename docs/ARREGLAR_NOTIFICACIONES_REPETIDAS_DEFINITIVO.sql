-- =====================================================
-- ARREGLAR NOTIFICACIONES REPETIDAS - DEFINITIVO
-- =====================================================
-- Problema: Las notificaciones se repiten infinitamente porque:
-- 1. El trigger está en AFTER UPDATE en lugar de AFTER INSERT
-- 2. Las notificaciones no se marcan como enviadas correctamente

-- PASO 1: Arreglar el trigger principal
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON public.notifications;

-- Crear trigger correcto para AFTER INSERT (cuando se crea una notificación nueva)
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

-- CREAR TRIGGER CORRECTO PARA INSERT (no UPDATE)
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON public.notifications  -- ✅ CAMBIO CRÍTICO: INSERT no UPDATE
    FOR EACH ROW
    EXECUTE FUNCTION trigger_send_push_flutter();

-- PASO 2: Limpiar notificaciones duplicadas en cola
DELETE FROM public.push_notification_queue 
WHERE status = 'ready_for_push' 
AND created_at < NOW() - INTERVAL '1 minute';

-- PASO 3: Mejorar la función que marca como enviada
CREATE OR REPLACE FUNCTION mark_push_notification_sent(notification_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE public.push_notification_queue 
    SET 
        status = 'sent',
        sent_at = NOW(),
        attempts = attempts + 1
    WHERE id = notification_id
    AND status = 'ready_for_push';  -- Solo actualizar si está pendiente
    
    -- Retornar TRUE si se actualizó alguna fila
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- PASO 4: Verificar que todo esté correcto
SELECT 'VERIFICACIÓN DE TRIGGERS' as info;

-- Ver el trigger corregido
SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_send_push_on_notification';

-- Ver notificaciones en cola
SELECT 
    COUNT(*) as total_en_cola,
    status,
    COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '5 minutes') as ultimos_5_min
FROM public.push_notification_queue 
GROUP BY status;

-- PASO 5: Probar con una notificación nueva
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
    'PRUEBA ARREGLADA ✅',
    'Esta notificación NO debería repetirse',
    'test',
    '{}'::jsonb,
    false,
    NOW()
);

SELECT 'TRIGGER ARREGLADO - Ahora debería funcionar correctamente' as resultado;