-- =====================================================
-- PRUEBA BÁSICA DEL SISTEMA FCM TOKEN
-- Sin triggers, sin complicaciones
-- =====================================================

-- PASO 1: Ver estado actual de todos los usuarios
SELECT * FROM ver_tokens_usuarios();

-- PASO 2: Limpiar token del usuario de prueba
SELECT limpiar_token_usuario('alof2003@gmail.com');

-- PASO 3: Ver estado después de limpiar
SELECT * FROM ver_tokens_usuarios() WHERE email = 'alof2003@gmail.com';

-- PASO 4: Simular que Flutter actualiza el token
SELECT actualizar_token_fcm_basico(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'token_flutter_basico_' || EXTRACT(EPOCH FROM NOW())::text
);

-- PASO 5: Ver resultado final
SELECT * FROM ver_tokens_usuarios() WHERE email = 'alof2003@gmail.com';

-- PASO 6: Limpiar tokens duplicados si los hay
SELECT limpiar_tokens_duplicados_manual();

-- PASO 7: Verificar que no hay duplicados
SELECT 
    fcm_token,
    COUNT(*) as usuarios_count,
    ARRAY_AGG(email) as emails
FROM users_profiles 
WHERE fcm_token IS NOT NULL
GROUP BY fcm_token
HAVING COUNT(*) > 1;