-- ========================================
-- DIAGNOSTICAR FCM TOKENS DUPLICADOS
-- ========================================

-- PASO 1: BUSCAR TOKENS DUPLICADOS
SELECT 
    'TOKENS DUPLICADOS ENCONTRADOS' as problema,
    fcm_token,
    COUNT(*) as usuarios_con_mismo_token,
    STRING_AGG(email, ', ') as emails_afectados
FROM users_profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != ''
GROUP BY fcm_token
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- PASO 2: VER TODOS LOS TOKENS ÚNICOS VS DUPLICADOS
SELECT 
    'ESTADÍSTICAS FCM TOKENS' as info,
    COUNT(DISTINCT fcm_token) as tokens_unicos,
    COUNT(*) as total_usuarios_con_token,
    COUNT(*) - COUNT(DISTINCT fcm_token) as tokens_duplicados
FROM users_profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != '';

-- PASO 3: VER DETALLES DE USUARIOS CON TOKENS
SELECT 
    email,
    nombre,
    LEFT(fcm_token, 40) || '...' as token_preview,
    created_at,
    updated_at
FROM users_profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != ''
ORDER BY fcm_token, created_at;

-- PASO 4: FUNCIÓN PARA LIMPIAR TOKENS DUPLICADOS
CREATE OR REPLACE FUNCTION limpiar_tokens_duplicados()
RETURNS TEXT AS $$
DECLARE
    duplicate_record RECORD;
    tokens_limpiados INTEGER := 0;
BEGIN
    -- Para cada token duplicado, mantener solo el más reciente
    FOR duplicate_record IN 
        SELECT fcm_token
        FROM users_profiles 
        WHERE fcm_token IS NOT NULL AND fcm_token != ''
        GROUP BY fcm_token
        HAVING COUNT(*) > 1
    LOOP
        -- Limpiar tokens de usuarios más antiguos, mantener el más reciente
        UPDATE users_profiles 
        SET fcm_token = NULL
        WHERE fcm_token = duplicate_record.fcm_token
        AND id NOT IN (
            SELECT id FROM users_profiles 
            WHERE fcm_token = duplicate_record.fcm_token
            ORDER BY updated_at DESC 
            LIMIT 1
        );
        
        GET DIAGNOSTICS tokens_limpiados = tokens_limpiados + ROW_COUNT;
    END LOOP;
    
    RETURN '✅ Limpiados ' || tokens_limpiados || ' tokens duplicados. Los usuarios afectados deben reabrir la app.';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 5: FUNCIÓN PARA FORZAR REGENERACIÓN DE TOKEN
CREATE OR REPLACE FUNCTION forzar_regeneracion_token(user_email TEXT)
RETURNS TEXT AS $$
DECLARE
    target_user_id UUID;
BEGIN
    -- Buscar usuario
    SELECT id INTO target_user_id
    FROM users_profiles 
    WHERE email = user_email;
    
    IF target_user_id IS NULL THEN
        RETURN '❌ Usuario no encontrado: ' || user_email;
    END IF;
    
    -- Limpiar token actual
    UPDATE users_profiles 
    SET fcm_token = NULL, updated_at = NOW()
    WHERE id = target_user_id;
    
    RETURN '✅ Token limpiado para ' || user_email || '. Debe reabrir la app para generar uno nuevo.';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 6: EJECUTAR DIAGNÓSTICO
SELECT 'EJECUTANDO DIAGNÓSTICO...' as status;

-- Ver si hay duplicados
SELECT * FROM (
    SELECT 
        fcm_token,
        COUNT(*) as usuarios_con_mismo_token,
        STRING_AGG(email, ', ') as emails_afectados
    FROM users_profiles 
    WHERE fcm_token IS NOT NULL AND fcm_token != ''
    GROUP BY fcm_token
    HAVING COUNT(*) > 1
) duplicados;