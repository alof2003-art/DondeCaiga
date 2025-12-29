-- =====================================================
-- PROBAR SISTEMA PUSH COMPLETO - FINAL
-- =====================================================
-- Ejecutar paso a paso en Supabase SQL Editor

-- PASO 1: Verificar estado actual
SELECT '🔍 VERIFICANDO ESTADO ACTUAL' as paso;
SELECT verificar_app_reinstalada();

-- PASO 2: Verificar FCM token de tu usuario
SELECT '🔍 VERIFICANDO FCM TOKEN' as paso;
SELECT 
    id,
    email,
    CASE 
        WHEN fcm_token IS NOT NULL THEN '✅ Token existe: ' || LEFT(fcm_token, 30) || '...'
        ELSE '❌ Token faltante - Abre la app'
    END as token_status
FROM users_profiles 
WHERE email = 'alof2003@gmail.com';

-- PASO 3: Si no hay token, crear uno de prueba (temporal)
-- SOLO ejecutar si el paso anterior muestra "Token faltante"
-- UPDATE users_profiles 
-- SET fcm_token = 'test_token_' || EXTRACT(EPOCH FROM NOW())::text
-- WHERE email = 'alof2003@gmail.com';

-- PASO 4: Probar sistema completo
SELECT '🚀 PROBANDO SISTEMA COMPLETO' as paso;
SELECT test_push_system_complete();

-- PASO 5: Verificar cola de notificaciones
SELECT '📋 VERIFICANDO COLA' as paso;
SELECT 
    id,
    title,
    body,
    status,
    created_at,
    error_message
FROM push_notification_queue 
ORDER BY created_at DESC 
LIMIT 5;

-- PASO 6: Probar notificación manual
SELECT '📱 ENVIANDO NOTIFICACIÓN DE PRUEBA' as paso;
SELECT send_push_notification_v2(
    (SELECT id FROM users_profiles WHERE email = 'alof2003@gmail.com'),
    'Prueba Final 🎉',
    'Si recibes esto, el sistema push funciona perfectamente'
);

-- =====================================================
-- RESULTADOS ESPERADOS:
-- ✅ FCM token existe
-- ✅ Configuración completa
-- ✅ Notificación enviada
-- ✅ Aparece en push_notification_queue con status 'sent'
-- =====================================================