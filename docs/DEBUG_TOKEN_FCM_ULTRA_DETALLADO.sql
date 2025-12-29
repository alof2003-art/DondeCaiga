-- =====================================================
-- DEBUG ULTRA DETALLADO PARA TOKENS FCM
-- Verificar si los tokens se están enviando correctamente
-- =====================================================

-- PASO 1: Crear tabla de logs para debugging
CREATE TABLE IF NOT EXISTS debug_fcm_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID,
    user_email TEXT,
    action_type TEXT, -- 'token_received', 'token_saved', 'token_error', 'token_cleared'
    token_preview TEXT, -- Primeros 30 caracteres del token
    token_length INTEGER,
    success BOOLEAN,
    error_message TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- PASO 2: Función para registrar logs de debugging
CREATE OR REPLACE FUNCTION log_fcm_debug(
    p_user_id UUID,
    p_user_email TEXT,
    p_action_type TEXT,
    p_token TEXT DEFAULT NULL,
    p_success BOOLEAN DEFAULT TRUE,
    p_error_message TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'
) RETURNS TEXT AS $$
BEGIN
    INSERT INTO debug_fcm_logs (
        user_id, user_email, action_type, 
        token_preview, token_length, 
        success, error_message, metadata
    ) VALUES (
        p_user_id, p_user_email, p_action_type,
        CASE WHEN p_token IS NOT NULL THEN LEFT(p_token, 30) || '...' ELSE NULL END,
        CASE WHEN p_token IS NOT NULL THEN LENGTH(p_token) ELSE 0 END,
        p_success, p_error_message, p_metadata
    );
    
    RETURN '✅ Log registrado: ' || p_action_type;
END;
$$ LANGUAGE plpgsql;

-- PASO 3: Función mejorada para actualizar token con logs
CREATE OR REPLACE FUNCTION actualizar_token_fcm_con_logs(
    p_user_id UUID,
    p_new_token TEXT
) RETURNS TEXT AS $$
DECLARE
    user_email_var TEXT;
    old_token TEXT;
    update_result INTEGER;
    final_result TEXT;
BEGIN
    -- Obtener email del usuario
    SELECT email, fcm_token INTO user_email_var, old_token
    FROM users_profiles 
    WHERE id = p_user_id;
    
    IF user_email_var IS NULL THEN
        PERFORM log_fcm_debug(p_user_id, 'UNKNOWN', 'token_error', p_new_token, FALSE, 'Usuario no encontrado');
        RETURN '❌ Usuario no encontrado';
    END IF;
    
    -- Log: Token recibido
    PERFORM log_fcm_debug(p_user_id, user_email_var, 'token_received', p_new_token, TRUE, NULL, 
        jsonb_build_object('old_token_preview', CASE WHEN old_token IS NOT NULL THEN LEFT(old_token, 30) || '...' ELSE 'NULL' END));
    
    -- Intentar actualizar
    BEGIN
        UPDATE users_profiles 
        SET fcm_token = p_new_token, updated_at = NOW()
        WHERE id = p_user_id;
        
        GET DIAGNOSTICS update_result = ROW_COUNT;
        
        IF update_result > 0 THEN
            -- Log: Token guardado exitosamente
            PERFORM log_fcm_debug(p_user_id, user_email_var, 'token_saved', p_new_token, TRUE, NULL,
                jsonb_build_object('rows_affected', update_result));
            final_result := '✅ Token actualizado para ' || user_email_var;
        ELSE
            -- Log: No se actualizó ninguna fila
            PERFORM log_fcm_debug(p_user_id, user_email_var, 'token_error', p_new_token, FALSE, 'No se actualizó ninguna fila - posible problema RLS');
            final_result := '❌ No se actualizó ninguna fila para ' || user_email_var;
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        -- Log: Error en la actualización
        PERFORM log_fcm_debug(p_user_id, user_email_var, 'token_error', p_new_token, FALSE, SQLERRM);
        final_result := '❌ Error SQL: ' || SQLERRM;
    END;
    
    RETURN final_result;
END;
$$ LANGUAGE plpgsql;

-- PASO 4: Función para limpiar token con logs
CREATE OR REPLACE FUNCTION limpiar_token_logout_con_logs(
    p_user_id UUID
) RETURNS TEXT AS $$
DECLARE
    user_email_var TEXT;
    old_token TEXT;
    update_result INTEGER;
