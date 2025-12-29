-- =====================================================
-- SISTEMA PARA EVITAR TOKENS FCM DUPLICADOS
-- Un dispositivo = Un usuario activo
-- =====================================================

-- FUNCIÓN PARA LIMPIAR TOKEN DE OTROS USUARIOS ANTES DE ASIGNAR
CREATE OR REPLACE FUNCTION limpiar_token_duplicado_para_usuario(
    p_user_id UUID,
    p_token TEXT
) RETURNS TEXT AS $$
DECLARE
    usuarios_afectados INTEGER;
    emails_afectados TEXT[];
BEGIN
    -- Obtener emails de usuarios que tienen este token (excepto el usuario actual)
    SELECT COUNT(*), ARRAY_AGG(email) INTO usuarios_afectados, emails_afectados
    FROM users_profiles 
    WHERE fcm_token = p_token AND id != p_user_id;
    
    IF usuarios_afectados > 0 THEN
        -- Limpiar token de otros usuarios
        UPDATE users_profiles 
        SET fcm_token = NULL, updated_at = NOW()
        WHERE fcm_token = p_token AND id != p_user_id;
        
        RETURN '🧹 Token limpiado de ' || usuarios_afectados || ' usuarios: ' || array_to_string(emails_afectados, ', ');
    ELSE
        RETURN '✅ No hay tokens duplicados que limpiar';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RETURN '❌ Error al limpiar tokens: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- FUNCIÓN PARA LIMPIAR TOKEN AL HACER LOGOUT
CREATE OR REPLACE FUNCTION limpiar_token_logout(
    p_user_id UUID
) RETURNS TEXT AS $$
BEGIN
    UPDATE users_profiles 
    SET fcm_token = NULL, updated_at = NOW()
    WHERE id = p_user_id;
    
    IF FOUND THEN
        RETURN '✅ Token limpiado para logout';
    ELSE
        RETURN '⚠️ Usuario no encontrado';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RETURN '❌ Error al limpiar token: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- FUNCIÓN PARA ASIGNAR TOKEN DE FORMA SEGURA
CREATE OR REPLACE FUNCTION asignar_token_seguro(
    p_user_id UUID,
    p_token TEXT
) RETURNS TEXT AS $$
DECLARE
    limpieza_resultado TEXT;
    usuario_email TEXT;
BEGIN
    -- Obtener email del usuario
    SELECT email INTO usuario_email FROM users_profiles WHERE id = p_user_id;
    
    IF usuario_email IS NULL THEN
        RETURN '❌ Usuario no encontrado';
    END IF;
    
    -- Paso 1: Limpiar token de otros usuarios
    SELECT limpiar_token_duplicado_para_usuario(p_user_id, p_token) INTO limpieza_resultado;
    
    -- Paso 2: Asignar token al usuario actual
    UPDATE users_profiles 
    SET fcm_token = p_token, updated_at = NOW()
    WHERE id = p_user_id;
    
    IF FOUND THEN
        RETURN '✅ Token asignado a ' || usuario_email || '. ' || limpieza_resultado;
    ELSE
        RETURN '❌ Error al asignar token a ' || usuario_email;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RETURN '❌ Error en asignación segura: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- FUNCIÓN PARA VER TOKENS DUPLICADOS
CREATE OR REPLACE FUNCTION ver_tokens_duplicados() RETURNS TABLE(
    token_preview TEXT,
    usuarios_count INTEGER,
    usuarios_emails TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        LEFT(fcm_token, 30) || '...' as token_preview,
        COUNT(*)::INTEGER as usuarios_count,
        ARRAY_AGG(email) as usuarios_emails
    FROM users_profiles 
    WHERE fcm_token IS NOT NULL
    GROUP BY fcm_token
    HAVING COUNT(*) > 1
    ORDER BY COUNT(*) DESC;
END;
$$ LANGUAGE plpgsql;

-- FUNCIÓN PARA VER ESTADO ACTUAL DE TOKENS
CREATE OR REPLACE FUNCTION ver_estado_tokens() RETURNS TABLE(
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
    ORDER BY up.updated_at DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PRUEBAS DEL SISTEMA
-- =====================================================

-- Ver estado actual
SELECT * FROM ver_estado_tokens();

-- Ver tokens duplicados
SELECT * FROM ver_tokens_duplicados();

-- Probar asignación segura (cambiar por tu user_id real)
-- SELECT asignar_token_seguro(
--     '58e28dd4-b952-4176-9753-21edd24bccae'::uuid,
--     'token_prueba_' || EXTRACT(EPOCH FROM NOW())::text
-- );

-- Probar limpieza de logout
-- SELECT limpiar_token_logout('58e28dd4-b952-4176-9753-21edd24bccae'::uuid);