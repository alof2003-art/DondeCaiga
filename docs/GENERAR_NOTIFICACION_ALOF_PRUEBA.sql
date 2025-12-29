-- ========================================
-- GENERAR NOTIFICACIÓN PRUEBA PARA ALOF
-- Fecha: 2024-12-29
-- Usuario: alof2003@gmail.com
-- ========================================

-- PASO 1: VERIFICAR DATOS DEL USUARIO
SELECT 
    '🔍 DATOS USUARIO ALOF' as info,
    id,
    email,
    nombre,
    CASE 
        WHEN fcm_token IS NOT NULL AND fcm_token != '' 
        THEN '✅ Token disponible: ' || LEFT(fcm_token, 40) || '...'
        ELSE '❌ Sin token FCM'
    END as token_status,
    created_at,
    updated_at
FROM users_profiles 
WHERE email = 'alof2003@gmail.com';

-- PASO 2: VERIFICAR SISTEMA PUSH
SELECT * FROM diagnosticar_sistema_push();

-- PASO 3: GENERAR NOTIFICACIÓN DE PRUEBA DIRECTA
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
    '🎯 Prueba Push Alof',
    'Notificación de prueba generada el ' || NOW()::TEXT,
    'test',
    FALSE,
    NOW()
FROM users_profiles 
WHERE email = 'alof2003@gmail.com';

-- PASO 4: VERIFICAR NOTIFICACIÓN CREADA
SELECT 
    '📋 NOTIFICACIÓN CREADA' as info,
    n.id,
    n.title,
    n.message,
    n.type,
    n.is_read,
    n.created_at,
    up.email as usuario_destino,
    CASE 
        WHEN up.fcm_token IS NOT NULL AND up.fcm_token != '' 
        THEN '✅ Push enviado'
        ELSE '❌ Sin token'
    END as push_status
FROM notifications n
JOIN users_profiles up ON n.user_id = up.id
WHERE up.email = 'alof2003@gmail.com'
ORDER BY n.created_at DESC
LIMIT 1;

-- PASO 5: VERIFICAR LOGS DE PUSH (si existen)
SELECT 
    '📊 ESTADÍSTICAS PUSH' as info,
    COUNT(*) as total_notificaciones,
    COUNT(CASE WHEN up.fcm_token IS NOT NULL THEN 1 END) as con_token,
    COUNT(CASE WHEN up.fcm_token IS NULL THEN 1 END) as sin_token
FROM notifications n
JOIN users_profiles up ON n.user_id = up.id
WHERE up.email = 'alof2003@gmail.com'
AND n.created_at >= NOW() - INTERVAL '1 hour';

-- ========================================
-- INSTRUCCIONES
-- ========================================

/*
🎯 COPIA Y PEGA ESTE SCRIPT EN SUPABASE SQL EDITOR

✅ QUE HACE:
1. Verifica tus datos de usuario
2. Verifica que el sistema push esté funcionando
3. Crea una notificación de prueba específica para ti
4. Verifica que se creó correctamente
5. Muestra estadísticas

📱 RESULTADO ESPERADO:
- Notificación aparece en la app
- Push notification aparece en bandeja del sistema
- Si no aparece push, el problema es el trigger o Edge Function

🔧 SI NO FUNCIONA:
1. Ejecuta primero: docs/SOLUCION_DEFINITIVA_FINAL_LIMPIA.sql
2. Luego ejecuta este script
*/