BEGIN
    -- Obtener datos del usuario
    SELECT email, fcm_token INTO user_email_var, old_token
    FROM users_profiles 
    WHERE id = p_user_id;
    
    IF user_email_var IS NULL THEN
        PERFORM log_fcm_debug(p_user_id, 'UNKNOWN', 'token_error', NULL, FALSE, 'Usuario no encontrado en logout');
        RETURN '❌ Usuario no encontrado';
    END IF;
    
    -- Log: Iniciando limpieza
    PERFORM log_fcm_debug(p_user_id, user_email_var, 'token_clearing', old_token, TRUE, 'Iniciando limpieza de logout');
    
    -- Limpiar token
    UPDATE users_profiles 
    SET fcm_token = NULL, updated_at = NOW()
    WHERE id = p_user_id;
    
    GET DIAGNOSTICS update_result = ROW_COUNT;
    
    IF update_result > 0 THEN
        -- Log: Token limpiado exitosamente
        PERFORM log_fcm_debug(p_user_id, user_email_var, 'token_cleared', NULL, TRUE, 'Token limpiado en logout');
        RETURN '✅ Token limpiado para ' || user_email_var;
    ELSE
        -- Log: Error en limpieza
        PERFORM log_fcm_debug(p_user_id, user_email_var, 'token_error', NULL, FALSE, 'No se pudo limpiar token en logout');
        RETURN '❌ Error al limpiar token para ' || user_email_var;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    PERFORM log_fcm_debug(p_user_id, user_email_var, 'token_error', NULL, FALSE, 'Error SQL en logout: ' || SQLERRM);
    RETURN '❌ Error SQL en logout: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- PASO 5: Función para ver logs de debugging
CREATE OR REPLACE FUNCTION ver_logs_fcm_debug(
    p_user_email TEXT DEFAULT NULL,
    p_limit INTEGER DEFAULT 50
) RETURNS TABLE(
    timestamp_log TIMESTAMP WITH TIME ZONE,
    user_email TEXT,
    action_type TEXT,
    token_preview TEXT,
    token_length INTEGER,
    success BOOLEAN,
    error_message TEXT,
    metadata JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dl.created_at,
        dl.user_email,
        dl.action_type,
        dl.token_preview,
        dl.token_length,
        dl.success,
        dl.error_message,
        dl.metadata
    FROM debug_fcm_logs dl
    WHERE (p_user_email IS NULL OR dl.user_email = p_user_email)
    ORDER BY dl.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- PASO 6: Función para estadísticas de tokens
CREATE OR REPLACE FUNCTION estadisticas_tokens_fcm() RETURNS TABLE(
    total_usuarios INTEGER,
    usuarios_con_token INTEGER,
    usuarios_sin_token INTEGER,
    tokens_duplicados INTEGER,
    ultimo_token_actualizado TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_usuarios,
        COUNT(fcm_token)::INTEGER as usuarios_con_token,
        (COUNT(*) - COUNT(fcm_token))::INTEGER as usuarios_sin_token,
        (SELECT COUNT(*) FROM (
            SELECT fcm_token 
            FROM users_profiles 
            WHERE fcm_token IS NOT NULL 
            GROUP BY fcm_token 
            HAVING COUNT(*) > 1
        ) duplicados)::INTEGER as tokens_duplicados,
        MAX(updated_at) as ultimo_token_actualizado
    FROM users_profiles;
END;
$$ LANGUAGE plpgsql;

-- PASO 7: Función para monitoreo en tiempo real
CREATE OR REPLACE FUNCTION monitoreo_tiempo_real_tokens() RETURNS TABLE(
    momento_check TIMESTAMP WITH TIME ZONE,
    email TEXT,
    token_status TEXT,
    token_length INTEGER,
    segundos_desde_update NUMERIC,
    logs_recientes INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        NOW() as momento_check,
        up.email,
        CASE 
            WHEN up.fcm_token IS NOT NULL THEN 'TOKEN PRESENTE'
            ELSE 'TOKEN AUSENTE'
        END as token_status,
        COALESCE(LENGTH(up.fcm_token), 0) as token_length,
        EXTRACT(EPOCH FROM (NOW() - up.updated_at)) as segundos_desde_update,
        (SELECT COUNT(*)::INTEGER 
         FROM debug_fcm_logs dl 
         WHERE dl.user_email = up.email 
         AND dl.created_at > NOW() - INTERVAL '1 hour') as logs_recientes
    FROM users_profiles up
    ORDER BY up.updated_at DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- COMANDOS PARA USAR DURANTE EL DEBUG
-- =====================================================

-- Ver estadísticas generales
SELECT * FROM estadisticas_tokens_fcm();

-- Ver logs de un usuario específico
SELECT * FROM ver_logs_fcm_debug('mpattydaquilema@gmail.com');

-- Ver todos los logs recientes
SELECT * FROM ver_logs_fcm_debug();

-- Monitoreo en tiempo real
SELECT * FROM monitoreo_tiempo_real_tokens();

-- Limpiar logs antiguos (opcional)
-- DELETE FROM debug_fcm_logs WHERE created_at < NOW() - INTERVAL '7 days';

-- =====================================================
-- INSTRUCCIONES DE USO
-- =====================================================

/*
1. Ejecuta este script en Supabase
2. Modifica el código Flutter para usar las nuevas funciones con logs
3. Usa estos comandos para monitorear:
   - SELECT * FROM ver_logs_fcm_debug('tu_email@gmail.com');
   - SELECT * FROM monitoreo_tiempo_real_tokens();
4. Los logs te dirán exactamente qué está pasando con cada token
*/