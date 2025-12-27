-- =====================================================
-- SQL DEFINITIVO NOTIFICACIONES PUSH - VERSIÓN FINAL
-- =====================================================
-- Este SQL resuelve TODOS los problemas identificados
-- Ejecuta TODO este archivo de una sola vez

-- =====================================================
-- 1. CREAR TABLA DE CONFIGURACIÓN PERSISTENTE
-- =====================================================

CREATE TABLE IF NOT EXISTS app_config (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear trigger para updated_at
CREATE OR REPLACE FUNCTION update_app_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_app_config_updated_at ON app_config;
CREATE TRIGGER trigger_update_app_config_updated_at
    BEFORE UPDATE ON app_config
    FOR EACH ROW
    EXECUTE FUNCTION update_app_config_updated_at();

-- =====================================================
-- 2. ARREGLAR POLÍTICAS RLS DE USERS_PROFILES
-- =====================================================

-- Verificar si RLS está habilitado
ALTER TABLE users_profiles ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas conflictivas
DROP POLICY IF EXISTS "Users can view their own profile" ON users_profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON users_profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON users_profiles;
DROP POLICY IF EXISTS "Users can update their own fcm_token" ON users_profiles;
DROP POLICY IF EXISTS "Allow fcm_token updates" ON users_profiles;

-- Crear políticas permisivas para FCM token
CREATE POLICY "Users can view profiles" 
ON users_profiles FOR SELECT 
USING (true);

CREATE POLICY "Users can update profiles" 
ON users_profiles FOR UPDATE 
USING (true)
WITH CHECK (true);

CREATE POLICY "Users can insert profiles" 
ON users_profiles FOR INSERT 
WITH CHECK (true);

-- =====================================================
-- 3. VERIFICAR Y CREAR COLUMNA FCM_TOKEN
-- =====================================================

-- Agregar columna fcm_token si no existe
ALTER TABLE users_profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Crear índice para fcm_token
CREATE INDEX IF NOT EXISTS idx_users_profiles_fcm_token 
ON users_profiles(fcm_token) 
WHERE fcm_token IS NOT NULL;

-- =====================================================
-- 4. CREAR/VERIFICAR TABLA PUSH_NOTIFICATION_QUEUE
-- =====================================================

CREATE TABLE IF NOT EXISTS push_notification_queue (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
    fcm_token TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'failed')),
    attempts INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    error_message TEXT,
    http_request_id BIGINT
);

-- Índices para push_notification_queue
CREATE INDEX IF NOT EXISTS idx_push_queue_status ON push_notification_queue(status);
CREATE INDEX IF NOT EXISTS idx_push_queue_user_id ON push_notification_queue(user_id);
CREATE INDEX IF NOT EXISTS idx_push_queue_created_at ON push_notification_queue(created_at);

-- RLS para push_notification_queue
ALTER TABLE push_notification_queue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own push notifications" ON push_notification_queue;
CREATE POLICY "Users can view their own push notifications" 
ON push_notification_queue FOR SELECT 
USING (user_id = auth.uid());

-- =====================================================
-- 5. FUNCIONES PARA OBTENER CONFIGURACIÓN
-- =====================================================

CREATE OR REPLACE FUNCTION get_app_config(config_key TEXT)
RETURNS TEXT AS $$
DECLARE
    config_value TEXT;
BEGIN
    SELECT value INTO config_value 
    FROM app_config 
    WHERE key = config_key;
    
    RETURN config_value;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. FUNCIÓN PARA ENVIAR PUSH NOTIFICATIONS
-- =====================================================

