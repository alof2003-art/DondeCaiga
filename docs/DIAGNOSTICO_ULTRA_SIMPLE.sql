-- =====================================================
-- DIAGNÓSTICO ULTRA SIMPLE - NOMBRES CORRECTOS
-- =====================================================

-- 1. VER TODAS LAS TABLAS DISPONIBLES
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users_profiles', 'notifications', 'user_fcm_tokens')
ORDER BY table_name;

-- 2. VER TRIGGERS EXISTENTES
SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name LIKE '%push%' OR trigger_name LIKE '%notification%';

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
        ELSE '✅ TOKEN OK: ' || LEFT(fcm_token, 30) || '...'
    END as token_status
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
LIMIT 3;

-- =====================================================
-- CREAR NOTIFICACIÓN DE PRUEBA SIMPLE
-- =====================================================

-- Opción 1: Con tu email (CAMBIA EL EMAIL)
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    created_at
) 
SELECT 
    au.id,
    '🔍 Test Simple',
    'Probando sistema - ' || NOW(),
    'test_simple',
    NOW()
FROM auth.users au 
WHERE au.email = 'alof2003@gmail.com'  -- 👈 CAMBIA POR TU EMAIL
LIMIT 1;

-- Opción 2: Si no sabes tu email, usa el primer usuario
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
    '🔍 Test Primer Usuario',
    'Probando con primer usuario - ' || NOW(),
    'test_simple',
    NOW()
FROM auth.users au 
ORDER BY created_at DESC
LIMIT 1;
*/

-- 6. VERIFICAR QUE SE CREÓ LA NOTIFICACIÓN
SELECT 
    'NOTIFICACIÓN CREADA' as resultado,
    id,
    user_id,
    title,
    message,
    created_at
FROM notifications 
WHERE type = 'test_simple'
ORDER BY created_at DESC 
LIMIT 1;