-- =====================================================
-- ARREGLAR COLUMNA FCM TOKEN
-- =====================================================

-- PASO 1: Verificar el tipo actual de la columna
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users_profiles' 
AND column_name = 'fcm_token';

-- PASO 2: Cambiar la columna a TEXT sin límite
ALTER TABLE public.users_profiles 
ALTER COLUMN fcm_token TYPE TEXT;

-- PASO 3: Verificar el cambio
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'users_profiles' 
AND column_name = 'fcm_token';

-- PASO 4: Limpiar tokens truncados
UPDATE public.users_profiles 
SET fcm_token = NULL 
WHERE fcm_token IS NOT NULL 
AND LENGTH(fcm_token) < 100;  -- Los tokens FCM válidos son mucho más largos

-- PASO 5: Verificar limpieza
SELECT 
    email,
    CASE 
        WHEN fcm_token IS NULL THEN 'NULL - Necesita regenerar'
        WHEN LENGTH(fcm_token) < 100 THEN 'TRUNCADO - Necesita regenerar'
        ELSE 'VÁLIDO - ' || LENGTH(fcm_token) || ' caracteres'
    END as estado_token
FROM public.users_profiles 
WHERE email IN ('alof2003@gmail.com', 'cristianquespaz2000@gmail.com');

SELECT '✅ COLUMNA ARREGLADA - Ahora puede almacenar tokens completos' as resultado;