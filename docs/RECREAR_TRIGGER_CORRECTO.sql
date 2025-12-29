-- =====================================================
-- RECREAR TRIGGER CORRECTO CON URL REAL
-- =====================================================

-- PASO 1: LIMPIAR TRIGGER Y FUNCIÓN EXISTENTES
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications;
DROP FUNCTION IF EXISTS send_push_notification_on_insert();

-- PASO 2: CREAR FUNCIÓN NUEVA CON URL CORRECTA
-- ⚠️ IMPORTANTE: Reemplaza TU_PROJECT_ID y TU_ANON_KEY con los valores reales

CREATE OR REPLACE FUNCTION send_push_notification_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    fcm_token_var TEXT;
    project_url TEXT := 'https://TU_PROJECT_ID.supabase.co';  -- 👈 CAMBIA ESTO
    anon_key TEXT := 'TU_ANON_KEY';  -- 👈 CAMBIA ESTO
BEGIN
    -- Obtener el FCM token del usuario (TABLA CORRECTA: users_profiles)
    SELECT fcm_token INTO fcm_token_var
    FROM users_profiles 
    WHERE id = NEW.user_id 
    AND fcm_token IS NOT NULL
    LIMIT 1;
    
    -- Solo enviar si hay token
    IF fcm_token_var IS NOT NULL THEN
        -- Llamar a la Edge Function
        PERFORM
            net.http_post(
                url := project_url || '/functions/v1/send-push-notification',
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || anon_key
                ),
                body := jsonb_build_object(
                    'fcm_token', fcm_token_var,
                    'title', NEW.title,
                    'body', NEW.message
                )
            );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- PASO 3: CREAR TRIGGER
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_on_insert();

-- PASO 4: VERIFICAR QUE SE CREÓ CORRECTAMENTE
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_send_push_on_notification';

-- =====================================================
-- CÓMO ENCONTRAR TU PROJECT_ID Y ANON_KEY
-- =====================================================

/*
PROJECT_ID:
1. Ve a tu Supabase Dashboard
2. Settings → General
3. Reference ID (ejemplo: abcdefghijklmnop)

ANON_KEY:
1. Ve a tu Supabase Dashboard  
2. Settings → API
3. Project API keys → anon/public key
4. Copia la clave que empieza con "eyJ..."

EJEMPLO DE URL COMPLETA:
https://abcdefghijklmnop.supabase.co/functions/v1/send-push-notification
*/