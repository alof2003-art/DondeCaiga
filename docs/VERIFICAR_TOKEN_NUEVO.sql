-- =====================================================
-- VERIFICAR TOKEN NUEVO
-- =====================================================

-- Verificar si se generó el token FCM
SELECT 
    email,
    CASE 
        WHEN fcm_token IS NULL THEN '❌ TOKEN NULL - Firebase no inicializó'
        WHEN LENGTH(fcm_token) < 100 THEN '⚠️ TOKEN TRUNCADO - ' || LENGTH(fcm_token) || ' chars'
        ELSE '✅ TOKEN VÁLIDO - ' || LENGTH(fcm_token) || ' chars'
    END as estado_token,
    LEFT(fcm_token, 50) || '...' as preview_token
FROM public.users_profiles 
WHERE email = 'alof2003@gmail.com';

-- Si el token es válido, crear notificación de prueba
INSERT INTO public.notifications (
    user_id,
    title,
    message,
    type,
    metadata,
    is_read,
    created_at
) 
SELECT 
    id,
    '🎉 TOKEN VÁLIDO ' || TO_CHAR(NOW(), 'HH24:MI:SS'),
    '¡Perfecto Gabriel! Firebase se inicializó correctamente y generó un token válido. Las notificaciones push deberían funcionar ahora.',
    'token_valido',
    jsonb_build_object('token_length', LENGTH(fcm_token)),
    false,
    NOW()
FROM public.users_profiles 
WHERE email = 'alof2003@gmail.com'
AND fcm_token IS NOT NULL
AND LENGTH(fcm_token) > 100;

SELECT '🔍 Verifica el estado del token arriba' as resultado;