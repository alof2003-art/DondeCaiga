-- =====================================================
-- NOTIFICACIÓN DE PRUEBA SÚPER ORIGINAL 🎯
-- =====================================================
-- Esta notificación es única e inconfundible para probar el sistema

-- Obtener la hora exacta para hacer la notificación única
SELECT NOW() as hora_actual;

-- Crear notificación súper original con emojis y timestamp
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
    '🚀 KIRO TESTING SYSTEM ' || TO_CHAR(NOW(), 'HH24:MI:SS'),
    '¡Hola Gabriel! 👋 Esta es tu notificación de prueba súper original creada a las ' || TO_CHAR(NOW(), 'HH24:MI:SS') || ' del ' || TO_CHAR(NOW(), 'DD/MM/YYYY') || '. Si ves esto UNA SOLA VEZ, ¡el sistema funciona perfectamente! 🎉✨',
    'kiro_test_original',
    jsonb_build_object(
        'test_id', 'KIRO_ORIGINAL_' || EXTRACT(EPOCH FROM NOW())::text,
        'created_by', 'Kiro AI Assistant',
        'purpose', 'Testing notification system',
        'should_repeat', false,
        'timestamp', NOW()::text,
        'special_emoji', '🎯🚀👋🎉✨'
    ),
    false,
    NOW()
);

-- Verificar que se creó correctamente
SELECT 
    'NOTIFICACIÓN CREADA' as status,
    title,
    LEFT(message, 50) || '...' as preview,
    type,
    created_at
FROM public.notifications 
WHERE type = 'kiro_test_original'
ORDER BY created_at DESC 
LIMIT 1;

-- Ver si se agregó a la cola de push
SELECT 
    'COLA DE PUSH' as status,
    COUNT(*) as notificaciones_pendientes,
    MAX(created_at) as ultima_creada
FROM public.push_notification_queue 
WHERE status = 'ready_for_push'
AND created_at > NOW() - INTERVAL '1 minute';

SELECT '🎯 NOTIFICACIÓN SÚPER ORIGINAL CREADA - Deberías recibirla en 10 segundos máximo' as resultado;