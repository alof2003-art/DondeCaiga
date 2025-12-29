-- =====================================================
-- LIMPIAR Y PROBAR SISTEMA ARREGLADO
-- =====================================================

-- PASO 1: Limpiar TODA la cola de notificaciones push
DELETE FROM public.push_notification_queue;

-- PASO 2: Verificar que esté limpia
SELECT 'COLA LIMPIA' as status, COUNT(*) as notificaciones_restantes 
FROM public.push_notification_queue;

-- PASO 3: Crear UNA notificación de prueba
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
    '🎯 PRUEBA FINAL ' || TO_CHAR(NOW(), 'HH24:MI:SS'),
    'Esta es la prueba final del sistema arreglado. Si recibes esto UNA SOLA VEZ, ¡funciona perfectamente!',
    'prueba_final',
    jsonb_build_object(
        'test_id', 'FINAL_TEST_' || EXTRACT(EPOCH FROM NOW())::text,
        'should_repeat', false
    ),
    false,
    NOW()
);

-- PASO 4: Verificar que se creó en la cola
SELECT 
    'NOTIFICACIÓN CREADA' as status,
    COUNT(*) as en_cola,
    status,
    title
FROM public.push_notification_queue 
GROUP BY status, title;

SELECT '🚀 SISTEMA ARREGLADO - Deberías recibir UNA notificación en 10 segundos máximo' as resultado;