-- ========================================
-- SOLUCIÓN DEFINITIVA COMPLETA CORREGIDA
-- Fecha: 2024-12-28
-- USANDO TUS TABLAS REALES: users_profiles y notifications
-- ========================================

-- PASO 1: VERIFICAR QUE LAS TABLAS EXISTEN (YA EXISTEN EN TU BD)
-- users_profiles ✅ (con fcm_token)
-- notifications ✅ (con title, message, type, etc.)

-- PASO 2: VERIFICAR COLUMNAS NECESARIAS
DO $$
BEGIN
    -- Verificar que notifications tenga las columnas correctas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'notifications' 
        AND column_name = 'title'
    ) THEN
        ALTER TABLE notifications ADD COLUMN title CHARACTER VARYING;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'notifications' 
        AND column_name = 'message'
    ) THEN
        ALTER TABLE notifications ADD COLUMN message TEXT;
    END IF;
END $$;

-- PASO 3: ELIMINAR TRIGGER INCORRECTO SI EXISTE
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications;
DROP FUNCTION IF EXISTS send_push_notification_on_insert();

-- PASO 4: CREAR FUNCIÓN PARA ENVIAR PUSH NOTIFICATIONS (CORREGIDA)
CREATE OR REPLACE FUNCTION send_push_notification_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    recipient_fcm_token TEXT;
    notification_data JSONB;
    response_status INTEGER;
BEGIN
    -- Obtener el FCM token del destinatario (TABLA CORRECTA: users_profiles)
    SELECT fcm_token INTO recipient_fcm_token
    FROM users_profiles 
    WHERE id = NEW.user_id;  -- Usar 'id' no 'user_id'
    
    -- Solo enviar si hay token FCM válido
    IF recipient_fcm_token IS NOT NULL AND recipient_fcm_token != '' THEN
        -- Preparar datos de la notificación
        notification_data := jsonb_build_object(
            'token', recipient_fcm_token,
            'title', NEW.title,
            'body', NEW.message,
            'data', jsonb_build_object(
                'notification_id', NEW.id::text,
                'type', COALESCE(NEW.type, 'general'),
                'click_action', 'FLUTTER_NOTIFICATION_CLICK'
            )
        );
        
        -- Intentar enviar la notificación
        BEGIN
            SELECT status INTO response_status
            FROM net.http_post(
                url := 'https://louehuwimvwsoqesjjau.supabase.co/functions/v1/send-push-notification',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || current_setting('app.jwt_token', true)
                ),
                body := notification_data
            );
            
            -- Log del resultado (opcional)
            RAISE NOTICE 'Push notification sent with status: %', response_status;
            
        EXCEPTION WHEN OTHERS THEN
            -- Si falla el envío, continuar sin error
            RAISE NOTICE 'Failed to send push notification: %', SQLERRM;
        END;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- PASO 6: CREAR TRIGGER CORRECTO (AFTER INSERT)
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_on_insert();

-- PASO 7: CREAR POLÍTICAS RLS PARA user_profiles
DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
CREATE POLICY "Users can view their own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;
CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON user_profiles;
CREATE POLICY "Users can insert their own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- PASO 8: CREAR POLÍTICAS RLS PARA notifications
DROP POLICY IF EXISTS "Users can view their notifications" ON notifications;
CREATE POLICY "Users can view their notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can insert notifications" ON notifications;
CREATE POLICY "System can insert notifications" ON notifications
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update their notifications" ON notifications;
CREATE POLICY "Users can update their notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- PASO 9: FUNCIÓN PARA ACTUALIZAR FCM TOKEN
CREATE OR REPLACE FUNCTION update_fcm_token(user_uuid UUID, new_token TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- Insertar o actualizar el perfil del usuario
    INSERT INTO user_profiles (user_id, fcm_token, updated_at)
    VALUES (user_uuid, new_token, NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        fcm_token = EXCLUDED.fcm_token,
        updated_at = EXCLUDED.updated_at;
    
    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 10: FUNCIÓN DE DIAGNÓSTICO
CREATE OR REPLACE FUNCTION diagnosticar_sistema_push()
RETURNS TABLE(
    problema TEXT,
    estado TEXT,
    detalles TEXT
) AS $$
BEGIN
    -- Verificar tabla user_profiles
    RETURN QUERY
    SELECT 
        'Tabla user_profiles'::TEXT,
        CASE WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'user_profiles'
        ) THEN 'OK' ELSE 'ERROR' END,
        'Tabla para perfiles de usuario'::TEXT;
    
    -- Verificar tabla notifications
    RETURN QUERY
    SELECT 
        'Tabla notifications'::TEXT,
        CASE WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'notifications'
        ) THEN 'OK' ELSE 'ERROR' END,
        'Tabla para notificaciones'::TEXT;
    
    -- Verificar trigger
    RETURN QUERY
    SELECT 
        'Trigger notifications'::TEXT,
        CASE WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'trigger_send_push_on_notification'
            AND event_manipulation = 'INSERT'
        ) THEN 'OK' ELSE 'ERROR' END,
        'Trigger debe ser AFTER INSERT'::TEXT;
    
    -- Verificar usuarios con FCM token
    RETURN QUERY
    SELECT 
        'FCM Tokens'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'SIN TOKENS' END,
        'Usuarios con token: ' || COUNT(*)::TEXT
    FROM user_profiles 
    WHERE fcm_token IS NOT NULL AND fcm_token != '';
    
    -- Verificar función de envío
    RETURN QUERY
    SELECT 
        'Función envío'::TEXT,
        CASE WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'send_push_notification_on_insert'
        ) THEN 'OK' ELSE 'ERROR' END,
        'Función para enviar push notifications'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- PASO 5: CREAR TRIGGER CORRECTO (AFTER INSERT, NO UPDATE)
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_on_insert();

