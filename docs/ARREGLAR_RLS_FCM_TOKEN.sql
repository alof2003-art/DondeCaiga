-- =====================================================
-- ARREGLAR RLS PARA FCM TOKEN - DIAGNÓSTICO COMPLETO
-- =====================================================

-- 1. VERIFICAR POLÍTICAS ACTUALES DE USERS_PROFILES
SELECT 
    'POLÍTICAS RLS USERS_PROFILES' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users_profiles'
ORDER BY policyname;

-- 2. VERIFICAR SI RLS ESTÁ HABILITADO
SELECT 
    'RLS STATUS' as info,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'users_profiles';

-- 3. CREAR POLÍTICA ESPECÍFICA PARA FCM TOKEN
DROP POLICY IF EXISTS "Users can update their own fcm_token" ON public.users_profiles;
CREATE POLICY "Users can update their own fcm_token" 
ON public.users_profiles 
FOR UPDATE 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 4. CREAR POLÍTICA PARA SELECT (SI NO EXISTE)
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users_profiles;
CREATE POLICY "Users can view their own profile" 
ON public.users_profiles 
FOR SELECT 
USING (auth.uid() = id);

-- 5. CREAR POLÍTICA PARA INSERT (SI NO EXISTE)
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users_profiles;
CREATE POLICY "Users can insert their own profile" 
ON public.users_profiles 
FOR INSERT 
WITH CHECK (auth.uid() = id);

-- 6. VERIFICAR USUARIO ACTUAL
SELECT 
    'USUARIO ACTUAL' as info,
    auth.uid() as current_user_id,
    CASE 
        WHEN auth.uid() IS NOT NULL THEN 'Usuario autenticado ✅'
        ELSE 'Usuario NO autenticado ❌'
    END as auth_status;

-- 7. PROBAR UPDATE DIRECTO DEL FCM TOKEN
UPDATE public.users_profiles 
SET fcm_token = 'test_token_' || NOW()::text
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 8. VERIFICAR SI SE ACTUALIZÓ
SELECT 
    'PRUEBA UPDATE FCM TOKEN' as info,
    id,
    fcm_token,
    updated_at
FROM public.users_profiles 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 9. FUNCIÓN PARA PROBAR UPDATE COMO USUARIO AUTENTICADO
CREATE OR REPLACE FUNCTION test_fcm_token_update()
RETURNS TEXT AS $$
DECLARE
    current_user_id UUID;
    update_result INTEGER;
BEGIN
    -- Obtener usuario actual
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NULL THEN
        RETURN '❌ Usuario no autenticado - RLS bloqueará la operación';
    END IF;
    
    -- Intentar actualizar FCM token
    UPDATE public.users_profiles 
    SET fcm_token = 'test_token_function_' || NOW()::text
    WHERE id = current_user_id;
    
    GET DIAGNOSTICS update_result = ROW_COUNT;
    
    IF update_result > 0 THEN
        RETURN '✅ FCM token actualizado exitosamente para usuario: ' || current_user_id::text;
    ELSE
        RETURN '❌ No se pudo actualizar FCM token - Verifica RLS policies';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. EJECUTAR PRUEBA DE FUNCIÓN
SELECT test_fcm_token_update() as test_result;

-- 11. OPCIÓN NUCLEAR: DESHABILITAR RLS TEMPORALMENTE (SOLO PARA PRUEBAS)
-- ⚠️ DESCOMENTA SOLO SI QUIERES PROBAR SIN RLS
-- ALTER TABLE public.users_profiles DISABLE ROW LEVEL SECURITY;

-- 12. CREAR POLÍTICA MÁS PERMISIVA PARA FCM TOKEN
DROP POLICY IF EXISTS "Allow fcm_token updates" ON public.users_profiles;
CREATE POLICY "Allow fcm_token updates" 
ON public.users_profiles 
FOR UPDATE 
USING (true)  -- Permitir a cualquiera (TEMPORAL)
WITH CHECK (true);

-- 13. FUNCIÓN PARA SIMULAR UPDATE DESDE FLUTTER
CREATE OR REPLACE FUNCTION simulate_flutter_fcm_update(
    p_user_id UUID,
    p_fcm_token TEXT
)
RETURNS TEXT AS $$
DECLARE
    update_result INTEGER;
BEGIN
    -- Simular lo que hace Flutter
    UPDATE public.users_profiles 
    SET fcm_token = p_fcm_token,
        updated_at = NOW()
    WHERE id = p_user_id;
    
    GET DIAGNOSTICS update_result = ROW_COUNT;
    
    IF update_result > 0 THEN
        RETURN '✅ Simulación exitosa - FCM token actualizado';
    ELSE
        RETURN '❌ Simulación falló - Usuario no encontrado o RLS bloqueó';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14. PROBAR SIMULACIÓN
SELECT simulate_flutter_fcm_update(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'simulated_fcm_token_' || NOW()::text
) as simulation_result;

-- 15. VERIFICAR RESULTADO FINAL
SELECT 
    'RESULTADO FINAL' as info,
    id,
    fcm_token,
    updated_at,
    CASE 
        WHEN fcm_token IS NOT NULL THEN 'FCM Token presente ✅'
        ELSE 'FCM Token faltante ❌'
    END as status
FROM public.users_profiles 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 16. MOSTRAR TODAS LAS POLÍTICAS FINALES
SELECT 
    'POLÍTICAS FINALES' as info,
    policyname,
    cmd,
    permissive,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users_profiles'
ORDER BY policyname;

-- 17. MENSAJE FINAL
SELECT '🔍 DIAGNÓSTICO COMPLETO - REVISA LOS RESULTADOS PARA IDENTIFICAR EL PROBLEMA' as resultado;