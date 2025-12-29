-- PRUEBA RÁPIDA DEL SISTEMA DE NOTIFICACIONES PUSH
-- Para usuario: alof2003@gmail.com
-- Ejecutar en Supabase SQL Editor

-- 1. Verificar que el usuario existe y tiene FCM token
SELECT 
    'Usuario y Token' as verificacion,
    CASE 
        WHEN id IS NOT NULL AND fcm_token IS NOT NULL THEN '✅ USUARIO CON TOKEN'
        WHEN id IS NOT NULL AND fcm_token IS NULL THEN '❌ USUARIO SIN TOKEN'
        ELSE '❌ USUARIO NO ENCONTRADO'
    END as estado,
    LEFT(COALESCE(fcm_token, 'NULL'), 30) || '...' as token_preview
FROM users_profiles 
WHERE email = 'alof2003@gmail.com';

-- 2. Verificar que el trigger existe
SELECT 
    'Trigger Push' as verificacion,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ TRIGGER ACTIVO'
        ELSE '❌ TRIGGER FALTANTE'
    END as estado,
    'trigger_send_push_on_notification' as trigger_name
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_send_push_on_notification'
AND event_manipulation = 'INSERT';

-- 3. ENVIAR NOTIFICACIÓN DE PRUEBA
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
    '🔔 Prueba Sistema Push',
    'Si recibes esto en tu celular, el sistema funciona perfectamente! ' || NOW()::text,
    'test',
    FALSE,
    NOW()
FROM users_profiles 
WHERE email = 'alof2003@gmail.com';

-- 4. Verificar que se creó la notificación
SELECT 
    'Notificación Creada' as verificacion,
    '✅ NOTIFICACIÓN ENVIADA' as estado,
    'Revisa tu celular en 10 segundos' as instruccion
FROM notifications 
WHERE user_id = (SELECT id FROM users_profiles WHERE email = 'alof2003@gmail.com')
AND created_at > NOW() - INTERVAL '1 minute'
ORDER BY created_at DESC 
LIMIT 1;