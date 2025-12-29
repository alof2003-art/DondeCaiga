-- PRUEBA COMPLETA DEL SISTEMA DE NOTIFICACIONES
-- Para usuario: alof2003@gmail.com
-- Ejecutar en Supabase SQL Editor

-- =====================================================
-- 1. VERIFICAR ESTADO DEL SISTEMA
-- =====================================================

-- Verificar usuario y token FCM
SELECT 
    '1. Usuario y Token FCM' as paso,
    CASE 
        WHEN id IS NOT NULL AND fcm_token IS NOT NULL THEN '✅ USUARIO CON TOKEN'
        WHEN id IS NOT NULL AND fcm_token IS NULL THEN '❌ USUARIO SIN TOKEN - Abre la app'
        ELSE '❌ USUARIO NO ENCONTRADO'
    END as estado,
    email,
    LEFT(COALESCE(fcm_token, 'NULL'), 30) || '...' as token_preview
FROM users_profiles 
WHERE email = 'alof2003@gmail.com';

-- Verificar trigger principal
SELECT 
    '2. Trigger Push' as paso,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ TRIGGER ACTIVO'
        ELSE '❌ TRIGGER FALTANTE'
    END as estado,
    'trigger_send_push_on_notification' as trigger_name
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_send_push_on_notification'
AND event_manipulation = 'INSERT';

-- Verificar extensión pg_net
SELECT 
    '3. Extensión pg_net' as paso,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ EXTENSIÓN ACTIVA'
        ELSE '❌ EXTENSIÓN FALTANTE'
    END as estado,
    'Necesaria para Edge Functions' as descripcion
FROM pg_extension 
WHERE extname = 'pg_net';

-- =====================================================
-- 2. LIMPIAR NOTIFICACIONES ANTERIORES (OPCIONAL)
-- =====================================================

-- Eliminar notificaciones de prueba anteriores
DELETE FROM notifications 
WHERE user_id = (SELECT id FROM users_profiles WHERE email = 'alof2003@gmail.com')
AND type = 'test'
AND created_at < NOW() - INTERVAL '1 hour';

-- =====================================================
-- 3. ENVIAR NOTIFICACIÓN DE PRUEBA BÁSICA
-- =====================================================

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
    '🔔 Prueba Sistema Push',
    'Notificación de prueba enviada el ' || NOW()::text || '. Si recibes esto en tu celular, el sistema funciona!',
    'test',
    FALSE,
    NOW()
FROM users_profiles 
WHERE email = 'alof2003@gmail.com';

-- =====================================================
-- 4. VERIFICAR QUE SE CREÓ LA NOTIFICACIÓN
-- =====================================================

SELECT 
    '4. Notificación Creada' as paso,
    '✅ NOTIFICACIÓN ENVIADA' as estado,
    title,
    LEFT(message, 50) || '...' as mensaje_preview,
    created_at
FROM notifications 
WHERE user_id = (SELECT id FROM users_profiles WHERE email = 'alof2003@gmail.com')
AND created_at > NOW() - INTERVAL '2 minutes'
ORDER BY created_at DESC 
LIMIT 1;

-- =====================================================
-- 5. PROBAR DIFERENTES TIPOS DE NOTIFICACIONES
-- =====================================================

-- Esperar 3 segundos entre notificaciones
SELECT pg_sleep(3);

-- Notificación de reserva
INSERT INTO notifications (user_id, title, message, type, is_read, metadata) 
SELECT 
    id,
    '🏠 Nueva Reserva',
    'Tienes una nueva solicitud de reserva para revisar',
    'nueva_reserva',
    FALSE,
    '{"test": true, "timestamp": "' || NOW()::text || '"}'::jsonb
FROM users_profiles WHERE email = 'alof2003@gmail.com';

SELECT pg_sleep(3);

-- Notificación de mensaje
INSERT INTO notifications (user_id, title, message, type, is_read, metadata) 
SELECT 
    id,
    '💬 Nuevo Mensaje',
    'Tienes un nuevo mensaje de un huésped',
    'nuevo_mensaje',
    FALSE,
    '{"test": true, "timestamp": "' || NOW()::text || '"}'::jsonb