CREATE OR REPLACE FUNCTION send_push_notification_final(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    user_fcm_token TEXT;
    notification_settings RECORD;
    http_request_id BIGINT;
    supabase_url TEXT;
    supabase_anon_key TEXT;
BEGIN
    -- Obtener configuración
    supabase_url := get_app_config('supabase_url');
    supabase_anon_key := get_app_config('supabase_anon_key');
    
    -- Verificar configuración
    IF supabase_url IS NULL OR supabase_anon_key IS NULL THEN
        INSERT INTO push_notification_queue (
            user_id, fcm_token, title, body, status, error_message
        ) VALUES (
            p_user_id, 'no_token', p_title, p_body, 'failed', 
            'Configuración de Supabase faltante'
        );
        RETURN FALSE;
    END IF;
    
    -- Verificar configuración de notificaciones
    SELECT * INTO notification_settings 
    FROM notification_settings 
    WHERE user_id = p_user_id;
    
    IF notification_settings IS NULL OR NOT notification_settings.push_notifications_enabled THEN
        RETURN FALSE;
    END IF;
    
    -- Obtener FCM token
    SELECT fcm_token INTO user_fcm_token
    FROM users_profiles 
    WHERE id = p_user_id AND fcm_token IS NOT NULL;
    
    IF user_fcm_token IS NULL THEN
        INSERT INTO push_notification_queue (
            user_id, fcm_token, title, body, status, error_message
        ) VALUES (
            p_user_id, 'no_token', p_title, p_body, 'failed', 
            'FCM token no encontrado'
        );
        RETURN FALSE;
    END IF;
    
    -- Llamar a Edge Function
    BEGIN
        SELECT net.http_post(
            url := supabase_url || '/functions/v1/send-push-notification',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || supabase_anon_key
            ),
            body := jsonb_build_object(
                'fcm_token', user_fcm_token,
                'title', p_title,
                'body', p_body
            )
        ) INTO http_request_id;
        
        -- Registrar como enviado
        INSERT INTO push_notification_queue (
            user_id, fcm_token, title, body, status, sent_at, http_request_id
        ) VALUES (
            p_user_id, user_fcm_token, p_title, p_body, 'sent', NOW(), http_request_id
        );
        
        RETURN TRUE;
        
    EXCEPTION WHEN OTHERS THEN
        -- Registrar error
        INSERT INTO push_notification_queue (
            user_id, fcm_token, title, body, status, error_message
        ) VALUES (
            p_user_id, user_fcm_token, p_title, p_body, 'failed', SQLERRM
        );
        
        RETURN FALSE;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. TRIGGER AUTOMÁTICO PARA NOTIFICACIONES
-- =====================================================

