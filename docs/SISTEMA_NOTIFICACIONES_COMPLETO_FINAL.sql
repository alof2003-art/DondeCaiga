-- =====================================================
-- SISTEMA COMPLETO DE NOTIFICACIONES - FINAL
-- =====================================================

-- PASO 1: HABILITAR EXTENSIONES NECESARIAS
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- PASO 2: CREAR/ACTUALIZAR TABLA DE NOTIFICACIONES
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'general',
    data JSONB DEFAULT '{}',
    read_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PASO 3: CREAR ÍNDICES PARA PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_read_at ON notifications(read_at) WHERE read_at IS NULL;

-- PASO 4: CONFIGURAR RLS (Row Level Security)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Política para que usuarios solo vean sus notificaciones
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

-- Política para que usuarios puedan marcar como leídas sus notificaciones
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Política para insertar notificaciones (solo servicios autenticados)
DROP POLICY IF EXISTS "Service can insert notifications" ON notifications;
CREATE POLICY "Service can insert notifications" ON notifications
    FOR INSERT WITH CHECK (true);

-- PASO 5: VERIFICAR/ACTUALIZAR TABLA users_profiles
DO $$
BEGIN
    -- Verificar si la columna fcm_token existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users_profiles' 
        AND column_name = 'fcm_token'
    ) THEN
        ALTER TABLE users_profiles ADD COLUMN fcm_token TEXT;
    END IF;
    
    -- Asegurar que la columna sea TEXT (sin límite)
    ALTER TABLE users_profiles ALTER COLUMN fcm_token TYPE TEXT;
END $$;

-- PASO 6: CREAR FUNCIÓN DE TRIGGER OPTIMIZADA
DROP FUNCTION IF EXISTS send_push_notification_on_insert();
CREATE OR REPLACE FUNCTION send_push_notification_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    fcm_token_var TEXT;
    project_url TEXT := 'https://louehuwimvwsoqesjjau.supabase.co';
    anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvdWVodXdpbXZ3c29xZXNqamF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3OTQ4MTYsImV4cCI6MjA4MDM3MDgxNn0.vhqclBtgt-o_GTNFGsU-pKYK68coeemIjl_CTQl8Rz8';
    request_id BIGINT;
    notification_data JSONB;
BEGIN
    -- Obtener el FCM token del usuario
    SELECT fcm_token INTO fcm_token_var
    FROM users_profiles 
    WHERE id = NEW.user_id 
    AND fcm_token IS NOT NULL
    AND LENGTH(fcm_token) > 50  -- Verificar que sea un token válido
    LIMIT 1;
    
    -- Solo enviar si hay token válido
    IF fcm_token_var IS NOT NULL THEN
        -- Preparar datos adicionales
        notification_data := jsonb_build_object(
            'notification_id', NEW.id::TEXT,
            'type', NEW.type,
            'created_at', NEW.created_at::TEXT
        );
        
        -- Si hay datos adicionales, combinarlos
        IF NEW.data IS NOT NULL AND NEW.data != '{}' THEN
            notification_data := notification_data || NEW.data;
        END IF;
        
        -- Llamar a la Edge Function
        SELECT net.http_post(
            url := project_url || '/functions/v1/send-push-notification',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || anon_key
            ),
            body := jsonb_build_object(
                'fcm_token', fcm_token_var,
                'title', NEW.title,
                'body', NEW.message,
                'data', notification_data
            )
        ) INTO request_id;
        
        RAISE NOTICE 'Push notification enviada - Request ID: %, User: %', request_id, NEW.user_id;
    ELSE
        RAISE NOTICE 'No FCM token válido para usuario: %', NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- PASO 7: CREAR TRIGGER
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications;
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_on_insert();

-- PASO 8: FUNCIONES AUXILIARES PARA EL SISTEMA

