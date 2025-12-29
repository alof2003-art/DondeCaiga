-- =====================================================
-- ARREGLAR FCM TOKEN DEFINITIVO FINAL
-- =====================================================
-- Tu token está NULL, necesitamos forzar que la app lo genere

-- PASO 1: Verificar el estado actual
SELECT 
    email,
    CASE 
        WHEN fcm_token IS NULL THEN '❌ TOKEN NULL'
        ELSE '✅ TOKEN EXISTE: ' || LEFT(fcm_token, 30) || '...'
    END as estado_token
FROM public.users_profiles 
WHERE email = 'alof2003@gmail.com';

-- PASO 2: Limpiar completamente las notificaciones pendientes
DELETE FROM public.push_notification_queue 
WHERE user_id = (SELECT id FROM users_profiles WHERE email = 'alof2003@gmail.com');

-- PASO 3: Insertar un token de prueba temporal para verificar el sistema
UPDATE public.users_profiles 
SET fcm_token = 'dBBoXVPqRYicD953mTmy8K:APA91bG4V'  -- Token de otro usuario para probar
WHERE email = 'alof2003@gmail.com';

-- PASO 4: Crear notificación de prueba con token válido
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
    '🧪 PRUEBA CON TOKEN VÁLIDO ' || TO_CHAR(NOW(), 'HH24:MI:SS'),
    'Esta prueba usa un token FCM válido de otro usuario para verificar que el sistema funciona',
    'prueba_token_valido',
    jsonb_build_object('test_with_valid_token', true),
    false,
    NOW()
);

-- PASO 5: Verificar que se creó correctamente
SELECT 
    'PRUEBA CREADA' as status,
    COUNT(*) as notificaciones_en_cola
FROM public.push_notification_queue 
WHERE user_id = (SELECT id FROM users_profiles WHERE email = 'alof2003@gmail.com')
AND status = 'pending';

SELECT '🧪 PRUEBA CON TOKEN VÁLIDO CREADA - Si funciona, el problema es que tu app no genera el token' as resultado;