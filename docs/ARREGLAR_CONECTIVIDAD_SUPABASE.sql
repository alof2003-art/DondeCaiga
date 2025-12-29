-- ========================================
-- VERIFICAR Y ARREGLAR CONECTIVIDAD SUPABASE
-- ========================================

-- PASO 1: VERIFICAR QUE LA BASE DE DATOS RESPONDE
SELECT 
    'CONECTIVIDAD SUPABASE' as test,
    NOW() as timestamp,
    'Si ves esto, Supabase funciona correctamente' as resultado;

-- PASO 2: VERIFICAR USUARIOS
SELECT 
    'USUARIOS EN BD' as test,
    COUNT(*) as total_usuarios,
    COUNT(CASE WHEN fcm_token IS NOT NULL THEN 1 END) as con_token
FROM users_profiles;

-- PASO 3: VERIFICAR NOTIFICACIONES
SELECT 
    'NOTIFICACIONES EN BD' as test,
    COUNT(*) as total_notificaciones,
    COUNT(CASE WHEN created_at > NOW() - INTERVAL '1 hour' THEN 1 END) as ultima_hora
FROM notifications;

-- PASO 4: VERIFICAR TRIGGERS
SELECT 
    'TRIGGERS ACTIVOS' as test,
    trigger_name,
    event_manipulation,
    CASE 
        WHEN event_manipulation = 'INSERT' THEN '✅ CORRECTO'
        ELSE '❌ REVISAR'
    END as estado
FROM information_schema.triggers 
WHERE trigger_name LIKE '%push%' OR trigger_name LIKE '%notification%';

-- PASO 5: VERIFICAR FUNCIONES
SELECT 
    'FUNCIONES PUSH' as test,
    routine_name,
    '✅ EXISTE' as estado
FROM information_schema.routines 
WHERE routine_name LIKE '%push%' OR routine_name LIKE '%fcm%' OR routine_name LIKE '%notification%';

-- PASO 6: PROBAR INSERCIÓN DE NOTIFICACIÓN
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    is_read,
    created_at
) 
SELECT 
    id,
    '🔧 Test Conectividad',
    'Si recibes esto, la conectividad Supabase funciona correctamente',
    'connectivity_test',
    FALSE,
    NOW()
FROM users_profiles 
WHERE fcm_token IS NOT NULL 
LIMIT 1;

-- PASO 7: VERIFICAR QUE SE INSERTÓ
SELECT 
    'NOTIFICACIÓN TEST' as test,
    title,
    message,
    created_at,
    '✅ INSERTADA CORRECTAMENTE' as estado
FROM notifications 
WHERE type = 'connectivity_test'
AND created_at > NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC
LIMIT 1;

-- PASO 8: ESTADÍSTICAS FINALES
SELECT 
    '🎯 DIAGNÓSTICO SUPABASE' as titulo,
    'Base de datos: FUNCIONANDO' as bd_status,
    'Triggers: ' || (
        SELECT COUNT(*) FROM information_schema.triggers 
        WHERE trigger_name = 'trigger_send_push_on_notification'
    )::TEXT as triggers_count,
    'Funciones: ' || (
        SELECT COUNT(*) FROM information_schema.routines 
        WHERE routine_name = 'send_push_notification_on_insert'
    )::TEXT as functions_count;