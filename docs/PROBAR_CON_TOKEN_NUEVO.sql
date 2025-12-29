-- =====================================================
-- PROBAR CON TOKEN NUEVO
-- =====================================================
-- Ejecutar DESPUÉS de reiniciar la app

-- PASO 1: Verificar que se generó el token nuevo
SELECT 
    'NUEVO TOKEN' as status,
    CASE 
        WHEN fcm_token IS NOT NULL THEN '✅ Token generado: ' || LEFT(fcm_token, 30) || '...'
        ELSE '❌ Token aún no generado - Espera más tiempo'
    END as resultado
FROM public.users_profiles 
WHERE email = 'alof2003@gmail.com';

-- PASO 2: Crear notificación de prueba con token nuevo
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
    '🎉 TOKEN NUEVO ' || TO_CHAR(NOW(), 'HH24:MI:SS'),
    '¡Perfecto! Si recibes esta notificación, el sistema funciona al 100%. Token regenerado exitosamente.',
    'token_nuevo',
    jsonb_build_object(
        'test_final', true,
        'token_regenerated', true
    ),
    false,
    NOW()
);

SELECT '🎉 NOTIFICACIÓN CREADA - Deberías recibirla en 10 segundos' as resultado;