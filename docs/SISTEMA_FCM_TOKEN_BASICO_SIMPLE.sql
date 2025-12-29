-- =====================================================
-- SISTEMA FCM TOKEN BÁSICO Y SIMPLE
-- Sin triggers, sin complicaciones, solo lo esencial
-- =====================================================

-- PASO 1: Eliminar todos los triggers relacionados con FCM tokens
DROP TRIGGER IF EXISTS trigger_reemplazar_token_fcm ON users_profiles;
DROP TRIGGER IF EXISTS trigger_reemplazar_token_fcm_simple ON users_profiles;
DROP FUNCTION IF EXISTS trigger_reemplazar_token_fcm();
DROP FUNCTION IF EXISTS trigger_reemplazar_token_fcm_simple();

-- PASO 2: Función súper simple para actualizar token
CREATE OR REPLACE FUNCTION actualizar_token_fcm_basico(
    p_user_id UUID,
    p_new_token TEXT
) RETURNS TEXT AS $$
BEGIN
    -- Simplemente actualizar el token del usuario
    UPDATE users_profiles 
    SET fcm_token = p_new_token, updated_at = NOW()
    WHERE id = p_user_id;
    
    IF FOUND THEN
        RETURN '✅ Token FCM actualizado correctamente';
    ELSE
        RETURN '❌ Usuario no encontrado';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RETURN '❌ Error: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- PASO 3: Función para limpiar token de un usuario específico
CREATE OR REPLACE FUNCTION limpiar_token_usuario(user_email TEXT) RETURNS TEXT AS $$
DECLARE
    target_user_id UUID;
BEGIN
    -- Buscar usuario por email
    SELECT id INTO target_user_id
    FROM users_profiles 
    WHERE email = user_email;
    
    IF target_user_id IS NULL THEN
        RETURN '❌ Usuario no encontrado: ' || user_email;
    END IF;
    
    -- Limpiar token
    UPDATE users_profiles 
    SET fcm_token = NULL, updated_at = NOW()
    WHERE id = target_user_id;
    
    RETURN '✅ Token limpiado para ' || user_email;
END;
$$ LANGUAGE plpgsql;

-- PASO 4: Función para ver tokens actuales
CREATE OR REPLACE FUNCTION ver_tokens_usuarios() RETURNS TABLE(
    email TEXT,
    tiene_token BOOLEAN,
    token_preview TEXT,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        up.email,
        (up.fcm_token IS NOT NULL) as tiene_token,
        CASE 
            WHEN up.fcm_token IS NOT NULL THEN LEFT(up.fcm_token, 30) || '...'
            ELSE 'NULL'
        END as token_preview,
        up.updated_at
    FROM users_profiles up
    ORDER BY up.email;
END;
$$ LANGUAGE plpgsql;

-- PASO 5: Función para limpiar tokens duplicados manualmente
CREATE OR REPLACE FUNCTION limpiar_tokens_duplicados_manual() RETURNS TEXT AS $$
DECLARE
    duplicados_count INTEGER;
BEGIN
    -- Encontrar y limpiar tokens duplicados (mantener solo el más reciente)
    WITH tokens_duplicados AS (
        SELECT 
            fcm_token,
            COUNT(*) as count,
            MAX(updated_at) as max_updated
        FROM users_profiles 
        WHERE fcm_token IS NOT NULL
        GROUP BY fcm_token
        HAVING COUNT(*) > 1
    )
    UPDATE users_profiles 
    SET fcm_token = NULL, updated_at = NOW()
    WHERE fcm_token IN (SELECT fcm_token FROM tokens_duplicados)
    AND updated_at < (
        SELECT max_updated 
        FROM tokens_duplicados td 
        WHERE td.fcm_token = users_profiles.fcm_token
    );
    
    GET DIAGNOSTICS duplicados_count = ROW_COUNT;
    
    RETURN '✅ Limpiados ' || duplicados_count || ' tokens duplicados';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PRUEBAS BÁSICAS
-- =====================================================

-- Ver estado actual
SELECT * FROM ver_tokens_usuarios();

-- Limpiar token de un usuario específico
-- SELECT limpiar_token_usuario('alof2003@gmail.com');

-- Probar actualización básica
-- SELECT actualizar_token_fcm_basico(
--     '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
--     'token_prueba_basico_' || EXTRACT(EPOCH FROM NOW())::text
-- );