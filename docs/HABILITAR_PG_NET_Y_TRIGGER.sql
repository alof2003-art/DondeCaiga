-- =====================================================
-- HABILITAR PG_NET Y CREAR TRIGGER CORRECTO
-- =====================================================

-- PASO 1: HABILITAR LA EXTENSIÓN PG_NET
-- Esta extensión permite hacer llamadas HTTP desde PostgreSQL
CREATE EXTENSION IF NOT EXISTS pg_net;

-- PASO 2: VERIFICAR QUE SE HABILITÓ CORRECTAMENTE
SELECT 
    extname as extension_name,
    extversion as version
FROM pg_extension 
WHERE extname = 'pg_net';

-- PASO 3: LIMPIAR TRIGGER Y FUNCIÓN EXISTENTES
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications;
DROP FUNCTION IF EXISTS send_push_notification_on_insert();

-- PASO 4: CREAR FUNCIÓN CON PG_NET
-- ⚠️ IMPORTANTE: Reemplaza TU_PROJECT_ID y TU_ANON_KEY con los valores reales

CREATE OR REPLACE FUNCTION send_push_notification_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    fcm_token_var TEXT;
    project_url TEXT := 'https://TU_PROJECT_ID.supabase.co';  -- 👈 CAMBIA ESTO
    anon_key TEXT := 'TU_ANON_KEY';  -- 👈 CAMBIA ESTO
    request_id BIGINT;
BEGIN
    -- Obtener el FCM token del usuario (TABLA CORRECTA: users_profiles)
    SELECT fcm_token INTO fcm_token_var
    FROM users_profiles 
    WHERE id = NEW.user_id 
    AND fcm_token IS NOT NULL
    LIMIT 1;
    
    -- Solo enviar si hay token
    IF fcm_token_var IS NOT NULL THEN
        -- Llamar a la Edge Function usando pg_net
        SELECT net.http_post(
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
        ) INTO request_id;
        
        -- Log para debug (opcional)
        RAISE NOTICE 'Push notification request sent with ID: %', request_id;
    ELSE
        RAISE NOTICE 'No FCM token found for user: %', NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- PASO 5: CREAR TRIGGER
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_on_insert();

-- PASO 6: VERIFICAR QUE TODO SE CREÓ CORRECTAMENTE
SELECT 
    'EXTENSIÓN PG_NET' as componente,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') 
        THEN '✅ HABILITADA'
        ELSE '❌ NO HABILITADA'
    END as estado
UNION ALL
SELECT 
    'FUNCIÓN TRIGGER' as componente,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'send_push_notification_on_insert') 
        THEN '✅ CREADA'
        ELSE '❌ NO CREADA'
    END as estado
UNION ALL
SELECT 
    'TRIGGER' as componente,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'trigger_send_push_on_notification') 
        THEN '✅ CREADO'
        ELSE '❌ NO CREADO'
    END as estado;

-- =====================================================
-- INSTRUCCIONES PARA COMPLETAR LA CONFIGURACIÓN
-- =====================================================

/*
ANTES DE EJECUTAR ESTE SCRIPT:

1. ENCONTRAR TU PROJECT_ID:
   - Ve a Supabase Dashboard
   - La URL es: https://supabase.com/dashboard/project/TU_PROJECT_ID
   - O Settings → General → Reference ID

2. ENCONTRAR TU ANON_KEY:
   - Ve a Supabase Dashboard
   - Settings → API
   - Copia "anon / public" key (empieza con "eyJ...")

3. REEMPLAZAR EN EL SCRIPT:
   - Cambia 'TU_PROJECT_ID' por tu ID real
   - Cambia 'TU_ANON_KEY' por tu key real

4. EJECUTAR EL SCRIPT COMPLETO

5. PROBAR CON UNA NOTIFICACIÓN:
   INSERT INTO notifications (user_id, title, message, type) 
   VALUES ('tu-user-id', 'Test', 'Mensaje de prueba', 'test');
*/