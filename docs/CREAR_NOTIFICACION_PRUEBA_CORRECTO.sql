-- =====================================================
-- CREAR NOTIFICACIÓN DE PRUEBA - ESTRUCTURA CORRECTA
-- =====================================================

-- 1. AGREGAR COLUMNA FCM_TOKEN A USERS_PROFILES SI NO EXISTE
ALTER TABLE users_profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 2. FUNCIÓN PARA CREAR NOTIFICACIÓN DE PRUEBA CON ESTRUCTURA CORRECTA
CREATE OR REPLACE FUNCTION crear_notificacion_prueba_final(
    p_usuario_id UUID,
    p_titulo TEXT DEFAULT 'Notificación de Prueba',
    p_mensaje TEXT DEFAULT 'Esta es una notificación de prueba desde Supabase'
)
RETURNS UUID AS $$
DECLARE
    nueva_notificacion_id UUID;
BEGIN
    -- Insertar en la tabla NOTIFICATIONS con la estructura correcta
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

-- 3. CREAR ÍNDICES PARA MEJORAR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_created 
ON notifications(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_users_profiles_fcm_token 
ON users_profiles(fcm_token) 
WHERE fcm_token IS NOT NULL;

-- 4. VERIFICAR DATOS EXISTENTES
SELECT 'NOTIFICATIONS' as tabla, COUNT(*) as total FROM notifications
UNION ALL
SELECT 'USERS_PROFILES' as tabla, COUNT(*) as total FROM users_profiles;