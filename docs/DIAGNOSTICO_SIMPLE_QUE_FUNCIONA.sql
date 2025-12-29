-- =====================================================
-- DIAGNÓSTICO SIMPLE QUE SÍ FUNCIONA
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
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'send_push_notification_on_insert';

-- 3. VER TODOS LOS USUARIOS PARA ENCONTRAR EL TUYO
SELECT 
    id,
    email,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 10;

-- 4. VERIFICAR FCM TOKENS DISPONIBLES
SELECT 
    id,
    email,
    CASE 
        WHEN fcm_token IS NULL THEN '❌ NO TOKEN'
        ELSE '✅ TOKEN: ' || LEFT(fcm_token, 20) || '...'
    END as token_status,
    created_at,
    updated_at
FROM users_profiles 
ORDER BY updated_at DESC 
LIMIT 5;

-- 5. VER NOTIFICACIONES RECIENTES
SELECT 
    id,
    user_id,
    title,
    message,
    type,
    created_at,
    read_at
FROM notifications 
ORDER BY created_at DESC 
LIMIT 5;

-- =====================================================
-- AHORA VAMOS A CREAR UNA NOTIFICACIÓN DE PRUEBA
-- =====================================================

-- PASO A: Encuentra tu user_id de la consulta #3 de arriba
-- PASO B: Reemplaza 'TU_USER_ID_AQUI' con tu ID real

INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    created_at
) VALUES (
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',  -- 👈 CAMBIA ESTO POR TU USER_ID REAL
    '🔍 Test Diagnóstico Simple',
    'Probando si el trigger funciona - ' || NOW(),
    'diagnostic_test',
    NOW()
);

-- ALTERNATIVA: Si sabes tu email, usa esta versión
/*
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    created_at
) 
SELECT 
    au.id,
    '🔍 Test con Email',
    'Probando trigger con email - ' || NOW(),
    'diagnostic_test',
    NOW()
FROM auth.users au 
WHERE au.email = 'tu_email@gmail.com';  -- 👈 CAMBIA POR TU EMAIL
*/

-- 6. VERIFICAR QUE LA NOTIFICACIÓN SE CREÓ
SELECT 
    id,
    user_id,
    title,
    message,
    type,
    created_at
FROM notifications 
WHERE type = 'diagnostic_test'
ORDER BY created_at DESC 
LIMIT 3;

-- =====================================================
-- INSTRUCCIONES PARA REVISAR LOGS
-- =====================================================

/*
DESPUÉS DE EJECUTAR LA NOTIFICACIÓN DE PRUEBA:

1. Ve a Supabase Dashboard
2. Edge Functions → send-push-notification
3. Logs tab
4. Busca logs con 🚀🚀🚀

SI NO VES LOGS:
- El trigger no se está ejecutando
- Hay que recrear el trigger

SI VES LOGS:
- El trigger funciona
- Revisar qué error aparece en los logs
*/