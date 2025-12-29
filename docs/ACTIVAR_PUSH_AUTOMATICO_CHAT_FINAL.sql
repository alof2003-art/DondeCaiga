-- =====================================================
-- ACTIVAR PUSH AUTOMÁTICO PARA CHAT - FINAL
-- =====================================================
-- Conectar notificaciones de chat con push notifications

-- 1. Crear trigger para enviar push cuando se crea notificación
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON public.notifications;
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON public.notifications
    FOR EACH ROW
    EXECUTE FUNCTION trigger_send_push_simple();

-- 2. Verificar que el trigger existe
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_send_push_on_notification';

-- 3. Probar el flujo completo: Mensaje → Notificación → Push
-- Simular un mensaje nuevo (reemplaza los UUIDs con usuarios reales)
INSERT INTO public.mensajes (
    reserva_id,
    remitente_id,
    mensaje
) VALUES (
    (SELECT id FROM reservas LIMIT 1),  -- Primera reserva disponible
    (SELECT viajero_id FROM reservas LIMIT 1),  -- Remitente
    'Mensaje de prueba para activar push notification automática 🚀'
);

-- 4. Verificar que se creó la notificación
SELECT 
    'Notificación creada' as resultado,
    user_id,
    title,
    message,
    created_at
FROM notifications 
WHERE created_at > NOW() - INTERVAL '1 minute'
ORDER BY created_at DESC 
LIMIT 1;

-- 5. Verificar que se agregó a la cola de push
SELECT 
    'Push en cola' as resultado,
    title,
    body,
    status,
    created_at
FROM push_notification_queue 
WHERE created_at > NOW() - INTERVAL '1 minute'
ORDER BY created_at DESC 
LIMIT 1;

-- =====================================================
-- FLUJO COMPLETO ACTIVADO:
-- 1. Usuario envía mensaje → trigger_notificacion_mensaje
-- 2. Se crea notificación → trigger_send_push_on_notification  
-- 3. Se envía push notification → Edge Function
-- 4. Usuario recibe notificación en su celular
-- =====================================================