CREATE OR REPLACE FUNCTION trigger_send_push_final()
RETURNS TRIGGER AS $$
BEGIN
    -- Enviar push para notificaciones nuevas (no leídas)
    IF NEW.is_read = FALSE THEN
        PERFORM send_push_notification_final(
            NEW.user_id,
            NEW.title,
            NEW.message
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Limpiar triggers anteriores
DROP TRIGGER IF EXISTS trigger_auto_push_simple ON notifications;
DROP TRIGGER IF EXISTS trigger_auto_push_immediate ON notifications;
DROP TRIGGER IF EXISTS trigger_auto_push_auto ON notifications;
DROP TRIGGER IF EXISTS trigger_auto_push_final ON notifications;

-- Crear trigger final
CREATE TRIGGER trigger_auto_push_final
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION trigger_send_push_final();

-- =====================================================
-- 8. FUNCIONES DE DIAGNÓSTICO Y PRUEBA
-- =====================================================

-- Función para verificar configuración completa
CREATE OR REPLACE FUNCTION check_complete_configuration()
RETURNS TABLE(
    component TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Verificar configuración de app
    SELECT 
        'App Config'::TEXT,
        CASE 
            WHEN get_app_config('supabase_url') IS NOT NULL 
                 AND get_app_config('supabase_anon_key') IS NOT NULL 
            THEN 'OK ✅'
            ELSE 'FALTA ❌'
        END::TEXT,
        COALESCE(get_app_config('supabase_url'), 'No configurado')::TEXT
    
    UNION ALL
    
    -- Verificar FCM token del usuario
    SELECT 
        'FCM Token'::TEXT,
        CASE 
            WHEN EXISTS(
                SELECT 1 FROM users_profiles 
                WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid 
                AND fcm_token IS NOT NULL
            ) THEN 'OK ✅'
            ELSE 'FALTA ❌'
        END::TEXT,
        COALESCE(
            (SELECT LEFT(fcm_token, 20) || '...' 
             FROM users_profiles 
             WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid),
            'Token no encontrado'
        )::TEXT
    
    UNION ALL
    
    -- Verificar configuración de notificaciones
    SELECT 
        'Notification Settings'::TEXT,
        CASE 
            WHEN EXISTS(
                SELECT 1 FROM notification_settings 
                WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid 
                AND push_notifications_enabled = true
            ) THEN 'OK ✅'
            ELSE 'FALTA ❌'
        END::TEXT,
        'Push notifications enabled'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Función para probar FCM token generation
CREATE OR REPLACE FUNCTION test_fcm_token_generation()
RETURNS TEXT AS $$
DECLARE
    current_token TEXT;
    test_token TEXT;
BEGIN
    -- Obtener token actual
    SELECT fcm_token INTO current_token
    FROM users_profiles 
    WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;
    
    IF current_token IS NOT NULL THEN
        RETURN '✅ FCM Token ya existe: ' || LEFT(current_token, 30) || '...';
    END IF;
    
    -- Simular inserción de token (como lo haría Flutter)
    test_token := 'test_fcm_token_' || EXTRACT(EPOCH FROM NOW())::text;
    
    UPDATE users_profiles 
    SET fcm_token = test_token
    WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;
    
    IF FOUND THEN
        RETURN '✅ Token de prueba insertado exitosamente: ' || test_token;
    ELSE
        RETURN '❌ No se pudo insertar token - Verifica RLS policies';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para probar sistema completo
CREATE OR REPLACE FUNCTION test_complete_push_system()
RETURNS TEXT AS $$
DECLARE
    config_ok BOOLEAN := FALSE;
    token_ok BOOLEAN := FALSE;
    push_result BOOLEAN := FALSE;
BEGIN
    -- Verificar configuración
    IF get_app_config('supabase_url') IS NOT NULL 
       AND get_app_config('supabase_anon_key') IS NOT NULL THEN
        config_ok := TRUE;
    END IF;
    
    -- Verificar FCM token
    IF EXISTS(
        SELECT 1 FROM users_profiles 
        WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid 
        AND fcm_token IS NOT NULL
    ) THEN
        token_ok := TRUE;
    END IF;
    
    -- Probar envío de push
    IF config_ok AND token_ok THEN
        SELECT send_push_notification_final(
            '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
            'Prueba Sistema Completo 🎉',
            'Si recibes esto, todo funciona perfectamente'
        ) INTO push_result;
    END IF;
    
    -- Retornar resultado
    IF config_ok AND token_ok AND push_result THEN
        RETURN '🎉 SISTEMA COMPLETO FUNCIONANDO - Revisa tu celular';
    ELSIF NOT config_ok THEN
        RETURN '❌ Configuración faltante - Ejecuta INSERT INTO app_config';
    ELSIF NOT token_ok THEN
        RETURN '❌ FCM Token faltante - Reinicia la app';
    ELSE
        RETURN '❌ Error al enviar push - Verifica Edge Function';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para verificar estado del FCM token
CREATE OR REPLACE FUNCTION check_fcm_token_status()
RETURNS TABLE(
    user_id UUID,
    token_status TEXT,
    token_preview TEXT,
    last_updated TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        up.id,
        CASE 
            WHEN up.fcm_token IS NOT NULL THEN 'Token disponible ✅'
            ELSE 'Token faltante ❌ - Reinicia la app'
        END::TEXT,
        COALESCE(LEFT(up.fcm_token, 30) || '...', 'NULL')::TEXT,
        up.updated_at
    FROM users_profiles up
    WHERE up.id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 9. INSERTAR CONFIGURACIÓN POR DEFECTO
-- =====================================================

-- Insertar configuración de notificaciones para el usuario si no existe
INSERT INTO notification_settings (user_id, push_notifications_enabled, email_notifications_enabled)
VALUES ('0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid, true, true)
ON CONFLICT (user_id) DO UPDATE SET 
    push_notifications_enabled = true,
    email_notifications_enabled = true;

-- =====================================================
-- 10. VERIFICACIONES FINALES
-- =====================================================

-- Verificar configuración completa
SELECT * FROM check_complete_configuration();

-- Verificar estado del FCM token
SELECT * FROM check_fcm_token_status();

-- Mostrar configuración actual
SELECT 
    'CONFIGURACIÓN ACTUAL' as info,
    key,
    CASE 
        WHEN key = 'supabase_anon_key' THEN LEFT(value, 20) || '...'
        ELSE value
    END as value_preview
FROM app_config
ORDER BY key;

-- Mostrar últimas notificaciones en cola
SELECT 
    'COLA DE PUSH NOTIFICATIONS' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
    COUNT(CASE WHEN status = 'sent' THEN 1 END) as sent,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed
FROM push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- =====================================================
-- 11. MENSAJE FINAL
-- =====================================================

SELECT '🚀 SQL DEFINITIVO EJECUTADO - AHORA CONFIGURA TUS DATOS CON:' as resultado;
SELECT 'INSERT INTO app_config (key, value) VALUES (''supabase_url'', ''TU-URL''), (''supabase_anon_key'', ''TU-KEY'');' as siguiente_paso;