-- =====================================================
-- DIAGNÓSTICO COMPLETO FCM TOKEN - ENCONTRAR EL PROBLEMA
-- =====================================================

-- 1. VERIFICAR ESTADO ACTUAL
SELECT 
    'DIAGNÓSTICO FCM TOKEN' as info,
    'Usuario ID' as componente,
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3' as valor;

-- 2. VERIFICAR FCM TOKEN EN USERS_PROFILES
SELECT 
    'FCM TOKEN EN USERS_PROFILES' as info,
    id,
    email,
    CASE 
        WHEN fcm_token IS NULL THEN '❌ NULL - No se ha generado'
        ELSE '✅ EXISTE: ' || LEFT(fcm_token, 30) || '...'
    END as fcm_status,
    updated_at as ultima_actualizacion
FROM public.users_profiles 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 3. VERIFICAR DEVICE_TOKENS
SELECT 
    'DEVICE TOKENS' as info,
    COUNT(*) as total_tokens,
    STRING_AGG(platform, ', ') as plataformas,
    MAX(created_at) as ultimo_token
FROM public.device_tokens 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 4. VERIFICAR RLS STATUS
SELECT 
    'RLS STATUS' as info,
    tablename,
    CASE 
        WHEN rowsecurity THEN '❌ ACTIVADO (puede bloquear)'
        ELSE '✅ DESACTIVADO (correcto)'
    END as rls_status
FROM pg_tables 
WHERE tablename IN ('users_profiles', 'device_tokens')
AND schemaname = 'public';

-- 5. VERIFICAR CONFIGURACIÓN DE APP
SELECT 
    'CONFIGURACIÓN APP' as info,
    key,
    CASE 
        WHEN key = 'supabase_anon_key' THEN LEFT(value, 20) || '...'
        ELSE value
    END as value_preview
FROM public.app_config
WHERE key IN ('supabase_url', 'supabase_anon_key');

-- 6. FUNCIÓN PARA PROBAR INSERCIÓN MANUAL DE TOKEN
CREATE OR REPLACE FUNCTION probar_insercion_token_manual()
RETURNS TEXT AS $$
DECLARE
    test_token TEXT;
    resultado TEXT;
BEGIN
    -- Generar token de prueba único
    test_token := 'manual_test_token_' || EXTRACT(EPOCH FROM NOW())::text;
    
    BEGIN
        -- Intentar insertar directamente
        UPDATE public.users_profiles 
        SET fcm_token = test_token, updated_at = NOW()
        WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;
        
        IF FOUND THEN
            resultado := '✅ INSERCIÓN MANUAL EXITOSA: ' || test_token;
        ELSE
            resultado := '❌ NO SE ENCONTRÓ EL USUARIO';
        END IF;
        
        RETURN resultado;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN '❌ ERROR AL INSERTAR: ' || SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- 7. FUNCIÓN PARA VERIFICAR PERMISOS DE USUARIO
CREATE OR REPLACE FUNCTION verificar_permisos_usuario()
RETURNS TEXT AS $$
DECLARE
    user_exists BOOLEAN;
    can_update BOOLEAN;
BEGIN
    -- Verificar si el usuario existe
    SELECT EXISTS(
        SELECT 1 FROM public.users_profiles 
        WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
    ) INTO user_exists;
    
    IF NOT user_exists THEN
        RETURN '❌ USUARIO NO EXISTE EN LA BASE DE DATOS';
    END IF;
    
    -- Intentar actualización simple
    BEGIN
        UPDATE public.users_profiles 
        SET updated_at = NOW()
        WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;
        
        can_update := FOUND;
    EXCEPTION WHEN OTHERS THEN
        can_update := FALSE;
    END;
    
    IF can_update THEN
        RETURN '✅ PERMISOS DE ACTUALIZACIÓN CORRECTOS';
    ELSE
        RETURN '❌ NO HAY PERMISOS PARA ACTUALIZAR';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 8. EJECUTAR DIAGNÓSTICOS
SELECT probar_insercion_token_manual();
SELECT verificar_permisos_usuario();

-- 9. MOSTRAR ÚLTIMAS NOTIFICACIONES
SELECT 
    'ÚLTIMAS NOTIFICACIONES' as info,
    COUNT(*) as total,
    MAX(created_at) as ultima_notificacion
FROM public.notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 10. MOSTRAR COLA DE PUSH NOTIFICATIONS
SELECT 
    'COLA PUSH NOTIFICATIONS' as info,
    status,
    COUNT(*) as cantidad,
    MAX(created_at) as ultimo_intento
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
GROUP BY status;

SELECT '🔍 DIAGNÓSTICO COMPLETADO - REVISA LOS RESULTADOS ARRIBA' as resultado;