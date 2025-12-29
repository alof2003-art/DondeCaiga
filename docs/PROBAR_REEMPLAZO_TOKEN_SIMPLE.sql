-- =====================================================
-- PRUEBA SIMPLE DEL SISTEMA DE REEMPLAZO DE TOKENS FCM
-- Solo usa users_profiles.fcm_token (NO device_tokens)
-- =====================================================

-- PASO 1: Ver estado actual de tokens
SELECT 
    'Estado Actual' as paso,
    email,
    CASE 
        WHEN fcm_token IS NOT NULL THEN LEFT(fcm_token, 30) || '...'
        ELSE 'NULL'
    END as token_preview
FROM users_profiles 
WHERE email IN ('alof2003@gmail.com', 'gabriel@example.com', 'myrian@example.com')
ORDER BY email;

-- PASO 2: Simular que Flutter actualiza el token de alof2003@gmail.com
UPDATE users_profiles 
SET fcm_token = 'nuevo_token_flutter_' || EXTRACT(EPOCH FROM NOW())::text
WHERE email = 'alof2003@gmail.com';

-- PASO 3: Ver resultado después de la actualización (el trigger limpia duplicados)
SELECT 
    'Después de Actualización' as paso,
    email,
    CASE 
        WHEN fcm_token IS NOT NULL THEN LEFT(fcm_token, 30) || '...'
        ELSE 'NULL - Token limpiado por trigger'
    END as token_preview
FROM users_profiles 
WHERE email IN ('alof2003@gmail.com', 'gabriel@example.com', 'myrian@example.com')
ORDER BY email;

-- PASO 4: Verificar que no hay tokens duplicados
SELECT 
    'Verificación Final' as paso,
    LEFT(fcm_token, 30) || '...' as token_preview,
    COUNT(*) as usuarios_con_este_token,
    ARRAY_AGG(email) as emails
FROM users_profiles 
WHERE fcm_token IS NOT NULL
GROUP BY fcm_token
HAVING COUNT(*) > 1;

-- PASO 5: Probar función simple
SELECT actualizar_fcm_token_simple(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'token_prueba_funcion_' || EXTRACT(EPOCH FROM NOW())::text
);

-- PASO 6: Forzar regeneración de token para un usuario
SELECT forzar_nuevo_token_usuario('alof2003@gmail.com');

-- PASO 7: Estado final
SELECT 
    'Estado Final' as paso,
    email,
    CASE 
        WHEN fcm_token IS NOT NULL THEN LEFT(fcm_token, 30) || '...'
        ELSE 'NULL - Listo para nuevo token'
    END as token_preview
FROM users_profiles 
WHERE email = 'alof2003@gmail.com';