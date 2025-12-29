-- =====================================================
-- DIAGNÓSTICO SIN EJECUTAR TRIGGER PROBLEMÁTICO
-- =====================================================

-- 1. VER EXTENSIONES HABILITADAS
SELECT 
    extname as extension_name,
    extversion as version,
    CASE 
        WHEN extname = 'pg_net' THEN '✅ NECESARIA PARA TRIGGERS HTTP'
        ELSE '📦 Otra extensión'
    END as descripcion
FROM pg_extension 
ORDER BY extname;

-- 2. VER TRIGGERS EXISTENTES
SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation,
    CASE 
        WHEN trigger_name LIKE '%push%' OR trigger_name LIKE '%notification%' 
        THEN '🔔 TRIGGER DE NOTIFICACIONES'
        ELSE '📋 Otro trigger'
    END as tipo
FROM information_schema.triggers 
WHERE event_object_table IN ('notifications', 'users_profiles')
ORDER BY trigger_name;

-- 3. VER TUS USUARIOS
SELECT 
    id,
    email,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 4. VER FCM TOKENS (TABLA CORRECTA: users_profiles)
SELECT 
    id,
    email,
    CASE 
        WHEN fcm_token IS NULL THEN '❌ NO TOKEN'
        WHEN LENGTH(fcm_token) < 50 THEN '⚠️ TOKEN CORTO: ' || fcm_token
        ELSE '✅ TOKEN OK: ' || LENGTH(fcm_token) || ' chars - ' || LEFT(fcm_token, 30) || '...'
    END as token_status,
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
    created_at
FROM notifications 
ORDER BY created_at DESC 
LIMIT 5;

-- 6. VERIFICAR SI PG_NET ESTÁ DISPONIBLE
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net') 
        THEN '✅ PG_NET HABILITADA - Triggers HTTP funcionarán'
        ELSE '❌ PG_NET NO HABILITADA - Necesitas habilitarla primero'
    END as estado_pg_net;

-- =====================================================
-- RESUMEN DEL DIAGNÓSTICO
-- =====================================================

SELECT 
    '🔍 DIAGNÓSTICO COMPLETADO' as resultado,
    'Revisa los resultados de arriba para ver:' as instrucciones,
    '1. Si tienes pg_net habilitada' as paso_1,
    '2. Si tienes FCM tokens válidos' as paso_2,
    '3. Si existen triggers problemáticos' as paso_3;

-- =====================================================
-- PRÓXIMOS PASOS SEGÚN RESULTADOS
-- =====================================================

/*
SI PG_NET NO ESTÁ HABILITADA:
- Ejecuta: docs/HABILITAR_PG_NET_Y_TRIGGER.sql

SI PG_NET ESTÁ HABILITADA PERO NO HAY TRIGGER:
- Ejecuta la parte del trigger en HABILITAR_PG_NET_Y_TRIGGER.sql

SI TODO ESTÁ BIEN:
- Prueba insertar una notificación manualmente
- Revisa los logs de la Edge Function

PARA PROBAR SIN TRIGGER (SEGURO):
- Usa la Edge Function directamente desde el dashboard
- O llama la función HTTP manualmente
*/