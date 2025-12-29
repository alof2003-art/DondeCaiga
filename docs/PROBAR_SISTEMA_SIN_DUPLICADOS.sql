-- =====================================================
-- PRUEBA DEL SISTEMA SIN TOKENS DUPLICADOS
-- =====================================================

-- PASO 1: Ver estado inicial
SELECT '=== ESTADO INICIAL ===' as paso;
SELECT * FROM ver_estado_tokens();

-- PASO 2: Ver si hay tokens duplicados
SELECT '=== TOKENS DUPLICADOS ACTUALES ===' as paso;
SELECT * FROM ver_tokens_duplicados();

-- PASO 3: Simular login de usuario 1 (Myrian)
SELECT '=== SIMULANDO LOGIN USUARIO 1 (MYRIAN) ===' as paso;
SELECT asignar_token_seguro(
    '58e28dd4-b952-4176-9753-21edd24bccae'::uuid,
    'token_dispositivo_compartido_12345'
);

-- PASO 4: Ver estado después del login de usuario 1
SELECT '=== ESTADO DESPUÉS LOGIN USUARIO 1 ===' as paso;
SELECT * FROM ver_estado_tokens() WHERE email IN ('mpattydaquilema@gmail.com', 'alof2003@gmail.com');

-- PASO 5: Simular login de usuario 2 (Alof) en el MISMO dispositivo
SELECT '=== SIMULANDO LOGIN USUARIO 2 (ALOF) - MISMO DISPOSITIVO ===' as paso;
SELECT asignar_token_seguro(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'token_dispositivo_compartido_12345'  -- MISMO TOKEN
);

-- PASO 6: Ver estado después del login de usuario 2
SELECT '=== ESTADO DESPUÉS LOGIN USUARIO 2 ===' as paso;
SELECT * FROM ver_estado_tokens() WHERE email IN ('mpattydaquilema@gmail.com', 'alof2003@gmail.com');

-- PASO 7: Verificar que no hay tokens duplicados
SELECT '=== VERIFICAR NO HAY DUPLICADOS ===' as paso;
SELECT * FROM ver_tokens_duplicados();

-- PASO 8: Simular logout de usuario 2
SELECT '=== SIMULANDO LOGOUT USUARIO 2 ===' as paso;
SELECT limpiar_token_logout('0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid);

-- PASO 9: Ver estado final
SELECT '=== ESTADO FINAL ===' as paso;
SELECT * FROM ver_estado_tokens() WHERE email IN ('mpattydaquilema@gmail.com', 'alof2003@gmail.com');

-- PASO 10: Resumen final
SELECT '=== RESUMEN FINAL ===' as paso;
SELECT 
    COUNT(*) as total_usuarios_con_token,
    COUNT(DISTINCT fcm_token) as tokens_unicos
FROM users_profiles 
WHERE fcm_token IS NOT NULL;