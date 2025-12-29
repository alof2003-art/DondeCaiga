-- =====================================================
-- DIAGNÓSTICO COMPLETO: TRIGGER + EDGE FUNCTION
-- =====================================================

-- 1. VERIFICAR QUE EL TRIGGER EXISTE Y ESTÁ ACTIVO
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_send_push_on_notification';

-- 2. VERIFICAR LA FUNCIÓN DEL TRIGGER
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'send_push_notification_on_insert';

-- 3. VERIFICAR CONFIGURACIÓN DE LA EDGE FUNCTION
SELECT 
    name,
    status,
    created_at,
    updated_at
FROM supabase_functions.functions 
WHERE name = 'send-push-notification';

-- 4. CREAR UNA NOTIFICACIÓN DE PRUEBA CON LOGS
-- (Reemplaza 'TU_USER_ID' con tu ID real)
DO $$
DECLARE
    test_user_id UUID;
    notification_id UUID;
BEGIN
    -- Buscar un usuario (cambia el email por el tuyo)
    SELECT id INTO test_user_id 
    FROM auth.users 
    WHERE email = 'tu_email@gmail.com'  -- 👈 CAMBIA ESTO
    LIMIT 1;
    
    IF test_user_id IS NULL THEN
        -- Si no encuentra por email, toma el primer usuario
        SELECT id INTO test_user_id 
        FROM auth.users 
        ORDER BY created_at DESC 
        LIMIT 1;
    END IF;
    
    RAISE NOTICE 'Usuario seleccionado: %', test_user_id;
    
    -- Insertar notificación de prueba
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        created_at
    ) VALUES (
        test_user_id,
        '🔍 Test Diagnóstico',
        'Esta es una notificación de prueba para diagnosticar el sistema. Timestamp: ' || NOW(),
        'diagnostic_test',
        NOW()
    ) RETURNING id INTO notification_id;
    
    RAISE NOTICE 'Notificación creada con ID: %', notification_id;
    
    -- Esperar un momento para que se ejecute el trigger
    PERFORM pg_sleep(2);
    
    RAISE NOTICE 'Trigger debería haberse ejecutado. Revisa los logs de la Edge Function.';
END $$;

-- 5. VERIFICAR QUE LA NOTIFICACIÓN SE CREÓ
SELECT 
    id,
    user_id,
    title,
    message,
    type,
    created_at,
    read_at
FROM notifications 
WHERE type = 'diagnostic_test'
ORDER BY created_at DESC 
LIMIT 1;

-- 6. VERIFICAR FCM TOKENS DISPONIBLES
SELECT 
    user_id,
    fcm_token,
    created_at,
    updated_at
FROM user_fcm_tokens 
ORDER BY updated_at DESC 
LIMIT 5;

-- 7. PROBAR LA FUNCIÓN MANUALMENTE (OPCIONAL)
-- Solo ejecuta esto si quieres probar la función directamente
/*
SELECT send_push_notification_on_insert();
*/

-- 8. VERIFICAR LOGS DE SUPABASE (Instrucciones)
/*
Para ver los logs de la Edge Function:
1. Ve a tu Supabase Dashboard
2. Edge Functions → send-push-notification
3. Logs tab
4. Busca los logs con emojis 🚀🚀🚀
5. Si no hay logs, el trigger no se está ejecutando
*/