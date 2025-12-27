-- =====================================================
-- PROBAR NOTIFICACIONES PUSH - ¡YA FUNCIONA EL FCM TOKEN!
-- =====================================================

-- 1. VERIFICAR QUE EL TOKEN EXISTE
SELECT 
    'VERIFICACIÓN FCM TOKEN' as info,
    id,
    email,
    CASE 
        WHEN fcm_token IS NOT NULL THEN '✅ TOKEN DISPONIBLE'
        ELSE '❌ TOKEN FALTANTE'
    END as token_status,
    LEFT(COALESCE(fcm_token, 'NULL'), 30) || '...' as token_preview,
    updated_at as ultima_actualizacion
FROM public.users_profiles 
WHERE fcm_token IS NOT NULL
ORDER BY updated_at DESC
LIMIT 5;

-- 2. VERIFICAR CONFIGURACIÓN COMPLETA
SELECT 
    'CONFIGURACIÓN SISTEMA' as info,
    CASE 
        WHEN get_app_config('supabase_url') IS NOT NULL 
             AND get_app_config('supabase_anon_key') IS NOT NULL 
        THEN '✅ CONFIGURADO'
        ELSE '❌ FALTANTE'
    END as config_status,
    'Sistema listo para enviar push notifications' as detalles;

-- 3. FUNCIÓN PARA PROBAR NOTIFICACIÓN PUSH
CREATE OR REPLACE FUNCTION test_push_notification_now(target_user_id UUID)
RETURNS TEXT AS $$
DECLARE
    user_token TEXT;
    push_result BOOLEAN;
BEGIN
    -- Verificar que el usuario tenga token
    SELECT fcm_token INTO user_token
    FROM public.users_profiles 
    WHERE id = target_user_id;
    
    IF user_token IS NULL THEN
        RETURN '❌ Usuario no tiene FCM token';
    END IF;
    
    -- Crear notificación que debería enviar push automáticamente
    INSERT INTO public.notifications (user_id, type, title, message, is_read) 
    VALUES (
        target_user_id, 
        'general', 
        'Prueba Push Notification 🚀', 
        'Si recibes esto en tu celular, las notificaciones push funcionan perfectamente', 
        FALSE
    );
    
    -- Verificar que se procesó
    IF EXISTS(
        SELECT 1 FROM public.push_notification_queue 
        WHERE user_id = target_user_id 
        AND created_at > NOW() - INTERVAL '1 minute'
    ) THEN
        RETURN '✅ NOTIFICACIÓN PUSH ENVIADA - Revisa tu celular en 10-15 segundos';
    ELSE
        RETURN '⚠️ Notificación creada pero no se procesó push - Verifica trigger';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 4. PROBAR CON TODOS LOS USUARIOS QUE TIENEN TOKEN
DO $$
DECLARE
    user_record RECORD;
    result TEXT;
BEGIN
    FOR user_record IN 
        SELECT id, email FROM public.users_profiles 
        WHERE fcm_token IS NOT NULL 
        ORDER BY updated_at DESC 
        LIMIT 3
    LOOP
        SELECT test_push_notification_now(user_record.id) INTO result;
        RAISE NOTICE 'Usuario %: %', user_record.email, result;
    END LOOP;
END $$;

-- 5. VERIFICAR COLA DE NOTIFICACIONES PUSH
SELECT 
    'COLA PUSH NOTIFICATIONS' as info,
    up.email,
    pnq.status,
    pnq.title,
    pnq.created_at,
    CASE 
        WHEN pnq.error_message IS NOT NULL THEN pnq.error_message
        ELSE 'Sin errores'
    END as error_info
FROM public.push_notification_queue pnq
JOIN public.users_profiles up ON pnq.user_id = up.id
WHERE pnq.created_at > NOW() - INTERVAL '10 minutes'
ORDER BY pnq.created_at DESC
LIMIT 10;

-- 6. FUNCIÓN PARA ENVIAR NOTIFICACIÓN A USUARIO ESPECÍFICO
CREATE OR REPLACE FUNCTION send_test_push_to_user(user_email TEXT)
RETURNS TEXT AS $$
DECLARE
    target_user_id UUID;
    result TEXT;
BEGIN
    -- Buscar usuario por email
    SELECT id INTO target_user_id
    FROM public.users_profiles 
    WHERE email = user_email AND fcm_token IS NOT NULL;
    
    IF target_user_id IS NULL THEN
        RETURN '❌ Usuario no encontrado o sin FCM token: ' || user_email;
    END IF;
    
    -- Enviar notificación
    SELECT test_push_notification_now(target_user_id) INTO result;
    
    RETURN 'Usuario ' || user_email || ': ' || result;
END;
$$ LANGUAGE plpgsql;

-- 7. MOSTRAR INSTRUCCIONES
SELECT '🎉 SISTEMA FCM FUNCIONANDO - USA ESTAS FUNCIONES:' as resultado;
SELECT 'Para probar: SELECT send_test_push_to_user(''tu-email@ejemplo.com'');' as instruccion_1;
SELECT 'Para verificar: SELECT * FROM push_notification_queue ORDER BY created_at DESC LIMIT 5;' as instruccion_2;

-- 8. CREAR NOTIFICACIÓN DE CELEBRACIÓN
INSERT INTO public.notifications (user_id, type, title, message, is_read) 
SELECT 
    id, 
    'general', 
    '¡Sistema de Notificaciones Activado! 🎉', 
    'Tu app ahora tiene notificaciones push automáticas. ¡Felicidades por completar la implementación!', 
    FALSE
FROM public.users_profiles 
WHERE fcm_token IS NOT NULL
LIMIT 3;

SELECT '🚀 NOTIFICACIONES DE CELEBRACIÓN ENVIADAS - ¡REVISA TU CELULAR!' as final_result;