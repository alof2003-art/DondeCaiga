-- ========================================
-- MIGRAR A SISTEMA MÚLTIPLE
-- ========================================

-- PASO 1: MIGRAR DATOS EXISTENTES
INSERT INTO device_user_tokens (device_id, user_id, fcm_token, last_login, is_active)
SELECT 
    LEFT(fcm_token, 20) as device_id,
    id as user_id,
    fcm_token,
    updated_at as last_login,
    TRUE as is_active
FROM users_profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != ''
ON CONFLICT (device_id, user_id) DO NOTHING;

-- PASO 2: VERIFICAR MIGRACIÓN
SELECT 
    'MIGRACIÓN COMPLETADA' as status,
    COUNT(*) as tokens_migrados
FROM device_user_tokens;

-- PASO 3: VER DISPOSITIVOS Y USUARIOS
SELECT 
    device_id,
    COUNT(*) as usuarios_en_dispositivo,
    STRING_AGG(up.email, ', ') as emails,
    MAX(dup.last_login) as ultimo_login
FROM device_user_tokens dup
JOIN users_profiles up ON dup.user_id = up.id
GROUP BY device_id
ORDER BY ultimo_login DESC;

-- PASO 4: PROBAR SISTEMA CON USUARIO ESPECÍFICO
SELECT save_user_fcm_token_multiple(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    (SELECT fcm_token FROM users_profiles WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3')
);

-- PASO 5: VER USUARIOS ACTIVOS POR DISPOSITIVO
SELECT * FROM get_active_users_for_device(
    (SELECT fcm_token FROM users_profiles WHERE fcm_token IS NOT NULL LIMIT 1)
);

-- PASO 6: CREAR NOTIFICACIÓN DE PRUEBA
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    is_read
) VALUES (
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    '🎯 Sistema Múltiple Activo',
    'Ahora puedes cambiar de cuenta sin perder notificaciones!',
    'test_multiple',
    FALSE
);

-- PASO 7: ESTADÍSTICAS FINALES
SELECT 
    'SISTEMA MÚLTIPLE ACTIVADO' as resultado,
    (SELECT COUNT(DISTINCT device_id) FROM device_user_tokens) as dispositivos,
    (SELECT COUNT(*) FROM device_user_tokens) as relaciones_usuario_dispositivo,
    'Usuarios pueden cambiar de cuenta sin perder notificaciones' as beneficio;