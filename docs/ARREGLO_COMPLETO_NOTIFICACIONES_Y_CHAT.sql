-- =====================================================
-- ARREGLO COMPLETO NOTIFICACIONES Y CHAT - FINAL
-- =====================================================

-- 1. ELIMINAR COMPLETAMENTE LA TABLA INCORRECTA Y TODAS SUS DEPENDENCIAS
DROP TABLE IF EXISTS notificaciones CASCADE;
DROP TABLE IF EXISTS notification_settings CASCADE;

-- 2. ELIMINAR TODAS LAS FUNCIONES QUE USAN LA TABLA INCORRECTA
DROP FUNCTION IF EXISTS crear_notificacion_solicitud_reserva CASCADE;
DROP FUNCTION IF EXISTS crear_notificacion_decision_reserva CASCADE;
DROP FUNCTION IF EXISTS crear_notificacion_nueva_resena CASCADE;
DROP FUNCTION IF EXISTS crear_notificacion_decision_anfitrion CASCADE;
DROP FUNCTION IF EXISTS crear_notificacion_nuevo_mensaje CASCADE;
DROP FUNCTION IF EXISTS crear_notificacion_llegada_huesped CASCADE;
DROP FUNCTION IF EXISTS crear_notificacion_fin_estadia CASCADE;
DROP FUNCTION IF EXISTS marcar_todas_notificaciones_leidas CASCADE;
DROP FUNCTION IF EXISTS limpiar_notificaciones_antiguas CASCADE;
DROP FUNCTION IF EXISTS update_notificaciones_updated_at CASCADE;
DROP FUNCTION IF EXISTS trigger_notificacion_nueva_reserva CASCADE;
DROP FUNCTION IF EXISTS trigger_notificacion_estado_reserva CASCADE;
DROP FUNCTION IF EXISTS crear_notificacion_prueba CASCADE;
DROP FUNCTION IF EXISTS crear_notificacion_prueba_final CASCADE;

-- 3. VERIFICAR QUE LA TABLA NOTIFICATIONS EXISTE CON LA ESTRUCTURA CORRECTA
SELECT 'VERIFICANDO TABLA NOTIFICATIONS' as status;

-- Si no existe, crearla
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'general',
    metadata JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. AGREGAR COLUMNA FCM_TOKEN A USERS_PROFILES SI NO EXISTE
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

-- 6. CONFIGURAR RLS PARA NOTIFICATIONS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can insert own notifications" ON notifications;
DROP POLICY IF EXISTS "Service role can insert notifications" ON notifications;

-- Crear políticas correctas
CREATE POLICY "Users can view own notifications" 
ON notifications FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" 
ON notifications FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Service role can insert notifications" 
ON notifications FOR INSERT 
WITH CHECK (true);

-- 7. FUNCIÓN SIMPLE PARA CREAR NOTIFICACIONES DE PRUEBA
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. INSERTAR NOTIFICACIONES DE PRUEBA DIRECTAMENTE
DELETE FROM notifications WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    metadata,
    is_read,
    created_at
) VALUES 
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'Bienvenido a Donde Caiga',
    'Tu sistema de notificaciones está funcionando correctamente',
    'general',
    '{"origen": "sistema"}'::jsonb,
    FALSE,
    NOW()
),
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'Notificación de Prueba',
    'Esta es una segunda notificación para verificar que todo funciona',
    'general',
    '{"origen": "prueba"}'::jsonb,
    FALSE,
    NOW() - INTERVAL '1 hour'
),
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'Sistema Activado',
    'Las notificaciones push están configuradas y listas para usar',
    'general',
    '{"origen": "configuracion"}'::jsonb,
    FALSE,
    NOW() - INTERVAL '2 hours'
);

-- 9. ARREGLAR CHAT - VERIFICAR TABLA MENSAJES
SELECT 'VERIFICANDO TABLA MENSAJES' as status;

-- Verificar que la tabla mensajes existe
CREATE TABLE IF NOT EXISTS mensajes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reserva_id UUID NOT NULL REFERENCES reservas(id) ON DELETE CASCADE,
    remitente_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    mensaje TEXT NOT NULL,
    leido BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índice para mensajes si no existe
CREATE INDEX IF NOT EXISTS idx_mensajes_reserva_created 
ON mensajes(reserva_id, created_at ASC);

-- 10. HABILITAR REALTIME PARA NOTIFICATIONS
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE mensajes;

-- 11. VERIFICAR RESULTADOS
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

-- 13. LIMPIAR CACHE DE SUPABASE
NOTIFY pgrst, 'reload schema';

-- 14. MENSAJE FINAL
SELECT 'ARREGLO COMPLETO - REINICIA LA APP Y PRUEBA' as resultado;