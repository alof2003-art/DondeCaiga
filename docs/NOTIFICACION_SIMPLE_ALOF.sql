-- ========================================
-- NOTIFICACIÓN SIMPLE PARA ALOF
-- Versión sin errores de sintaxis
-- ========================================

-- PASO 1: Ver datos de alof
SELECT 
    'DATOS USUARIO' as info,
    id,
    email,
    nombre,
    CASE 
        WHEN fcm_token IS NOT NULL AND fcm_token != '' 
        THEN 'Token OK'
        ELSE 'Sin token'
    END as token_status
FROM users_profiles 
WHERE email = 'alof2003@gmail.com';

-- PASO 2: Crear notificación directa
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    is_read,
    created_at
) 
SELECT 
    id,
    'Prueba Push Alof',
    'Notificacion de prueba - Si recibes esto funciona!',
    'test',
    FALSE,
    NOW()
FROM users_profiles 
WHERE email = 'alof2003@gmail.com';

-- PASO 3: Verificar que se creó
SELECT 
    'NOTIFICACION CREADA' as resultado,
    n.id,
    n.title,
    n.message,
    n.created_at,
    up.email
FROM notifications n
JOIN users_profiles up ON n.user_id = up.id
WHERE up.email = 'alof2003@gmail.com'
ORDER BY n.created_at DESC
LIMIT 1;