-- =====================================================
-- CONFIGURACIÓN COMPLETA NOTIFICACIONES PUSH
-- =====================================================
-- Ejecuta este código en el SQL Editor de Supabase

-- 1. Habilitar extensión HTTP (necesaria para enviar requests)
CREATE EXTENSION IF NOT EXISTS http;

-- 2. Agregar columna fcm_token a users_profiles
ALTER TABLE users_profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 3. Crear índice para mejorar performance
CREATE INDEX IF NOT EXISTS idx_users_profiles_fcm_token 
ON users_profiles(fcm_token) 
WHERE fcm_token IS NOT NULL;

-- 4. Función para actualizar el token FCM de un usuario
CREATE OR REPLACE FUNCTION actualizar_fcm_token(
    p_user_id UUID,
    p_fcm_token TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE users_profiles 
    SET fcm_token = p_fcm_token,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    IF FOUND THEN
        RAISE NOTICE 'Token FCM actualizado para usuario %', p_user_id;
        RETURN TRUE;
    ELSE
        RAISE WARNING 'No se pudo actualizar token FCM para usuario %', p_user_id;
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 5. Función de prueba para crear notificación (sin push automático por ahora)
CREATE OR REPLACE FUNCTION crear_notificacion_prueba(
    p_usuario_id UUID,
    p_titulo TEXT DEFAULT 'Notificación de Prueba',
    p_mensaje TEXT DEFAULT 'Esta es una notificación de prueba desde Supabase'
)
RETURNS UUID AS $$
DECLARE
    nueva_notificacion_id UUID;
BEGIN
    -- Insertar notificación
    INSERT INTO notificaciones (
        usuario_id,
        titulo,
        mensaje,
        tipo,
        datos,
        leida,
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

-- =====================================================
-- INSTRUCCIONES PARA PROBAR
-- =====================================================

/*
DESPUÉS DE EJECUTAR ESTE SQL:

1. Abre tu app en el celular
2. Inicia sesión con tu usuario
3. El token FCM se guardará automáticamente

4. Para probar, ejecuta en Supabase:
   SELECT crear_notificacion_prueba('tu-user-id-aqui');

5. Verifica que se creó la notificación:
   SELECT * FROM notificaciones WHERE usuario_id = 'tu-user-id-aqui' ORDER BY created_at DESC LIMIT 5;

6. Verifica que tu token FCM se guardó:
   SELECT fcm_token FROM users_profiles WHERE user_id = 'tu-user-id-aqui';

NOTA: Por ahora las notificaciones push automáticas están deshabilitadas.
Una vez que confirmes que todo funciona, activaremos el trigger automático.
*/