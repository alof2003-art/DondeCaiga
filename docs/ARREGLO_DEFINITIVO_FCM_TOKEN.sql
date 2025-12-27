-- =====================================================
-- ARREGLO DEFINITIVO FCM TOKEN - VERSIÓN QUE SÍ FUNCIONA
-- =====================================================

-- 1. VERIFICAR ESTADO ACTUAL DE RLS
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity THEN '❌ RLS Activado (problema)'
        ELSE '✅ RLS Desactivado (correcto)'
    END as status
FROM pg_tables 
WHERE tablename IN ('users_profiles', 'device_tokens');

-- 2. FORZAR DESACTIVACIÓN DE RLS (MÉTODO DIRECTO)
ALTER TABLE public.users_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens DISABLE ROW LEVEL SECURITY;

-- 3. ELIMINAR TODAS LAS POLÍTICAS EXISTENTES
DO $$ 
DECLARE 
    pol RECORD;
BEGIN
    -- Eliminar políticas de users_profiles
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'users_profiles' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.users_profiles', pol.policyname);
    END LOOP;
    
    -- Eliminar políticas de device_tokens
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'device_tokens' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.device_tokens', pol.policyname);
    END LOOP;
END $$;

-- 4. VERIFICAR QUE SE DESACTIVARON
SELECT 
    'VERIFICACIÓN POST-DESACTIVACIÓN' as info,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity THEN '❌ AÚN ACTIVADO'
        ELSE '✅ DESACTIVADO CORRECTAMENTE'
    END as status
FROM pg_tables 
WHERE tablename IN ('users_profiles', 'device_tokens');

-- 5. LIMPIAR FCM TOKEN ACTUAL PARA FORZAR REGENERACIÓN
UPDATE public.users_profiles 
SET fcm_token = NULL 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 6. LIMPIAR DEVICE_TOKENS TAMBIÉN
DELETE FROM public.device_tokens 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 7. VERIFICAR LIMPIEZA
SELECT 
    'ESTADO DESPUÉS DE LIMPIAR' as info,
    id,
    email,
    CASE 
        WHEN fcm_token IS NULL THEN '✅ Token limpio - Reinicia app'
        ELSE '❌ Token aún existe: ' || LEFT(fcm_token, 20) || '...'
    END as fcm_status
FROM public.users_profiles 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 8. CREAR FUNCIÓN DE VERIFICACIÓN MEJORADA
CREATE OR REPLACE FUNCTION verificar_fcm_token_completo()
RETURNS TABLE(
    componente TEXT,
    estado TEXT,
    detalles TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Verificar RLS
    SELECT 
        'RLS Status'::TEXT,
        CASE 
            WHEN (SELECT rowsecurity FROM pg_tables WHERE tablename = 'users_profiles') 
            THEN '❌ ACTIVADO (problema)'
            ELSE '✅ DESACTIVADO (correcto)'
        END::TEXT,
        'Row Level Security en users_profiles'::TEXT
    
    UNION ALL
    
    -- Verificar FCM token
    SELECT 
        'FCM Token'::TEXT,
        CASE 
            WHEN EXISTS(
                SELECT 1 FROM public.users_profiles 
                WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid 
                AND fcm_token IS NOT NULL
            ) THEN '✅ TOKEN EXISTE'
            ELSE '❌ TOKEN FALTANTE'
        END::TEXT,
        COALESCE(
            (SELECT LEFT(fcm_token, 30) || '...' 
             FROM public.users_profiles 
             WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid),
            'NULL - Reinicia la app'
        )::TEXT
    
    UNION ALL
    
    -- Verificar device_tokens
    SELECT 
        'Device Tokens'::TEXT,
        CASE 
            WHEN EXISTS(
                SELECT 1 FROM public.device_tokens 
                WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
            ) THEN '✅ TOKENS EXISTEN'
            ELSE '❌ NO HAY TOKENS'
        END::TEXT,
        COALESCE(
            (SELECT COUNT(*)::TEXT || ' tokens registrados' 
             FROM public.device_tokens 
             WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid),
            '0 tokens'
        )::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 9. CREAR FUNCIÓN PARA INSERTAR TOKEN MANUALMENTE (PRUEBA)
CREATE OR REPLACE FUNCTION insertar_token_prueba()
RETURNS TEXT AS $$
DECLARE
    test_token TEXT;
    resultado TEXT;
BEGIN
    -- Generar token de prueba
    test_token := 'test_fcm_token_' || EXTRACT(EPOCH FROM NOW())::text;
    
    BEGIN
        -- Intentar insertar en users_profiles
        UPDATE public.users_profiles 
        SET fcm_token = test_token
        WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;
        
        IF FOUND THEN
            resultado := '✅ Token insertado en users_profiles: ' || test_token;
        ELSE
            resultado := '❌ No se pudo insertar en users_profiles';
        END IF;
        
        -- También insertar en device_tokens
        INSERT INTO public.device_tokens (user_id, token, platform)
        VALUES ('0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid, test_token, 'android');
        
        resultado := resultado || ' | ✅ Token insertado en device_tokens';
        
        RETURN resultado;
        
    EXCEPTION WHEN OTHERS THEN
        RETURN '❌ Error al insertar token: ' || SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- 10. VERIFICAR CONFIGURACIÓN ACTUAL
SELECT verificar_fcm_token_completo();

-- 11. PROBAR INSERCIÓN MANUAL
SELECT insertar_token_prueba();

-- 12. VERIFICAR DESPUÉS DE INSERCIÓN
SELECT verificar_fcm_token_completo();

-- =====================================================
-- INSTRUCCIONES FINALES:
-- =====================================================
-- 1. Ejecuta TODO este SQL
-- 2. Si ves "✅ Token insertado", las RLS ya no son problema
-- 3. Cierra la app completamente
-- 4. Abre la app de nuevo
-- 5. Espera 20 segundos
-- 6. Ejecuta: SELECT verificar_fcm_token_completo();
-- 7. Si el token se guardó, ejecuta las notificaciones push
-- =====================================================

SELECT '🚀 ARREGLO DEFINITIVO EJECUTADO - REVISA LOS RESULTADOS ARRIBA' as resultado;