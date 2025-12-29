-- =====================================================
-- PROBAR FCM TOKEN SIMPLE - SIN ERRORES
-- =====================================================

-- 1. VERIFICAR USUARIO ACTUAL
SELECT 
    'TU USUARIO' as info,
    id,
    email,
    fcm_token
FROM public.users_profiles 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3';

-- 2. ACTUALIZAR FCM TOKEN DIRECTAMENTE
UPDATE public.users_profiles 
SET fcm_token = 'test_token_manual_' || extract(epoch from now())::text || '_long_enough_to_be_valid_fcm_token_for_testing_purposes_only'
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3';

-- 3. VERIFICAR QUE SE ACTUALIZÓ
SELECT 
    'DESPUÉS DE ACTUALIZAR' as info,
    id,
    email,
    CASE 
        WHEN fcm_token IS NOT NULL THEN 'Token presente'
        ELSE 'Sin token'
    END as token_status,
    LEFT(fcm_token, 50) || '...' as token_preview
FROM public.users_profiles 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3';