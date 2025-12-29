-- =====================================================
-- PRUEBAS SIMPLES DEL SISTEMA
-- =====================================================

-- PRUEBA 1: Notificación simple
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    created_at
) 
SELECT 
    au.id,
    '🎉 Sistema Funcionando',
    'Tu sistema de notificaciones push está activo y funcionando correctamente.',
    'system_test',
    NOW()
FROM auth.users au 
WHERE au.email = 'alof2003@gmail.com'
LIMIT 1;

-- PRUEBA 2: Notificación de reserva (usando función si existe)
SELECT notify_new_reservation(
    (SELECT id FROM auth.users WHERE email = 'alof2003@gmail.com' LIMIT 1),
    'Casa Vista al Mar',
    'María González',
    '2024-01-15'::DATE,
    uuid_generate_v4()
);

-- PRUEBA 3: Notificación de mensaje (usando función si existe)
SELECT notify_new_chat_message(
    (SELECT id FROM auth.users WHERE email = 'alof2003@gmail.com' LIMIT 1),
    'Carlos Rodríguez',
    'Hola, tengo una pregunta sobre tu propiedad...',
    uuid_generate_v4()
);

-- VERIFICAR NOTIFICACIONES CREADAS
SELECT 
    id,
    title,
    message,
    type,
    read_at,
    created_at
FROM notifications 
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'alof2003@gmail.com' LIMIT 1)
ORDER BY created_at DESC 
LIMIT 5;

-- VERIFICAR CONTEO DE NO LEÍDAS
SELECT get_unread_notifications_count() as unread_count;