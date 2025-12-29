-- ========================================
-- PROBAR TOKENS ÚNICOS DESPUÉS DE LIMPIEZA
-- ========================================

-- PASO 1: VERIFICAR QUE NO HAY DUPLICADOS
SELECT 
    'VERIFICACIÓN POST-LIMPIEZA' as check_type,
    COUNT(DISTINCT fcm_token) as tokens_unicos,
    COUNT(*) as usuarios_con_token,
    COUNT(*) - COUNT(DISTINCT fcm_token) as duplicados_restantes
FROM users_profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != '';

-- PASO 2: VER ESTADO ACTUAL DE TODOS LOS USUARIOS
SELECT 
    email,
    nombre,
    CASE 
        WHEN fcm_token IS NOT NULL THEN '✅ CON TOKEN ÚNICO'
        ELSE '❌ SIN TOKEN'
    END as estado_token,
    CASE 
        WHEN fcm_token IS NOT NULL THEN LEFT(fcm_token, 30) || '...'
        ELSE 'NULL - Debe reabrir app'
    END as token_preview,
    updated_at
FROM users_profiles 
ORDER BY updated_at DESC;

-- PASO 3: FUNCIÓN PARA PROBAR NOTIFICACIÓN A USUARIO ESPECÍFICO
CREATE OR REPLACE FUNCTION probar_notificacion_usuario(user_email TEXT)
RETURNS TEXT AS $$
DECLARE
    target_user_id UUID;
    user_has_token BOOLEAN;
    notification_id UUID;
BEGIN
    -- Buscar usuario
    SELECT id, (fcm_token IS NOT NULL) INTO target_user_id, user_has_token
    FROM users_profiles 
    WHERE email = user_email;
    
    IF target_user_id IS NULL THEN
        RETURN '❌ Usuario no encontrado: ' || user_email;
    END IF;
    
    IF NOT user_has_token THEN
        RETURN '⚠️ Usuario ' || user_email || ' no tiene FCM token. Debe reabrir la app.';
    END IF;
    
    -- Crear notificación de prueba
    INSERT INTO notifications (
        user_id, title, message, type, is_read, created_at
    ) VALUES (
        target_user_id,
        '🎯 Prueba Token Único',
        'Hola ' || user_email || '! Tu token FCM es único y funcional',
        'test_unique',
        FALSE,
        NOW()
    ) RETURNING id INTO notification_id;
    
    RETURN '✅ Notificación enviada a ' || user_email || ' (ID: ' || notification_id || ')';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 4: PROBAR CON USUARIOS ESPECÍFICOS
SELECT probar_notificacion_usuario('alof2003@gmail.com');
SELECT probar_notificacion_usuario('mpattydaquilema@gmail.com');

-- PASO 5: FUNCIÓN PARA SIMULAR MÚLTIPLES USUARIOS CON TOKENS ÚNICOS
CREATE OR REPLACE FUNCTION simular_tokens_unicos()
RETURNS TEXT AS $$
DECLARE
    user_record RECORD;
    notifications_sent INTEGER := 0;
BEGIN
    -- Enviar notificación a cada usuario con token único
    FOR user_record IN 
        SELECT id, email FROM users_profiles 
        WHERE fcm_token IS NOT NULL AND fcm_token != ''
    LOOP
        INSERT INTO notifications (user_id, title, message, type, is_read)
        VALUES (
            user_record.id,
            '🌟 Token Único Verificado',
            'Tu token FCM es único para: ' || user_record.email,
            'unique_test',
            FALSE
        );
        notifications_sent := notifications_sent + 1;
    END LOOP;
    
    RETURN '✅ ' || notifications_sent || ' notificaciones enviadas a usuarios con tokens únicos';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 6: EJECUTAR SIMULACIÓN
SELECT simular_tokens_unicos();

-- PASO 7: VER NOTIFICACIONES RECIENTES
SELECT 
    n.title,
    n.message,
    up.email as destinatario,
    n.created_at,
    CASE 
        WHEN up.fcm_token IS NOT NULL THEN '✅ PUSH ENVIADO'
        ELSE '❌ SIN TOKEN'
    END as push_status
FROM notifications n
JOIN users_profiles up ON n.user_id = up.id
WHERE n.created_at > NOW() - INTERVAL '10 minutes'
ORDER BY n.created_at DESC;

-- PASO 8: ESTADÍSTICAS FINALES
SELECT 
    'ESTADÍSTICAS FINALES' as titulo,
    (SELECT COUNT(*) FROM users_profiles) as total_usuarios,
    (SELECT COUNT(*) FROM users_profiles WHERE fcm_token IS NOT NULL) as usuarios_con_token,
    (SELECT COUNT(DISTINCT fcm_token) FROM users_profiles WHERE fcm_token IS NOT NULL) as tokens_unicos,
    (SELECT COUNT(*) FROM notifications WHERE created_at > NOW() - INTERVAL '10 minutes') as notificaciones_recientes;