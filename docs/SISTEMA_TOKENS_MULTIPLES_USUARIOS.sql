-- ========================================
-- SISTEMA DE TOKENS PARA MÚLTIPLES USUARIOS
-- Permite que varios usuarios usen el mismo dispositivo
-- sin perder notificaciones constantemente
-- ========================================

-- PASO 1: CREAR TABLA PARA GESTIONAR TOKENS POR DISPOSITIVO
CREATE TABLE IF NOT EXISTS device_user_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    device_id TEXT NOT NULL, -- Identificador único del dispositivo
    user_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraint único para evitar duplicados
    UNIQUE(device_id, user_id)
);

-- Crear índices por separado
CREATE INDEX IF NOT EXISTS idx_device_user_tokens_fcm_token ON device_user_tokens(fcm_token);
CREATE INDEX IF NOT EXISTS idx_device_user_tokens_device_id ON device_user_tokens(device_id);
CREATE INDEX IF NOT EXISTS idx_device_user_tokens_user_id ON device_user_tokens(user_id);

-- PASO 2: FUNCIÓN PARA OBTENER/CREAR DEVICE_ID ÚNICO
CREATE OR REPLACE FUNCTION get_device_id(fcm_token_param TEXT)
RETURNS TEXT AS $$
BEGIN
    -- Por ahora, usar los primeros 20 caracteres del FCM token como device_id
    -- En producción, podrías usar un identificador más específico del dispositivo
    RETURN LEFT(fcm_token_param, 20);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 3: FUNCIÓN MEJORADA PARA GUARDAR TOKENS (MÚLTIPLES USUARIOS)
