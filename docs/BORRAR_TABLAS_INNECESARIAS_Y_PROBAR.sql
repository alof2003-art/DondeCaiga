-- =====================================================
-- BORRAR TABLAS INNECESARIAS Y PROBAR NOTIFICACIONES
-- =====================================================

-- 1. BORRAR TABLAS INNECESARIAS (las que creó tu amigo)
DROP TABLE IF EXISTS notificaciones CASCADE;
DROP TABLE IF EXISTS notification_settings CASCADE;

-- 2. AGREGAR COLUMNA FCM_TOKEN A USERS_PROFILES SI NO EXISTE
ALTER TABLE users_profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 3. FUNCIÓN PARA CREAR NOTIFICACIÓN DE PRUEBA CON ESTRUCTURA CORRECTA
CREATE OR REPLACE FUNCTION crear_notificacion_prueba_final(
    p_usuario_id UUID,
    p_titulo TEXT DEFAULT 'Notificación de Prueba',
    p_mensaje TEXT DEFAULT 'Esta es una notificación de prueba desde Supabase'
)
RETURNS UUID AS $$
DECLARE
    nueva_notificacion_id UUID;
BEGIN
    -- Insertar en la tabla NOTIFICATIONS (la correcta que ya existe)
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        metadata,
        is_read,
        created_at
    ) VALUES (
        p_usuario_id,
        p_titulo,
        p_mensaje,
        'general',
        '{"origen": "prueba_manual"}'::jsonb,
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

-- 4. CREAR ÍNDICES PARA MEJORAR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_created 
ON notifications(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_users_profiles_fcm_token 
ON users_profiles(fcm_token) 
WHERE fcm_token IS NOT NULL;

-- 5. VERIFICAR QUE LAS TABLAS INNECESARIAS SE BORRARON
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%notification%'
ORDER BY table_name;

-- 6. VERIFICAR DATOS EXISTENTES EN LA TABLA CORRECTA
SELECT 'NOTIFICATIONS (correcta)' as tabla, COUNT(*) as total FROM notifications
UNION ALL
SELECT 'USERS_PROFILES' as tabla, COUNT(*) as total FROM users_profiles;

-- 7. MOSTRAR ÚLTIMAS NOTIFICACIONES PARA VERIFICAR
SELECT 
    id,
    user_id,
    title,
    message,
    type,
    is_read,
    created_at
FROM notifications 
ORDER BY created_at DESC 
LIMIT 3;