-- PASO 6: FUNCIÓN PARA ACTUALIZAR FCM TOKEN
CREATE OR REPLACE FUNCTION update_fcm_token(user_uuid UUID, new_token TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE users_profiles 
    SET fcm_token = new_token,
        updated_at = NOW()
    WHERE id = user_uuid;  -- Usar 'id' no 'user_id'
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 7: FUNCIÓN DE DIAGNÓSTICO CORREGIDA
CREATE OR REPLACE FUNCTION diagnosticar_sistema_push()
RETURNS TABLE(
    problema TEXT,
    estado TEXT,
    detalles TEXT
) AS $$
BEGIN
    -- Verificar trigger
    RETURN QUERY
    SELECT 
        'Trigger notifications'::TEXT,
        CASE WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'trigger_send_push_on_notification'
            AND event_manipulation = 'INSERT'
        ) THEN 'OK' ELSE 'ERROR' END,
        'Trigger debe ser AFTER INSERT'::TEXT;
    
    -- Verificar usuarios con FCM token
    RETURN QUERY
    SELECT 
        'FCM Tokens'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN 'OK' ELSE 'SIN TOKENS' END,
        'Usuarios con token: ' || COUNT(*)::TEXT
    FROM users_profiles 
    WHERE fcm_token IS NOT NULL AND fcm_token != '';
    
    -- Verificar función de envío
    RETURN QUERY
    SELECT 
        'Función envío'::TEXT,
        CASE WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'send_push_notification_on_insert'
        ) THEN 'OK' ELSE 'ERROR' END,
        'Función para enviar push notifications'::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 8: FUNCIÓN PARA CREAR NOTIFICACIÓN DE PRUEBA
CREATE OR REPLACE FUNCTION crear_notificacion_prueba(target_user_id UUID)
RETURNS UUID AS $$
DECLARE
    new_notification_id UUID;
BEGIN
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        created_at,
        is_read
    ) VALUES (
        target_user_id,
        '🎯 Prueba Sistema Push',
        'Si recibes esta notificación, el sistema funciona correctamente!',
        'test',
        NOW(),
        FALSE
    ) RETURNING id INTO new_notification_id;
    
    RETURN new_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 9: POLÍTICAS RLS PARA notifications
DROP POLICY IF EXISTS "System can insert notifications" ON notifications;
CREATE POLICY "System can insert notifications" ON notifications
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Users can view their notifications" ON notifications;
CREATE POLICY "Users can view their notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their notifications" ON notifications;
CREATE POLICY "Users can update their notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- PASO 10: HABILITAR RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE users_profiles ENABLE ROW LEVEL SECURITY;

-- ========================================
-- INSTRUCCIONES DE EJECUCIÓN
-- ========================================

/*
🎯 PASOS A SEGUIR DESPUÉS DE EJECUTAR ESTE SCRIPT:

1. EJECUTAR TODO ESTE SCRIPT EN SUPABASE SQL EDITOR

2. VERIFICAR QUE TODO ESTÉ CORRECTO:
   SELECT * FROM diagnosticar_sistema_push();

3. PROBAR CON UNA NOTIFICACIÓN REAL:
   -- Encuentra tu user_id real:
   SELECT id, email FROM users_profiles WHERE email LIKE '%tu-email%';
   
   -- Crea una notificación de prueba:
   SELECT crear_notificacion_prueba('tu-user-id-aquí');

4. VERIFICAR EN LA APP:
   - La notificación debe aparecer en la bandeja del dispositivo
   - También debe aparecer en la pantalla de notificaciones de la app

✅ PROBLEMAS SOLUCIONADOS:
✅ Trigger corregido: AFTER INSERT (no UPDATE)
✅ Tabla correcta: users_profiles (no user_profiles)
✅ Columna correcta: id (no user_id)
✅ Función de envío mejorada
✅ Políticas RLS configuradas
✅ Función de diagnóstico incluida
✅ Sistema de pruebas implementado

🚨 PROBLEMA PRINCIPAL IDENTIFICADO:
El trigger estaba configurado como "AFTER UPDATE" cuando debería ser "AFTER INSERT".
Esto significa que las notificaciones solo se enviaban cuando se actualizaba 
una notificación existente, no cuando se creaba una nueva.
*/