CREATE OR REPLACE FUNCTION save_user_fcm_token_multiple(user_uuid UUID, new_token TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    device_identifier TEXT;
    rows_affected INTEGER;
BEGIN
    -- Validar token
    IF new_token IS NULL OR LENGTH(TRIM(new_token)) < 50 THEN
        RETURN FALSE;
    END IF;
    
    -- Obtener identificador del dispositivo
    device_identifier := get_device_id(new_token);
    
    -- Actualizar token en users_profiles (para compatibilidad)
    UPDATE public.users_profiles 
    SET fcm_token = new_token, updated_at = NOW()
    WHERE id = user_uuid;
    
    -- Insertar o actualizar en la tabla de dispositivos
    INSERT INTO device_user_tokens (device_id, user_id, fcm_token, last_login)
    VALUES (device_identifier, user_uuid, new_token, NOW())
    ON CONFLICT (device_id, user_id) 
    DO UPDATE SET 
        fcm_token = EXCLUDED.fcm_token,
        is_active = TRUE,
        last_login = NOW(),
        updated_at = NOW();
    
    -- Marcar otros usuarios del mismo dispositivo como menos activos
    -- (pero no eliminar sus tokens)
    UPDATE device_user_tokens 
    SET is_active = FALSE, updated_at = NOW()
    WHERE device_id = device_identifier 
    AND user_id != user_uuid;
    
    RETURN TRUE;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error al guardar token múltiple: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 4: FUNCIÓN PARA OBTENER USUARIOS ACTIVOS DE UN DISPOSITIVO
CREATE OR REPLACE FUNCTION get_active_users_for_device(fcm_token_param TEXT)
RETURNS TABLE(
    user_id UUID,
    email TEXT,
    nombre TEXT,
    is_primary BOOLEAN,
    last_login TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    device_identifier TEXT;
BEGIN
    device_identifier := get_device_id(fcm_token_param);
    
    RETURN QUERY
    SELECT 
        dup.user_id,
        up.email,
        up.nombre,
        dup.is_active as is_primary,
        dup.last_login
    FROM device_user_tokens dup
    JOIN users_profiles up ON dup.user_id = up.id
    WHERE dup.device_id = device_identifier
    ORDER BY dup.last_login DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 5: FUNCIÓN MEJORADA PARA ENVIAR NOTIFICACIONES
CREATE OR REPLACE FUNCTION send_push_notification_smart()
RETURNS TRIGGER AS $$
DECLARE
    recipient_fcm_token TEXT;
    device_identifier TEXT;
    notification_data JSONB;
    other_users_count INTEGER;
BEGIN
    -- Obtener FCM token del usuario principal
    SELECT fcm_token INTO recipient_fcm_token
    FROM users_profiles 
    WHERE id = NEW.user_id;
    
    -- Solo enviar si hay token válido
    IF recipient_fcm_token IS NOT NULL AND recipient_fcm_token != '' THEN
        device_identifier := get_device_id(recipient_fcm_token);
        
        -- Verificar si hay otros usuarios activos en el mismo dispositivo
        SELECT COUNT(*) INTO other_users_count
        FROM device_user_tokens
        WHERE device_id = device_identifier 
        AND user_id != NEW.user_id
        AND last_login > NOW() - INTERVAL '7 days'; -- Activos en los últimos 7 días
        
        -- Preparar datos con información adicional si hay múltiples usuarios
        notification_data := jsonb_build_object(
            'fcm_token', recipient_fcm_token,
            'title', CASE 
                WHEN other_users_count > 0 THEN 
                    (SELECT nombre FROM users_profiles WHERE id = NEW.user_id) || ': ' || NEW.title
                ELSE NEW.title
            END,
            'body', NEW.message,
            'data', jsonb_build_object(
                'user_id', NEW.user_id,
                'notification_id', NEW.id,
                'multiple_users', other_users_count > 0
            )
        );
        
        -- Enviar push
        BEGIN
            PERFORM net.http_post(
                url := 'https://louehuwimvwsoqesjjau.supabase.co/functions/v1/send-push-notification',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || current_setting('app.jwt_token', true)
                ),
                body := notification_data
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Push notification failed for user %: %', NEW.user_id, SQLERRM;
        END;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 6: FUNCIÓN DE LIMPIEZA AUTOMÁTICA
CREATE OR REPLACE FUNCTION cleanup_old_device_tokens()
RETURNS TEXT AS $$
DECLARE
    cleaned_count INTEGER;
BEGIN
    -- Eliminar tokens de usuarios inactivos por más de 30 días
    DELETE FROM device_user_tokens 
    WHERE last_login < NOW() - INTERVAL '30 days'
    AND is_active = FALSE;
    
    GET DIAGNOSTICS cleaned_count = ROW_COUNT;
    
    RETURN '✅ Limpiados ' || cleaned_count || ' tokens antiguos';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 7: REEMPLAZAR FUNCIÓN ANTERIOR
DROP FUNCTION IF EXISTS save_user_fcm_token(UUID, TEXT);
CREATE OR REPLACE FUNCTION save_user_fcm_token(user_uuid UUID, new_token TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN save_user_fcm_token_multiple(user_uuid, new_token);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 8: ACTUALIZAR TRIGGER
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications;
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_smart();

-- PASO 9: FUNCIÓN DE DIAGNÓSTICO
CREATE OR REPLACE FUNCTION diagnosticar_sistema_multiple()
RETURNS TABLE(
    info TEXT,
    valor TEXT,
    descripcion TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'Dispositivos únicos'::TEXT,
        COUNT(DISTINCT device_id)::TEXT,
        'Número de dispositivos diferentes'::TEXT
    FROM device_user_tokens;
    
    RETURN QUERY
    SELECT 
        'Usuarios con tokens'::TEXT,
        COUNT(DISTINCT user_id)::TEXT,
        'Usuarios que han usado la app'::TEXT
    FROM device_user_tokens;
    
    RETURN QUERY
    SELECT 
        'Usuarios activos'::TEXT,
        COUNT(*)::TEXT,
        'Usuarios activos en los últimos 7 días'::TEXT
    FROM device_user_tokens
    WHERE last_login > NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 10: EJECUTAR DIAGNÓSTICO
SELECT * FROM diagnosticar_sistema_multiple();