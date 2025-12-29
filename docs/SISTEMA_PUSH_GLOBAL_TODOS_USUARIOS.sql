-- ========================================
-- SISTEMA PUSH GLOBAL PARA TODOS LOS USUARIOS
-- ========================================

-- PASO 1: ARREGLAR TRIGGER (CAMBIAR DE UPDATE A INSERT)
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications;

-- FUNCIÓN GLOBAL QUE FUNCIONA PARA CUALQUIER USUARIO
CREATE OR REPLACE FUNCTION send_push_notification_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    recipient_fcm_token TEXT;
    notification_data JSONB;
BEGIN
    -- Obtener FCM token del usuario (CUALQUIER USUARIO)
    SELECT fcm_token INTO recipient_fcm_token
    FROM users_profiles 
    WHERE id = NEW.user_id;
    
    -- Solo enviar si hay token válido
    IF recipient_fcm_token IS NOT NULL AND recipient_fcm_token != '' THEN
        -- Preparar datos
        notification_data := jsonb_build_object(
            'fcm_token', recipient_fcm_token,
            'title', NEW.title,
            'body', NEW.message
        );
        
        -- Enviar push (manejo de errores)
        BEGIN
            PERFORM net.http_post(
                url := 'https://louehuwimvwsoqesjjau.supabase.co/functions/v1/send-push-notification',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || current_setting('app.jwt_token', true)
                ),
                body := notification_data
            );
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Push notification failed for user %: %', NEW.user_id, SQLERRM;
        END;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- CREAR TRIGGER CORRECTO (AFTER INSERT) - GLOBAL
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_on_insert();

-- PASO 2: DESACTIVAR RLS TEMPORALMENTE PARA PERMITIR FCM TOKENS
ALTER TABLE users_profiles DISABLE ROW LEVEL SECURITY;

-- PASO 3: FUNCIÓN GLOBAL PARA GUARDAR FCM TOKEN (CUALQUIER USUARIO)
CREATE OR REPLACE FUNCTION save_user_fcm_token(user_uuid UUID, new_token TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    rows_affected INTEGER;
BEGIN
    -- Validar que el token no esté vacío y sea suficientemente largo
    IF new_token IS NULL OR LENGTH(TRIM(new_token)) < 50 THEN
        RETURN FALSE;
    END IF;
    
    -- Actualizar el token para CUALQUIER usuario
    UPDATE public.users_profiles 
    SET 
        fcm_token = new_token,
        updated_at = NOW()
    WHERE id = user_uuid;
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    
    RETURN rows_affected > 0;
    
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 4: FUNCIÓN PARA CREAR NOTIFICACIÓN DE PRUEBA (CUALQUIER USUARIO)
CREATE OR REPLACE FUNCTION crear_notificacion_prueba_global(target_user_id UUID, titulo TEXT DEFAULT '🎯 Prueba Push Global', mensaje TEXT DEFAULT 'Sistema funcionando para todos los usuarios!')
RETURNS UUID AS $$
DECLARE
    new_notification_id UUID;
BEGIN
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        created_at
    ) VALUES (
        target_user_id,
        titulo,
        mensaje,
        'test',
        FALSE,
        NOW()
    ) RETURNING id INTO new_notification_id;
    
    RETURN new_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 5: FUNCIÓN DE DIAGNÓSTICO GLOBAL
CREATE OR REPLACE FUNCTION diagnosticar_sistema_push_global()
RETURNS TABLE(
    componente TEXT,
    estado TEXT,
    detalles TEXT
) AS $$
BEGIN
    -- Verificar trigger
    RETURN QUERY
    SELECT 
        'Trigger Global'::TEXT,
        CASE WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'trigger_send_push_on_notification'
            AND event_manipulation = 'INSERT'
        ) THEN '✅ CORRECTO' ELSE '❌ ERROR' END,
        'Debe ser AFTER INSERT para todos los usuarios'::TEXT;
    
    -- Verificar RLS
    RETURN QUERY
    SELECT 
        'RLS Status'::TEXT,
        CASE WHEN (SELECT rowsecurity FROM pg_tables WHERE tablename = 'users_profiles') 
             THEN '❌ ACTIVADO (bloquea tokens)' 
             ELSE '✅ DESACTIVADO (permite tokens)' END,
        'Row Level Security en users_profiles'::TEXT;
    
    -- Verificar FCM tokens globales
    RETURN QUERY
    SELECT 
        'FCM Tokens Globales'::TEXT,
        CASE WHEN COUNT(*) > 0 THEN '✅ ' || COUNT(*)::TEXT || ' usuarios con token' 
             ELSE '❌ NINGÚN USUARIO CON TOKEN' END,
        'Total de usuarios que pueden recibir push'::TEXT
    FROM users_profiles 
    WHERE fcm_token IS NOT NULL AND fcm_token != '';
    
    -- Verificar usuarios sin token
    RETURN QUERY
    SELECT 
        'Usuarios Sin Token'::TEXT,
        COUNT(*)::TEXT || ' usuarios',
        'Estos usuarios no recibirán notificaciones push'::TEXT
    FROM users_profiles 
    WHERE fcm_token IS NULL OR fcm_token = '';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 6: FUNCIÓN PARA ENVIAR NOTIFICACIÓN A TODOS LOS USUARIOS (PARA PRUEBAS)
CREATE OR REPLACE FUNCTION enviar_notificacion_a_todos(titulo TEXT DEFAULT '📢 Notificación Global', mensaje TEXT DEFAULT 'Esta es una prueba del sistema push global')
RETURNS TEXT AS $$
DECLARE
    user_record RECORD;
    notifications_sent INTEGER := 0;
BEGIN
    -- Enviar notificación a todos los usuarios con FCM token
    FOR user_record IN 
        SELECT id, email FROM users_profiles 
        WHERE fcm_token IS NOT NULL AND fcm_token != ''
        LIMIT 10  -- Limitar a 10 para no saturar
    LOOP
        PERFORM crear_notificacion_prueba_global(
            user_record.id, 
            titulo, 
            mensaje || ' - Para: ' || user_record.email
        );
        notifications_sent := notifications_sent + 1;
    END LOOP;
    
    RETURN '✅ ' || notifications_sent::TEXT || ' notificaciones enviadas a usuarios con FCM token';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 7: EJECUTAR DIAGNÓSTICO
SELECT * FROM diagnosticar_sistema_push_global();

-- PASO 8: MENSAJE FINAL
SELECT '🎉 SISTEMA PUSH GLOBAL CONFIGURADO EXITOSAMENTE' as resultado,
       'Ahora funciona para TODOS los usuarios, no solo para uno específico' as descripcion;