FROM users_profiles WHERE email = 'alof2003@gmail.com';

SELECT pg_sleep(3);

-- Notificación de reseña
INSERT INTO notifications (user_id, title, message, type, is_read, metadata) 
SELECT 
    id,
    '⭐ Nueva Reseña',
    'Has recibido una nueva reseña de 5 estrellas',
    'nueva_resena',
    FALSE,
    '{"test": true, "calificacion": 5, "timestamp": "' || NOW()::text || '"}'::jsonb
FROM users_profiles WHERE email = 'alof2003@gmail.com';

-- =====================================================
-- 6. VERIFICAR TODAS LAS NOTIFICACIONES ENVIADAS
-- =====================================================

SELECT 
    '6. Resumen de Notificaciones' as paso,
    COUNT(*) as total_enviadas,
    'Revisa tu celular en los próximos 30 segundos' as instruccion
FROM notifications 
WHERE user_id = (SELECT id FROM users_profiles WHERE email = 'alof2003@gmail.com')
AND created_at > NOW() - INTERVAL '5 minutes';

-- =====================================================
-- 7. VER DETALLE DE NOTIFICACIONES RECIENTES
-- =====================================================

SELECT 
    ROW_NUMBER() OVER (ORDER BY created_at DESC) as orden,
    type as tipo,
    title as titulo,
    LEFT(message, 60) || '...' as mensaje,
    CASE 
        WHEN created_at > NOW() - INTERVAL '1 minute' THEN 'Hace menos de 1 min'
        WHEN created_at > NOW() - INTERVAL '5 minutes' THEN 'Hace menos de 5 min'
        ELSE 'Hace más de 5 min'
    END as tiempo,
    CASE 
        WHEN is_read THEN '✅ Leída'
        ELSE '🔔 No leída'
    END as estado_lectura
FROM notifications 
WHERE user_id = (SELECT id FROM users_profiles WHERE email = 'alof2003@gmail.com')
AND created_at > NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- 8. VERIFICAR COLA DE PUSH NOTIFICATIONS
-- =====================================================

SELECT 
    '8. Cola Push Notifications' as paso,
    COUNT(*) as notificaciones_en_cola,
    CASE 
        WHEN COUNT(*) > 0 THEN 'Hay notificaciones pendientes de envío'
        ELSE 'Cola vacía - todas enviadas'
    END as estado
FROM push_notification_queue 
WHERE user_id = (SELECT id FROM users_profiles WHERE email = 'alof2003@gmail.com')
AND created_at > NOW() - INTERVAL '10 minutes';

-- =====================================================
-- 9. INSTRUCCIONES FINALES
-- =====================================================

SELECT 
    '🎯 INSTRUCCIONES FINALES' as titulo,
    'Revisa tu celular TECNO LI7 ahora' as paso_1,
    'Deberías ver 4 notificaciones push' as paso_2,
    'Si no las ves, cierra y abre la app' as paso_3,
    'Las notificaciones aparecen en la bandeja del sistema' as paso_4;

-- =====================================================
-- 10. DIAGNÓSTICO SI NO FUNCIONA
-- =====================================================

-- Solo ejecutar si no recibes notificaciones
/*
SELECT 
    'DIAGNÓSTICO' as seccion,
    CASE 
        WHEN (SELECT fcm_token FROM users_profiles WHERE email = 'alof2003@gmail.com') IS NULL 
        THEN '❌ No hay FCM token - Abre la app'
        WHEN NOT EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'trigger_send_push_on_notification')
        THEN '❌ Trigger no existe - Ejecuta SISTEMA_NOTIFICACIONES_COMPLETO_AUTOMATICO.sql'
        WHEN NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_net')
        THEN '❌ Extensión pg_net faltante - Ejecuta CREATE EXTENSION pg_net;'
        ELSE '✅ Todo configurado correctamente'
    END as problema_detectado;
*/