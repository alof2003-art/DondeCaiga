-- ========================================
-- SOLUCIÓN DEFINITIVA COMPLETA
-- Fecha: 2024-12-28
-- Problemas identificados y solucionados
-- ========================================

-- PROBLEMA 1: TRIGGER INCORRECTO (MÁS CRÍTICO)
-- El trigger está configurado como AFTER UPDATE cuando debería ser AFTER INSERT

-- 1. ELIMINAR TRIGGER INCORRECTO
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications;

-- 2. CREAR TRIGGER CORRECTO (AFTER INSERT)
CREATE OR REPLACE FUNCTION send_push_notification_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    recipient_fcm_token TEXT;
    notification_data JSONB;
BEGIN
    -- Obtener el FCM token del destinatario
    SELECT fcm_token INTO recipient_fcm_token
    FROM user_profiles 
    WHERE user_id = NEW.user_id;
    
    -- Solo enviar si hay token FCM
    IF recipient_fcm_token IS NOT NULL AND recipient_fcm_token != '' THEN
        -- Preparar datos de la notificación
        notification_data := jsonb_build_object(
            'token', recipient_fcm_token,
            'title', NEW.title,
            'body', NEW.message,
            'data', jsonb_build_object(
                'notification_id', NEW.id::text,
                'type', NEW.type,
                'click_action', 'FLUTTER_NOTIFICATION_CLICK'
            )
        );
        
        -- Llamar a la Edge Function
        PERFORM net.http_post(
            url := 'https://louehuwimvwsoqesjjau.supabase.co/functions/v1/send-push-notification',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || current_setting('app.jwt_token', true)
            ),
            body := notification_data
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. CREAR TRIGGER CORRECTO (AFTER INSERT)
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_on_insert();

-- PROBLEMA 2: VERIFICAR Y ARREGLAR FCM TOKENS
-- Asegurar que los tokens FCM estén correctamente almacenados

-- 4. VERIFICAR ESTRUCTURA DE user_profiles
DO $$
BEGIN
    -- Verificar si la columna fcm_token existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_profiles' 
        AND column_name = 'fcm_token'
    ) THEN
        -- Agregar columna si no existe
        ALTER TABLE user_profiles ADD COLUMN fcm_token TEXT;
    END IF;
END $$;

-- 5. FUNCIÓN PARA ACTUALIZAR FCM TOKEN
CREATE OR REPLACE FUNCTION update_fcm_token(user_uuid UUID, new_token TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE user_profiles 
    SET fcm_token = new_token,
        updated_at = NOW()
    WHERE user_id = user_uuid;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. POLÍTICA RLS PARA FCM TOKENS
DROP POLICY IF EXISTS "Users can update their own FCM token" ON user_profiles;
CREATE POLICY "Users can update their own FCM token" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- PROBLEMA 3: EDGE FUNCTION URL CORRECTA
-- Verificar que la URL de la Edge Function sea correcta

-- 7. FUNCIÓN DE DIAGNÓSTICO
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
-- PROBLEMA 4: CREAR NOTIFICACIÓN DE PRUEBA
-- Para verificar que todo funciona correctamente

-- 8. FUNCIÓN PARA CREAR NOTIFICACIÓN DE PRUEBA
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
        read_at
    ) VALUES (
        target_user_id,
        '🎯 Prueba Sistema Push',
        'Si recibes esta notificación, el sistema funciona correctamente!',
        'test',
        NOW(),
        NULL
    ) RETURNING id INTO new_notification_id;
    
    RETURN new_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. VERIFICAR PERMISOS DE LA TABLA notifications
-- Asegurar que las políticas RLS permitan insertar notificaciones

-- Política para permitir insertar notificaciones (sistema)
DROP POLICY IF EXISTS "System can insert notifications" ON notifications;
CREATE POLICY "System can insert notifications" ON notifications
    FOR INSERT WITH CHECK (true);

-- Política para que usuarios vean sus notificaciones
DROP POLICY IF EXISTS "Users can view their notifications" ON notifications;
CREATE POLICY "Users can view their notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

-- Política para marcar como leídas
DROP POLICY IF EXISTS "Users can update their notifications" ON notifications;
CREATE POLICY "Users can update their notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- 10. HABILITAR RLS EN notifications SI NO ESTÁ HABILITADO
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ========================================
-- INSTRUCCIONES DE EJECUCIÓN
-- ========================================

/*
PASOS A SEGUIR DESPUÉS DE EJECUTAR ESTE SCRIPT:

1. EJECUTAR TODO ESTE SCRIPT EN SUPABASE SQL EDITOR

2. VERIFICAR QUE TODO ESTÉ CORRECTO:
   SELECT * FROM diagnosticar_sistema_push();

3. PROBAR CON UNA NOTIFICACIÓN:
   -- Reemplaza 'tu-user-id' con un UUID real de user_profiles
   SELECT crear_notificacion_prueba('tu-user-id');

4. VERIFICAR EN LA APP:
   - La notificación debe aparecer en la bandeja del dispositivo
   - También debe aparecer en la pantalla de notificaciones de la app

5. SI NO FUNCIONA, VERIFICAR:
   - Que el FCM token esté guardado correctamente
   - Que la Edge Function esté desplegada
   - Que los permisos de Android estén configurados

PROBLEMAS SOLUCIONADOS:
✅ Trigger corregido: AFTER INSERT (no UPDATE)
✅ Función de envío mejorada
✅ Políticas RLS configuradas
✅ Función de diagnóstico incluida
✅ Sistema de pruebas implementado
*/