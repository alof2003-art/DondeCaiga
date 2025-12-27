-- =====================================================
-- SOLUCIÓN DEFINITIVA NOTIFICACIONES - FORCE RESET
-- =====================================================

-- 1. LIMPIAR COMPLETAMENTE EL CACHE DE SUPABASE
NOTIFY pgrst, 'reload schema';

-- 2. VERIFICAR QUE LA TABLA NOTIFICATIONS EXISTE Y ESTÁ BIEN
SELECT 
    'VERIFICANDO TABLA NOTIFICATIONS' as status,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'notifications';

-- 3. VERIFICAR COLUMNAS DE LA TABLA NOTIFICATIONS
SELECT 
    'COLUMNAS DE NOTIFICATIONS' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'notifications' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. AGREGAR COLUMNA FCM_TOKEN SI NO EXISTE
ALTER TABLE users_profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 5. CREAR ÍNDICES OPTIMIZADOS
DROP INDEX IF EXISTS idx_notifications_user_id_created;
DROP INDEX IF EXISTS idx_notifications_user_read;
DROP INDEX IF EXISTS idx_users_profiles_fcm_token;

CREATE INDEX idx_notifications_user_id_created 
ON notifications(user_id, created_at DESC);

CREATE INDEX idx_notifications_user_read 
ON notifications(user_id, is_read);

CREATE INDEX idx_users_profiles_fcm_token 
ON users_profiles(fcm_token) 
WHERE fcm_token IS NOT NULL;

-- 6. FUNCIÓN DE PRUEBA SUPER SIMPLE
DROP FUNCTION IF EXISTS crear_notificacion_prueba_final CASCADE;

CREATE OR REPLACE FUNCTION crear_notificacion_prueba_final(
    p_usuario_id UUID,
    p_titulo TEXT DEFAULT 'Notificación de Prueba',
    p_mensaje TEXT DEFAULT 'Esta es una notificación de prueba desde Supabase'
)
RETURNS UUID AS $$
DECLARE
    nueva_notificacion_id UUID;
BEGIN
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
    
    RETURN nueva_notificacion_id;
END;
$$ LANGUAGE plpgsql;

-- 7. VERIFICAR POLÍTICAS RLS
SELECT 
    'POLÍTICAS RLS' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'notifications';

-- 8. HABILITAR RLS SI NO ESTÁ HABILITADO
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- 9. CREAR POLÍTICA BÁSICA SI NO EXISTE
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications" 
ON notifications FOR SELECT 
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
CREATE POLICY "Users can update own notifications" 
ON notifications FOR UPDATE 
USING (auth.uid() = user_id);

-- 10. INSERTAR NOTIFICACIÓN DE PRUEBA DIRECTAMENTE
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    metadata,
    is_read,
    created_at
) VALUES (
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'Prueba Directa',
    'Esta notificación se insertó directamente en el SQL',
    'general',
    '{"origen": "sql_directo"}'::jsonb,
    FALSE,
    NOW()
) ON CONFLICT DO NOTHING;

-- 11. VERIFICAR QUE SE INSERTÓ
SELECT 
    'NOTIFICACIONES INSERTADAS' as info,
    COUNT(*) as total,
    MAX(created_at) as ultima_fecha
FROM notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 12. MOSTRAR ÚLTIMAS NOTIFICACIONES
SELECT 
    'ÚLTIMAS NOTIFICACIONES' as info,
    id,
    user_id,
    title,
    message,
    type,
    is_read,
    created_at
FROM notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
ORDER BY created_at DESC 
LIMIT 5;

-- 13. LIMPIAR CACHE NUEVAMENTE
NOTIFY pgrst, 'reload schema';

-- 14. MENSAJE FINAL
SELECT 'CONFIGURACIÓN COMPLETADA - REINICIA LA APP' as resultado;