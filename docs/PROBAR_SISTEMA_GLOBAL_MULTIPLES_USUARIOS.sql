-- ========================================
-- PROBAR SISTEMA GLOBAL CON MÚLTIPLES USUARIOS
-- ========================================

-- PASO 1: VER TODOS LOS USUARIOS REGISTRADOS
SELECT 
    'Usuarios Registrados' as info,
    COUNT(*) as total_usuarios,
    COUNT(CASE WHEN fcm_token IS NOT NULL THEN 1 END) as con_fcm_token,
    COUNT(CASE WHEN fcm_token IS NULL THEN 1 END) as sin_fcm_token
FROM users_profiles;

-- PASO 2: VER DETALLES DE USUARIOS
SELECT 
    id,
    email,
    nombre,
    CASE 
        WHEN fcm_token IS NOT NULL THEN '✅ CON TOKEN'
        ELSE '❌ SIN TOKEN'
    END as token_status,
    CASE 
        WHEN fcm_token IS NOT NULL THEN LEFT(fcm_token, 30) || '...'
        ELSE 'NULL'
    END as token_preview
FROM users_profiles
ORDER BY created_at DESC
LIMIT 10;

-- PASO 3: FUNCIÓN PARA PROBAR CON USUARIO ESPECÍFICO
CREATE OR REPLACE FUNCTION probar_push_usuario_especifico(user_email TEXT)
RETURNS TEXT AS $$
DECLARE
    target_user_id UUID;
    user_has_token BOOLEAN;
    notification_id UUID;
BEGIN
    -- Buscar usuario por email
    SELECT id, (fcm_token IS NOT NULL) INTO target_user_id, user_has_token
    FROM users_profiles 
    WHERE email = user_email;
    
    IF target_user_id IS NULL THEN
        RETURN '❌ Usuario no encontrado: ' || user_email;
    END IF;
    
    IF NOT user_has_token THEN
        RETURN '⚠️ Usuario encontrado pero sin FCM token: ' || user_email || ' (debe abrir la app)';
    END IF;
    
    -- Crear notificación de prueba
    SELECT crear_notificacion_prueba_global(
        target_user_id,
        '🎯 Prueba Personal',
        'Hola ' || user_email || '! Si recibes esto, tu sistema push funciona perfectamente'
    ) INTO notification_id;
    
    RETURN '✅ Notificación enviada a ' || user_email || ' (ID: ' || notification_id || ')';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 4: PROBAR CON TU USUARIO
SELECT probar_push_usuario_especifico('alof2003@gmail.com');

-- PASO 5: FUNCIÓN PARA SIMULAR MÚLTIPLES USUARIOS
CREATE OR REPLACE FUNCTION simular_usuarios_multiples()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    user_count INTEGER;
BEGIN
    -- Contar usuarios con token
    SELECT COUNT(*) INTO user_count
    FROM users_profiles 
    WHERE fcm_token IS NOT NULL AND fcm_token != '';
    
    IF user_count = 0 THEN
        RETURN '❌ No hay usuarios con FCM token. Los usuarios deben abrir la app primero.';
    END IF;
    
    -- Enviar notificación a cada usuario con token
    INSERT INTO notifications (user_id, title, message, type, is_read)
    SELECT 
        id,
        '🌍 Notificación Global #' || ROW_NUMBER() OVER (ORDER BY created_at),
        'Esta es una prueba del sistema global. Tu email: ' || email,
        'global_test',
        FALSE
    FROM users_profiles 
    WHERE fcm_token IS NOT NULL AND fcm_token != ''
    LIMIT 5;  -- Limitar a 5 para no saturar
    
    RETURN '✅ Notificaciones enviadas a ' || LEAST(user_count, 5)::TEXT || ' usuarios con FCM token';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 6: EJECUTAR SIMULACIÓN
SELECT simular_usuarios_multiples();

-- PASO 7: VER NOTIFICACIONES RECIENTES
SELECT 
    n.title,
    n.message,
    up.email as usuario_destinatario,
    n.created_at,
    CASE WHEN up.fcm_token IS NOT NULL THEN '✅ PUSH ENVIADO' ELSE '❌ SIN TOKEN' END as push_status
FROM notifications n
JOIN users_profiles up ON n.user_id = up.id
WHERE n.created_at > NOW() - INTERVAL '1 hour'
ORDER BY n.created_at DESC
LIMIT 10;

-- PASO 8: ESTADÍSTICAS FINALES
SELECT 
    'ESTADÍSTICAS SISTEMA PUSH GLOBAL' as titulo,
    (SELECT COUNT(*) FROM users_profiles) as total_usuarios,
    (SELECT COUNT(*) FROM users_profiles WHERE fcm_token IS NOT NULL) as usuarios_con_token,
    (SELECT COUNT(*) FROM notifications WHERE created_at > NOW() - INTERVAL '1 hour') as notificaciones_ultima_hora;