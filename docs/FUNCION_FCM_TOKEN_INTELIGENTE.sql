-- FUNCIÓN PARA ACTUALIZAR FCM TOKENS DE FORMA INTELIGENTE
-- Maneja tokens duplicados y actualización automática
-- Ejecutar en Supabase SQL Editor

CREATE OR REPLACE FUNCTION actualizar_fcm_token_inteligente(
    p_user_id UUID,
    p_new_token TEXT
) RETURNS TEXT AS $$
DECLARE
    old_token TEXT;
    tokens_duplicados INTEGER;
    usuarios_afectados TEXT[];
BEGIN
    -- Obtener token actual del usuario
    SELECT fcm_token INTO old_token
    FROM users_profiles 
    WHERE id = p_user_id;
    
    -- Si el token no cambió, no hacer nada
    IF old_token = p_new_token THEN
        RETURN '✅ Token no cambió - No se requiere actualización';
    END IF;
    
    -- Verificar si el nuevo token ya existe en otros usuarios
    SELECT COUNT(*), ARRAY_AGG(email) INTO tokens_duplicados, usuarios_afectados
    FROM users_profiles 
    WHERE fcm_token = p_new_token AND id != p_user_id;
    
    -- Si hay tokens duplicados, limpiarlos
    IF tokens_duplicados > 0 THEN
        RAISE NOTICE 'Token duplicado encontrado en % usuarios: %', tokens_duplicados, usuarios_afectados;
        
        -- Limpiar token de otros usuarios (el token se reasignará al usuario actual)
        UPDATE users_profiles 
        SET fcm_token = NULL, updated_at = NOW()
        WHERE fcm_token = p_new_token AND id != p_user_id;
        
        RAISE NOTICE 'Tokens duplicados limpiados de % usuarios', tokens_duplicados;
    END IF;
    
    -- Actualizar token del usuario actual
    UPDATE users_profiles 
    SET fcm_token = p_new_token, updated_at = NOW()
    WHERE id = p_user_id;
    
    -- Registrar en device_tokens si existe la tabla
    BEGIN
        INSERT INTO device_tokens (user_id, token, platform, is_active, created_at, updated_at)
        VALUES (p_user_id, p_new_token, 'android', TRUE, NOW(), NOW())
        ON CONFLICT (user_id, token) 
        DO UPDATE SET 
            is_active = TRUE,
            updated_at = NOW();
    EXCEPTION WHEN OTHERS THEN
        -- Si la tabla device_tokens no existe, continuar sin error
        NULL;
    END;
    
    -- Retornar resultado
    IF tokens_duplicados > 0 THEN
        RETURN '✅ Token actualizado - ' || tokens_duplicados || ' tokens duplicados limpiados';
    ELSE
        RETURN '✅ Token actualizado correctamente';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RETURN '❌ Error al actualizar token: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCIÓN PARA LIMPIAR TOKENS ANTIGUOS
-- =====================================================

CREATE OR REPLACE FUNCTION limpiar_tokens_antiguos() RETURNS TEXT AS $$
DECLARE
    tokens_limpiados INTEGER;
BEGIN
    -- Limpiar tokens de usuarios que no han usado la app en 30 días
    UPDATE users_profiles 
    SET fcm_token = NULL
    WHERE fcm_token IS NOT NULL 
    AND updated_at < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS tokens_limpiados = ROW_COUNT;
    
    RETURN '✅ Limpiados ' || tokens_limpiados || ' tokens antiguos (>30 días)';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCIÓN PARA DIAGNOSTICAR TOKENS DUPLICADOS
-- =====================================================

CREATE OR REPLACE FUNCTION diagnosticar_tokens_duplicados() RETURNS TABLE(
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

-- =====================================================
-- TRIGGER AUTOMÁTICO PARA REEMPLAZO DE TOKENS FCM
-- =====================================================

CREATE OR REPLACE FUNCTION trigger_reemplazar_token_fcm() RETURNS TRIGGER AS $$
DECLARE
    tokens_duplicados INTEGER;
BEGIN
    -- Solo procesar si el token FCM cambió
    IF OLD.fcm_token IS DISTINCT FROM NEW.fcm_token AND NEW.fcm_token IS NOT NULL THEN
        
        -- Limpiar el mismo token de otros usuarios (el token del celular tiene prioridad)
        UPDATE users_profiles 
        SET fcm_token = NULL, updated_at = NOW()
        WHERE fcm_token = NEW.fcm_token 
        AND id != NEW.id;
        
        GET DIAGNOSTICS tokens_duplicados = ROW_COUNT;
        
        IF tokens_duplicados > 0 THEN
            RAISE NOTICE '🔄 Token FCM reemplazado: % tokens duplicados limpiados para usuario %', 
                tokens_duplicados, NEW.email;
        ELSE
            RAISE NOTICE '✅ Token FCM actualizado para usuario %', NEW.email;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger en users_profiles
DROP TRIGGER IF EXISTS trigger_reemplazar_token_fcm ON users_profiles;
CREATE TRIGGER trigger_reemplazar_token_fcm
    BEFORE UPDATE ON users_profiles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_reemplazar_token_fcm();

-- =====================================================
-- FUNCIÓN SIMPLE PARA FORZAR NUEVO TOKEN
-- =====================================================

CREATE OR REPLACE FUNCTION forzar_nuevo_token_usuario(user_email TEXT) RETURNS TEXT AS $$
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
    
    -- Limpiar token actual (forzar regeneración)
    UPDATE users_profiles 
    SET fcm_token = NULL, updated_at = NOW()
    WHERE id = target_user_id;
    
    RETURN '✅ Token limpiado para ' || user_email || '. Debe cerrar y reabrir la app completamente para generar uno nuevo.';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PROBAR LAS FUNCIONES
-- =====================================================

-- Diagnosticar tokens duplicados actuales
SELECT * FROM diagnosticar_tokens_duplicados();

-- Forzar nuevo token para un usuario específico
-- SELECT forzar_nuevo_token_usuario('alof2003@gmail.com');

-- Probar actualización inteligente (cambiar por tu user_id real)
-- SELECT actualizar_fcm_token_inteligente(
--     '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
--     'nuevo_token_de_prueba_' || NOW()::text
-- );