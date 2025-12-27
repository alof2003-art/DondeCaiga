-- =====================================================
-- ARREGLO FINAL NOTIFICACIONES - LIMPIAR TODO
-- =====================================================

-- 1. ELIMINAR TODAS LAS FUNCIONES QUE USAN LA TABLA INCORRECTA
DROP FUNCTION IF EXISTS crear_notificacion_prueba CASCADE;
DROP FUNCTION IF EXISTS crear_notificacion_nueva_reserva CASCADE;
DROP FUNCTION IF EXISTS crear_notificacion_decision_reserva CASCADE;
DROP FUNCTION IF EXISTS crear_notificacion_nueva_resena CASCADE;
DROP FUNCTION IF EXISTS crear_notificacion_nuevo_mensaje CASCADE;
DROP FUNCTION IF EXISTS limpiar_notificaciones_antiguas CASCADE;

-- 2. ELIMINAR TRIGGERS QUE PUEDAN ESTAR USANDO LA TABLA INCORRECTA
DROP TRIGGER IF EXISTS trigger_nueva_reserva_notificacion ON reservas CASCADE;
DROP TRIGGER IF EXISTS trigger_nueva_resena_notificacion ON resenas CASCADE;
DROP TRIGGER IF EXISTS trigger_enviar_notificacion_push ON notificaciones CASCADE;

-- 3. BORRAR TABLAS INNECESARIAS DEFINITIVAMENTE
DROP TABLE IF EXISTS notificaciones CASCADE;
DROP TABLE IF EXISTS notification_settings CASCADE;

-- 4. AGREGAR COLUMNA FCM_TOKEN A USERS_PROFILES SI NO EXISTE
ALTER TABLE users_profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 5. CREAR ÍNDICES PARA LA TABLA NOTIFICATIONS (la correcta)
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_created 
ON notifications(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_notifications_user_read 
ON notifications(user_id, is_read);

CREATE INDEX IF NOT EXISTS idx_users_profiles_fcm_token 
ON users_profiles(fcm_token) 
WHERE fcm_token IS NOT NULL;

-- 6. FUNCIÓN DE PRUEBA CORRECTA (usa tabla notifications)
CREATE OR REPLACE FUNCTION crear_notificacion_prueba_final(
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

-- 7. VERIFICAR QUE TODO ESTÁ LIMPIO
SELECT 
    'TABLAS CON NOTIFICATION' as tipo,
    table_name
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE '%notification%'
ORDER BY table_name;

-- 8. VERIFICAR FUNCIONES
SELECT 
    'FUNCIONES CON NOTIFICACION' as tipo,
    routine_name
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%notificacion%'
ORDER BY routine_name;

-- 9. MOSTRAR DATOS DE LA TABLA CORRECTA
SELECT 'NOTIFICATIONS (correcta)' as tabla, COUNT(*) as total FROM notifications;

-- 10. MOSTRAR ESTRUCTURA DE LA TABLA CORRECTA
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'notifications' 
AND table_schema = 'public'
ORDER BY ordinal_position;