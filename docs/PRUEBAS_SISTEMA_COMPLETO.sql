-- =====================================================
-- PRUEBAS COMPLETAS DEL SISTEMA DE NOTIFICACIONES
-- =====================================================

-- PRUEBA 1: NOTIFICACIÓN GENERAL
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    data
) 
SELECT 
    au.id,
    '🎉 Bienvenido al Sistema Completo',
    'Tu sistema de notificaciones está funcionando perfectamente. Todas las funcionalidades están integradas.',
    'welcome',
    jsonb_build_object(
        'version', '1.0.0',
        'timestamp', NOW()::TEXT
    )
FROM auth.users au 
WHERE au.email = 'alof2003@gmail.com'
LIMIT 1;

-- PRUEBA 2: NOTIFICACIÓN DE RESERVA
SELECT notify_new_reservation(
    (SELECT id FROM auth.users WHERE email = 'alof2003@gmail.com' LIMIT 1),
    'Casa Vista al Mar',
    'María González',
    '2024-01-15'::DATE,
    uuid_generate_v4()
);

-- PRUEBA 3: NOTIFICACIÓN DE MENSAJE
SELECT notify_new_chat_message(
    (SELECT id FROM auth.users WHERE email = 'alof2003@gmail.com' LIMIT 1),
    'Carlos Rodríguez',
    'Hola, tengo una pregunta sobre la propiedad que publicas...',
    uuid_generate_v4()
);

-- PRUEBA 4: NOTIFICACIÓN DE RESEÑA
SELECT notify_new_review(
    (SELECT id FROM auth.users WHERE email = 'alof2003@gmail.com' LIMIT 1),
    'Ana Martínez',
    'Apartamento Centro Histórico',
    5,
    uuid_generate_v4()
);

-- PRUEBA 5: MÚLTIPLES NOTIFICACIONES PARA PROBAR RENDIMIENTO
DO $$
DECLARE
    user_uuid UUID;
    i INTEGER;
BEGIN
    SELECT id INTO user_uuid FROM auth.users WHERE email = 'alof2003@gmail.com' LIMIT 1;
    
    FOR i IN 1..5 LOOP
        INSERT INTO notifications (
            user_id,
            title,
            message,
            type,
            data
        ) VALUES (
            user_uuid,
            'Prueba de Rendimiento #' || i,
            'Esta es la notificación número ' || i || ' para probar el rendimiento del sistema.',
            'performance_test',
            jsonb_build_object(
                'test_number', i,
                'batch', 'performance_test',
                'timestamp', NOW()::TEXT
            )
        );
        
        -- Pequeña pausa entre notificaciones
        PERFORM pg_sleep(0.5);
    END LOOP;
END $$;

-- VERIFICAR TODAS LAS NOTIFICACIONES CREADAS
SELECT 
    id,
    title,
    message,
    type,
    data,
    read_at,
    created_at
FROM notifications 
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'alof2003@gmail.com' LIMIT 1)
ORDER BY created_at DESC 
LIMIT 10;

-- PROBAR FUNCIONES AUXILIARES

-- Obtener conteo de no leídas
SELECT get_unread_notifications_count() as unread_count;

-- Marcar una notificación como leída (reemplaza con ID real)
/*
SELECT mark_notification_as_read('uuid-de-notificacion-aqui');
*/

-- Marcar todas como leídas
/*
SELECT mark_all_notifications_as_read() as marked_count;
*/

-- VERIFICAR ESTADO DEL SISTEMA
SELECT 
    'TOTAL NOTIFICACIONES' as metric,
    COUNT(*)::TEXT as value
FROM notifications
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'alof2003@gmail.com' LIMIT 1)

UNION ALL

SELECT 
    'NO LEÍDAS' as metric,
    COUNT(*)::TEXT as value
FROM notifications
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'alof2003@gmail.com' LIMIT 1)
AND read_at IS NULL

UNION ALL

SELECT 
    'LEÍDAS' as metric,
    COUNT(*)::TEXT as value
FROM notifications
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'alof2003@gmail.com' LIMIT 1)
AND read_at IS NOT NULL

UNION ALL

SELECT 
    'TIPOS ÚNICOS' as metric,
    COUNT(DISTINCT type)::TEXT as value
FROM notifications
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'alof2003@gmail.com' LIMIT 1);

-- VERIFICAR LOGS DE TRIGGERS (en los logs de Supabase)
SELECT 
    '🔍 REVISA LOS LOGS DE LA EDGE FUNCTION' as instruccion,
    'Deberías ver logs con 🚀 para cada notificación' as detalle,
    'Si no ves logs, hay un problema con el trigger' as diagnostico;

-- LIMPIAR NOTIFICACIONES DE PRUEBA (OPCIONAL)
/*
DELETE FROM notifications 
WHERE type IN ('welcome', 'performance_test')
AND user_id = (SELECT id FROM auth.users WHERE email = 'alof2003@gmail.com' LIMIT 1);
*/