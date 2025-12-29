-- =====================================================
-- TRIGGER FINAL CON TUS DATOS REALES DE SUPABASE
-- =====================================================

-- PASO 1: HABILITAR LA EXTENSIÓN PG_NET
CREATE EXTENSION IF NOT EXISTS pg_net;

-- PASO 2: LIMPIAR TRIGGER Y FUNCIÓN EXISTENTES
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications;
DROP FUNCTION IF EXISTS send_push_notification_on_insert();

-- PASO 3: CREAR FUNCIÓN CON TUS DATOS REALES
CREATE OR REPLACE FUNCTION send_push_notification_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    fcm_token_var TEXT;
    project_url TEXT := 'https://louehuwimvwsoqesjjau.supabase.co';
    anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvdWVodXdpbXZ3c29xZXNqamF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3OTQ4MTYsImV4cCI6MjA4MDM3MDgxNn0.vhqclBtgt-o_GTNFGsU-pKYK68coeemIjl_CTQl8Rz8';
    request_id BIGINT;
BEGIN
    -- Obtener el FCM token del usuario
    SELECT fcm_token INTO fcm_token_var
    FROM users_profiles 
    WHERE id = NEW.user_id 
    AND fcm_token IS NOT NULL
    LIMIT 1;
    
    -- Solo enviar si hay token
    IF fcm_token_var IS NOT NULL THEN
        -- Llamar a la Edge Function
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
        
        RAISE NOTICE 'Push notification enviada - Request ID: %', request_id;
    ELSE
        RAISE NOTICE 'No FCM token para usuario: %', NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- PASO 4: CREAR TRIGGER
CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_on_insert();

-- PASO 5: VERIFICAR QUE TODO SE CREÓ CORRECTAMENTE
SELECT 
    'PG_NET' as componente,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') 
        THEN '✅ HABILITADA'
        ELSE '❌ NO HABILITADA'
    END as estado
UNION ALL
SELECT 
    'FUNCIÓN' as componente,
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

-- PASO 6: PROBAR CON UNA NOTIFICACIÓN
-- (Cambia 'alof2003@gmail.com' por tu email si es diferente)
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    created_at
) 
SELECT 
    au.id,
    '🚀 Test Final',
    'Probando trigger con tus datos reales - ' || NOW(),
    'test_final',
    NOW()
FROM auth.users au 
WHERE au.email = 'alof2003@gmail.com'
LIMIT 1;

-- PASO 7: VERIFICAR QUE SE CREÓ LA NOTIFICACIÓN
SELECT 
    '🎯 NOTIFICACIÓN DE PRUEBA CREADA' as resultado,
    id,
    user_id,
    title,
    message,
    created_at
FROM notifications 
WHERE type = 'test_final'
ORDER BY created_at DESC 
LIMIT 1;

-- =====================================================
-- INSTRUCCIONES FINALES
-- =====================================================

/*
DESPUÉS DE EJECUTAR ESTE SCRIPT:

1. ✅ pg_net estará habilitada
2. ✅ El trigger estará creado con tus datos reales
3. ✅ Se habrá insertado una notificación de prueba
4. 🔍 REVISA LOS LOGS DE LA EDGE FUNCTION:
   - Ve a Supabase Dashboard
   - Edge Functions → send-push-notification
   - Logs tab
   - Busca logs con 🚀🚀🚀

SI VES LOGS CON 🚀🚀🚀:
- ¡El sistema funciona! El trigger llama a la Edge Function

SI NO VES LOGS:
- Hay un problema con la Edge Function
- Verifica que esté deployada correctamente

SI VES ERRORES EN LOS LOGS:
- Revisa el error específico
- Probablemente sea un problema con Firebase o el token
*/