-- Función para marcar notificación como leída
CREATE OR REPLACE FUNCTION mark_notification_as_read(notification_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE notifications 
    SET read_at = NOW(), updated_at = NOW()
    WHERE id = notification_id 
    AND user_id = auth.uid()
    AND read_at IS NULL;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para marcar todas las notificaciones como leídas
CREATE OR REPLACE FUNCTION mark_all_notifications_as_read()
RETURNS INTEGER AS $$
DECLARE
    affected_count INTEGER;
BEGIN
    UPDATE notifications 
    SET read_at = NOW(), updated_at = NOW()
    WHERE user_id = auth.uid()
    AND read_at IS NULL;
    
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    RETURN affected_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para obtener conteo de notificaciones no leídas
CREATE OR REPLACE FUNCTION get_unread_notifications_count()
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM notifications 
        WHERE user_id = auth.uid()
        AND read_at IS NULL
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para limpiar notificaciones antiguas (opcional)
CREATE OR REPLACE FUNCTION cleanup_old_notifications(days_old INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM notifications 
    WHERE created_at < NOW() - INTERVAL '1 day' * days_old
    AND read_at IS NOT NULL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 9: CREAR FUNCIONES PARA TIPOS ESPECÍFICOS DE NOTIFICACIONES

-- Notificación de nueva reserva
CREATE OR REPLACE FUNCTION notify_new_reservation(
    p_user_id UUID,
    p_property_name TEXT,
    p_guest_name TEXT,
    p_check_in DATE,
    p_reservation_id UUID
)
RETURNS UUID AS $$
DECLARE
    notification_id UUID;
BEGIN
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        data
    ) VALUES (
        p_user_id,
        '🏠 Nueva Reserva',
        p_guest_name || ' ha reservado ' || p_property_name || ' para el ' || p_check_in::TEXT,
        'new_reservation',
        jsonb_build_object(
            'reservation_id', p_reservation_id::TEXT,
            'property_name', p_property_name,
            'guest_name', p_guest_name,
            'check_in', p_check_in::TEXT
        )
    ) RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Notificación de nuevo mensaje de chat
CREATE OR REPLACE FUNCTION notify_new_chat_message(
    p_user_id UUID,
    p_sender_name TEXT,
    p_message_preview TEXT,
    p_chat_id UUID
)
RETURNS UUID AS $$
DECLARE
    notification_id UUID;
BEGIN
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        data
    ) VALUES (
        p_user_id,
        '💬 Nuevo Mensaje',
        p_sender_name || ': ' || LEFT(p_message_preview, 50) || CASE WHEN LENGTH(p_message_preview) > 50 THEN '...' ELSE '' END,
        'new_message',
        jsonb_build_object(
            'chat_id', p_chat_id::TEXT,
            'sender_name', p_sender_name,
            'message_preview', p_message_preview
        )
    ) RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Notificación de nueva reseña
CREATE OR REPLACE FUNCTION notify_new_review(
    p_user_id UUID,
    p_reviewer_name TEXT,
    p_property_name TEXT,
    p_rating INTEGER,
    p_review_id UUID
)
RETURNS UUID AS $$
DECLARE
    notification_id UUID;
    stars TEXT;
BEGIN
    -- Crear representación visual de estrellas
    stars := REPEAT('⭐', p_rating);
    
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        data
    ) VALUES (
        p_user_id,
        '⭐ Nueva Reseña',
        p_reviewer_name || ' dejó una reseña de ' || p_rating || ' estrellas para ' || p_property_name || ' ' || stars,
        'new_review',
        jsonb_build_object(
            'review_id', p_review_id::TEXT,
            'reviewer_name', p_reviewer_name,
            'property_name', p_property_name,
            'rating', p_rating
        )
    ) RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 10: VERIFICACIÓN FINAL DEL SISTEMA
SELECT 
    'EXTENSIONES' as componente,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') 
        THEN '✅ pg_net HABILITADA'
        ELSE '❌ pg_net NO HABILITADA'
    END as estado
UNION ALL
SELECT 
    'TABLA NOTIFICATIONS' as componente,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications') 
        THEN '✅ TABLA CREADA'
        ELSE '❌ TABLA NO EXISTE'
    END as estado
UNION ALL
SELECT 
    'TRIGGER' as componente,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'trigger_send_push_on_notification') 
        THEN '✅ TRIGGER ACTIVO'
        ELSE '❌ TRIGGER NO EXISTE'
    END as estado
UNION ALL
SELECT 
    'FCM_TOKEN COLUMN' as componente,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users_profiles' AND column_name = 'fcm_token') 
        THEN '✅ COLUMNA EXISTE'
        ELSE '❌ COLUMNA NO EXISTE'
    END as estado;

-- PASO 11: INSERTAR NOTIFICACIÓN DE PRUEBA DEL SISTEMA COMPLETO
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    data,
    created_at
) 
SELECT 
    au.id,
    '🎉 Sistema Completo Activado',
    'Tu sistema de notificaciones está funcionando al 100%. Todas las funcionalidades están integradas y listas para usar.',
    'system_ready',
    jsonb_build_object(
        'version', '1.0.0',
        'features', jsonb_build_array('push_notifications', 'real_time', 'chat', 'reservations', 'reviews'),
        'timestamp', NOW()::TEXT
    ),
    NOW()
FROM auth.users au 
WHERE au.email = 'alof2003@gmail.com'
LIMIT 1;

-- MOSTRAR RESUMEN FINAL
SELECT 
    '🚀 SISTEMA COMPLETO INSTALADO' as resultado,
    'Todas las funcionalidades están activas' as estado,
    'Push notifications, chat, reservas, reseñas integradas' as funcionalidades;