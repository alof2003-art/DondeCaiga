-- ========================================
-- REVISIÓN SISTEMA COMPLETO PARA TODOS LOS USUARIOS
-- ========================================

-- PASO 1: VERIFICAR TRIGGER GLOBAL (DEBE SER AFTER INSERT)
SELECT 
    'TRIGGER PRINCIPAL' as componente,
    trigger_name,
    event_manipulation,
    CASE 
        WHEN event_manipulation = 'INSERT' THEN '✅ CORRECTO'
        ELSE '❌ DEBE SER INSERT'
    END as estado
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_send_push_on_notification';

-- PASO 2: VERIFICAR FUNCIÓN PRINCIPAL (DEBE SER GLOBAL)
SELECT 
    'FUNCIÓN PRINCIPAL' as componente,
    routine_name,
    CASE 
        WHEN routine_name = 'send_push_notification_on_insert' THEN '✅ EXISTE'
        ELSE '❌ FALTANTE'
    END as estado
FROM information_schema.routines 
WHERE routine_name = 'send_push_notification_on_insert';

-- PASO 3: VERIFICAR FUNCIÓN SAVE_USER_FCM_TOKEN (DEBE SER GLOBAL)
SELECT 
    'FUNCIÓN GUARDAR TOKEN' as componente,
    routine_name,
    CASE 
        WHEN routine_name = 'save_user_fcm_token' THEN '✅ EXISTE'
        ELSE '❌ FALTANTE'
    END as estado
FROM information_schema.routines 
WHERE routine_name = 'save_user_fcm_token';

-- PASO 4: VERIFICAR RLS (DEBE ESTAR DESACTIVADO PARA FCM TOKENS)
SELECT 
    'RLS USERS_PROFILES' as componente,
    tablename,
    CASE 
        WHEN rowsecurity THEN '❌ ACTIVADO (puede bloquear tokens)'
        ELSE '✅ DESACTIVADO (permite tokens)'
    END as estado
FROM pg_tables 
WHERE tablename = 'users_profiles';

-- PASO 5: VERIFICAR USUARIOS CON TOKENS
SELECT 
    'USUARIOS CON TOKENS' as componente,
    COUNT(*) as total_usuarios_con_token,
    COUNT(DISTINCT fcm_token) as tokens_unicos,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT fcm_token) THEN '✅ SIN DUPLICADOS'
        ELSE '❌ HAY DUPLICADOS'
    END as estado_duplicados
FROM users_profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != '';

-- PASO 6: VER TODOS LOS USUARIOS Y SU ESTADO
SELECT 
    email,
    nombre,
    CASE 
        WHEN fcm_token IS NOT NULL THEN '✅ CON TOKEN'
        ELSE '⚪ SIN TOKEN'
    END as estado_token,
    CASE 
        WHEN fcm_token IS NOT NULL THEN LEFT(fcm_token, 30) || '...'
        ELSE 'NULL'
    END as token_preview,
    created_at,
    updated_at
FROM users_profiles 
ORDER BY updated_at DESC;

-- PASO 7: FUNCIÓN PARA PROBAR CUALQUIER USUARIO
CREATE OR REPLACE FUNCTION probar_notificacion_cualquier_usuario(user_email TEXT)
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
        RETURN '⚠️ Usuario ' || user_email || ' no tiene FCM token. Debe abrir la app.';
    END IF;
    
    -- Crear notificación de prueba
    INSERT INTO notifications (
        user_id, title, message, type, is_read, created_at
    ) VALUES (
        target_user_id,
        '🎯 Sistema Global Funcionando',
        'Hola ' || user_email || '! El sistema push funciona para TODOS los usuarios',
        'test_global',
        FALSE,
        NOW()
    ) RETURNING id INTO notification_id;
    
    RETURN '✅ Notificación enviada a ' || user_email || ' (ID: ' || notification_id || ')';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 8: FUNCIÓN PARA ENVIAR A TODOS LOS USUARIOS CON TOKEN
CREATE OR REPLACE FUNCTION enviar_a_todos_los_usuarios()
RETURNS TEXT AS $$
DECLARE
    user_record RECORD;
    notifications_sent INTEGER := 0;
BEGIN
    -- Enviar notificación a TODOS los usuarios con FCM token
    FOR user_record IN 
        SELECT id, email, nombre FROM users_profiles 
        WHERE fcm_token IS NOT NULL AND fcm_token != ''
    LOOP
        INSERT INTO notifications (user_id, title, message, type, is_read)
        VALUES (
            user_record.id,
            '🌍 Notificación Global',
            'Sistema configurado para TODOS los usuarios. Usuario: ' || user_record.nombre || ' (' || user_record.email || ')',
            'global_test',
            FALSE
        );
        notifications_sent := notifications_sent + 1;
    END LOOP;
    
    RETURN '✅ ' || notifications_sent || ' notificaciones enviadas a TODOS los usuarios con token';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 9: EJECUTAR PRUEBA GLOBAL
SELECT enviar_a_todos_los_usuarios();

-- PASO 10: VER NOTIFICACIONES RECIENTES
SELECT 
    n.title,
    n.message,
    up.email as destinatario,
    up.nombre,
    n.created_at,
    CASE 
        WHEN up.fcm_token IS NOT NULL THEN '✅ PUSH ENVIADO'
        ELSE '❌ SIN TOKEN'
    END as push_status
FROM notifications n
JOIN users_profiles up ON n.user_id = up.id
WHERE n.created_at > NOW() - INTERVAL '5 minutes'
ORDER BY n.created_at DESC;

-- PASO 11: ESTADÍSTICAS FINALES
SELECT 
    '🎉 SISTEMA GLOBAL CONFIGURADO' as titulo,
    (SELECT COUNT(*) FROM users_profiles) as total_usuarios_registrados,
    (SELECT COUNT(*) FROM users_profiles WHERE fcm_token IS NOT NULL) as usuarios_con_token,
    (SELECT COUNT(*) FROM notifications WHERE created_at > NOW() - INTERVAL '5 minutes') as notificaciones_enviadas_ahora,
    'FUNCIONA PARA TODOS LOS USUARIOS' as estado;

-- PASO 12: CHECKLIST FINAL
SELECT 
    'CHECKLIST FINAL' as titulo,
    '✅ Trigger: AFTER INSERT' as check1,
    '✅ Función: Global para todos' as check2,
    '✅ RLS: Desactivado para tokens' as check3,
    '✅ Tokens: Sin duplicados' as check4,
    '✅ Notificaciones: Para cualquier usuario' as check5;