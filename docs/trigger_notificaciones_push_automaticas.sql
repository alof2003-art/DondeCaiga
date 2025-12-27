-- =====================================================
-- TRIGGER PARA NOTIFICACIONES PUSH AUTOMÁTICAS
-- =====================================================
-- Este trigger se ejecuta cada vez que se inserta una nueva notificación
-- y automáticamente envía una notificación push al dispositivo del usuario

-- 1. Crear función que envía notificación push
CREATE OR REPLACE FUNCTION enviar_notificacion_push()
RETURNS TRIGGER AS $$
DECLARE
    usuario_fcm_token TEXT;
    usuario_nombre TEXT;
    edge_function_url TEXT;
    payload JSON;
    response_status INTEGER;
BEGIN
    -- Obtener el token FCM del usuario destinatario
    SELECT 
        up.fcm_token,
        up.nombre_completo
    INTO 
        usuario_fcm_token,
        usuario_nombre
    FROM users_profiles up
    WHERE up.user_id = NEW.usuario_id;

    -- Solo enviar si el usuario tiene token FCM
    IF usuario_fcm_token IS NOT NULL AND usuario_fcm_token != '' THEN
        
        -- Configurar la URL de la edge function
        -- IMPORTANTE: Reemplaza 'tu-proyecto' con tu ID real de Supabase
        edge_function_url := 'https://qbuelwmimwcqjesapolr.supabase.co/functions/v1/send-push-notification';
        
        -- Preparar el payload
        payload := json_build_object(
            'fcmToken', usuario_fcm_token,
            'titulo', NEW.titulo,
            'mensaje', NEW.mensaje,
            'tipo', NEW.tipo,
            'usuarioId', NEW.usuario_id,
            'datos', NEW.datos
        );

        -- Log para debug
        RAISE NOTICE 'Enviando notificación push a usuario %: %', NEW.usuario_id, NEW.titulo;

        -- Enviar notificación usando http extension
        -- Nota: Esto requiere que la extensión http esté habilitada
        BEGIN
            SELECT status INTO response_status
            FROM http((
                'POST',
                edge_function_url,
                ARRAY[
                    http_header('Content-Type', 'application/json'),
                    http_header('Authorization', 'Bearer ' || current_setting('app.supabase_anon_key', true))
                ],
                'application/json',
                payload::text
            ));
            
            -- Log del resultado
            IF response_status = 200 THEN
                RAISE NOTICE 'Notificación push enviada exitosamente';
            ELSE
                RAISE WARNING 'Error al enviar notificación push. Status: %', response_status;
            END IF;
            
        EXCEPTION WHEN OTHERS THEN
            -- No fallar el trigger si hay error en la notificación push
            RAISE WARNING 'Error al enviar notificación push: %', SQLERRM;
        END;
        
    ELSE
        RAISE NOTICE 'Usuario % no tiene token FCM configurado', NEW.usuario_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Crear el trigger
DROP TRIGGER IF EXISTS trigger_enviar_notificacion_push ON notificaciones;

CREATE TRIGGER trigger_enviar_notificacion_push
    AFTER INSERT ON notificaciones
    FOR EACH ROW
    EXECUTE FUNCTION enviar_notificacion_push();

-- 3. Habilitar la extensión http (necesaria para hacer requests HTTP)
-- IMPORTANTE: Esto debe ejecutarse como superusuario en Supabase
-- Ve a SQL Editor en Supabase y ejecuta:
CREATE EXTENSION IF NOT EXISTS http;

-- 4. Agregar columna fcm_token a users_profiles si no existe
ALTER TABLE users_profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 5. Crear índice para mejorar performance
CREATE INDEX IF NOT EXISTS idx_users_profiles_fcm_token 
ON users_profiles(fcm_token) 
WHERE fcm_token IS NOT NULL;

-- 6. Función para actualizar el token FCM de un usuario
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

-- 7. Función para obtener el token FCM de un usuario
CREATE OR REPLACE FUNCTION obtener_fcm_token(p_user_id UUID)
RETURNS TEXT AS $$
DECLARE
    token TEXT;
BEGIN
    SELECT fcm_token INTO token
    FROM users_profiles
    WHERE user_id = p_user_id;
    
    RETURN token;
END;
$$ LANGUAGE plpgsql;

-- 8. Función de prueba para enviar notificación manual
CREATE OR REPLACE FUNCTION enviar_notificacion_prueba(
    p_usuario_id UUID,
    p_titulo TEXT DEFAULT 'Notificación de Prueba',
    p_mensaje TEXT DEFAULT 'Esta es una notificación de prueba desde Supabase'
)
RETURNS BOOLEAN AS $$
DECLARE
    nueva_notificacion_id UUID;
BEGIN
    -- Insertar notificación (esto disparará automáticamente el push)
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
    RETURN TRUE;
    
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error al crear notificación de prueba: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- COMENTARIOS Y NOTAS IMPORTANTES
-- =====================================================

/*
CONFIGURACIÓN REQUERIDA:

1. Habilitar extensión HTTP en Supabase:
   - Ve a SQL Editor
   - Ejecuta: CREATE EXTENSION IF NOT EXISTS http;

2. Configurar Edge Function:
   - Desplegar la edge function send-push-notification
   - Configurar FCM_SERVER_KEY en secrets de Supabase

3. Actualizar URL de Edge Function:
   - Reemplaza 'qbuelwmimwcqjesapolr' con tu ID real de Supabase
   - La URL debe ser: https://TU-PROYECTO-ID.supabase.co/functions/v1/send-push-notification

4. Configurar tokens FCM:
   - Los usuarios deben tener su fcm_token guardado en users_profiles
   - Esto se hace automáticamente cuando abren la app

CÓMO PROBAR:

1. Asegúrate de que tu usuario tenga fcm_token:
   SELECT fcm_token FROM users_profiles WHERE user_id = 'tu-user-id';

2. Enviar notificación de prueba:
   SELECT enviar_notificacion_prueba('tu-user-id', 'Título de Prueba', 'Mensaje de Prueba');

3. Verificar logs:
   - En Supabase: Ve a Logs > Functions
   - En la app: Verás logs en la consola de Flutter

FLUJO COMPLETO:
1. Se crea notificación en tabla 'notificaciones'
2. Trigger se ejecuta automáticamente
3. Obtiene fcm_token del usuario
4. Llama a edge function con los datos
5. Edge function envía push via Firebase FCM
6. Usuario recibe notificación en su dispositivo
*/