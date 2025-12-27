-- =====================================================
-- ARREGLAR NOTIFICACIONES Y CHAT COMPLETO
-- =====================================================

-- 1. BORRAR TABLAS INNECESARIAS
DROP TABLE IF EXISTS notificaciones CASCADE;
DROP TABLE IF EXISTS notification_settings CASCADE;

-- 2. VERIFICAR ESTRUCTURA DE LA TABLA NOTIFICATIONS CORRECTA
-- (La que ya tienes y funciona)
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'notifications' 
ORDER BY ordinal_position;

-- 3. AGREGAR COLUMNA FCM_TOKEN A USERS_PROFILES SI NO EXISTE
ALTER TABLE users_profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 4. ARREGLAR ZONA HORARIA EN MENSAJES
-- Actualizar mensajes existentes para usar UTC correctamente
UPDATE mensajes 
SET created_at = created_at AT TIME ZONE 'UTC'
WHERE created_at IS NOT NULL;

-- 5. VERIFICAR ESTRUCTURA DE MENSAJES
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'mensajes' 
ORDER BY ordinal_position;

-- 6. FUNCIÓN PARA CREAR NOTIFICACIÓN DE PRUEBA EN LA TABLA CORRECTA
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

-- 7. VERIFICAR DATOS EXISTENTES
SELECT 'NOTIFICATIONS' as tabla, COUNT(*) as total FROM notifications
UNION ALL
SELECT 'MENSAJES' as tabla, COUNT(*) as total FROM mensajes
UNION ALL
SELECT 'USERS_PROFILES' as tabla, COUNT(*) as total FROM users_profiles;

-- 8. CREAR ÍNDICES PARA MEJORAR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_created 
ON notifications(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_mensajes_chat_created 
ON mensajes(chat_id, created_at ASC);

CREATE INDEX IF NOT EXISTS idx_users_profiles_fcm_token 
ON users_profiles(fcm_token) 
WHERE fcm_token IS NOT NULL;

-- 9. FUNCIÓN PARA LIMPIAR NOTIFICACIONES ANTIGUAS (OPCIONAL)
CREATE OR REPLACE FUNCTION limpiar_notificaciones_antiguas()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM notifications 
    WHERE created_at < NOW() - INTERVAL '30 days'
    AND read = TRUE;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE 'Notificaciones antiguas eliminadas: %', deleted_count;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- VERIFICACIONES FINALES
-- =====================================================

-- Verificar que las tablas correctas existen
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE tablename IN ('notifications', 'mensajes', 'users_profiles')
ORDER BY tablename;

-- Mostrar estructura de notifications
\d notifications;

-- Mostrar últimas notificaciones
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