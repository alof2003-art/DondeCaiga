-- =====================================================
-- ARREGLAR NOTIFICACIONES - VERSION SIMPLE PARA SUPABASE
-- =====================================================

-- 1. BORRAR TABLAS INNECESARIAS
DROP TABLE IF EXISTS notificaciones CASCADE;
DROP TABLE IF EXISTS notification_settings CASCADE;

-- 2. AGREGAR COLUMNA FCM_TOKEN A USERS_PROFILES SI NO EXISTE
ALTER TABLE users_profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 3. CREAR ÍNDICES PARA MEJORAR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_created 
ON notifications(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_users_profiles_fcm_token 
ON users_profiles(fcm_token) 
WHERE fcm_token IS NOT NULL;

-- 4. FUNCIÓN PARA CREAR NOTIFICACIÓN DE PRUEBA EN LA TABLA CORRECTA
CREATE OR REPLACE FUNCTION crear_notificacion_prueba_correcta(
    p_usuario_id UUID,
    p_titulo TEXT DEFAULT 'Notificación de Prueba',
    p_mensaje TEXT DEFAULT 'Esta es una notificación de prueba desde Supabase'
)
RETURNS UUID AS $$
DECLARE
    nueva_notificacion_id UUID;
BEGIN
    -- Insertar en la tabla NOTIFICATIONS (la correcta)
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        data,
        read,
        created_at
    ) VALUES (
        p_usuario_id,
        p_titulo,
        p_mensaje,
        'general',
        '{"origen": "prueba_manual"}',
        FALSE,
        NOW()
    ) RETURNING id INTO nueva_notificacion_id;
    
    RAISE NOTICE 'Notificación de prueba creada con ID: %', nueva_notificacion_id;
    RETURN nueva_notificacion_id;
    
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error al crear notificación de prueba: %', SQLERRM;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 5. VERIFICAR DATOS EXISTENTES
SELECT 'NOTIFICATIONS' as tabla, COUNT(*) as total FROM notifications
UNION ALL
SELECT 'USERS_PROFILES' as tabla, COUNT(*) as total FROM users_profiles;

-- 6. MOSTRAR ESTRUCTURA DE NOTIFICATIONS (VERSION COMPATIBLE)
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'notifications' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 7. MOSTRAR ÚLTIMAS NOTIFICACIONES
SELECT 
    id,
    user_id,
    title,
    message,
    type,
    read,
    created_at
FROM notifications 
ORDER BY created_at DESC 
LIMIT 5;