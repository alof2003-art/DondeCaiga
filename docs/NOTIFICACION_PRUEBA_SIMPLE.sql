-- 🚀 NOTIFICACIÓN PRUEBA SIMPLE
-- Envía una notificación de prueba a tu perfil

-- PASO 1: Encontrar tu user_id (ejecuta esto primero)
SELECT id, email, nombre_completo 
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- PASO 2: Reemplaza 'TU_USER_ID_AQUI' con tu ID real y ejecuta:
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    created_at
) VALUES (
    'TU_USER_ID_AQUI',  -- 👈 Cambia esto por tu user_id
    '🎉 ¡Notificación de Prueba!',
    'Tu sistema de push notifications está funcionando correctamente. ¡Felicidades! 🚀',
    'test',
    NOW()
);

-- ALTERNATIVA: Si no sabes tu user_id, usa tu email:
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    created_at
) 
SELECT 
    au.id,
    '🎉 ¡Notificación de Prueba!',
    'Tu sistema de push notifications está funcionando correctamente. ¡Felicidades! 🚀',
    'test',
    NOW()
FROM auth.users au 
WHERE au.email = 'tu_email@gmail.com';  -- 👈 Cambia por tu email real

-- VERIFICAR QUE SE CREÓ:
SELECT * FROM notifications 
WHERE type = 'test' 
ORDER BY created_at DESC 
LIMIT 1;