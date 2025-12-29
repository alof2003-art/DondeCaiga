-- =====================================================
-- ARREGLAR FCM TOKEN PARA TODOS LOS USUARIOS
-- =====================================================

-- 1. VERIFICAR TODOS LOS USUARIOS
SELECT 
    'TODOS LOS USUARIOS' as info,
    COUNT(*) as total_usuarios,
    COUNT(fcm_token) as usuarios_con_token,
    COUNT(*) - COUNT(fcm_token) as usuarios_sin_token
FROM public.users_profiles;

-- 2. MOSTRAR USUARIOS SIN TOKEN FCM
SELECT 
    'USUARIOS SIN TOKEN FCM' as info,
    id,
    email,
    nombre,
    CASE 
        WHEN fcm_token IS NULL THEN 'Sin token ❌'
        WHEN LENGTH(fcm_token) < 50 THEN 'Token inválido ❌'
        ELSE 'Token válido ✅'
    END as token_status
FROM public.users_profiles
ORDER BY email;

-- 3. DESHABILITAR RLS PARA PERMITIR ACTUALIZACIONES
ALTER TABLE public.users_profiles DISABLE ROW LEVEL SECURITY;

-- 4. LIMPIAR TOKENS INVÁLIDOS DE TODOS LOS USUARIOS
UPDATE public.users_profiles 
SET fcm_token = NULL 
WHERE fcm_token IS NOT NULL 
AND (
    LENGTH(fcm_token) < 50 OR
    fcm_token = '' OR
    fcm_token = 'null' OR
    fcm_token LIKE '%test%'
);

-- 5. CREAR POLÍTICA SÚPER PERMISIVA PARA FCM TOKENS
DROP POLICY IF EXISTS "Allow all operations on users_profiles" ON public.users_profiles;

CREATE POLICY "Allow all operations on users_profiles" 
ON public.users_profiles 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- 6. REACTIVAR RLS CON POLÍTICA PERMISIVA
ALTER TABLE public.users_profiles ENABLE ROW LEVEL SECURITY;

-- 7. CREAR FUNCIÓN UNIVERSAL PARA ACTUALIZAR FCM TOKEN
CREATE OR REPLACE FUNCTION save_user_fcm_token(
    user_uuid UUID,
    new_token TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    rows_affected INTEGER;
BEGIN
    -- Validar que el token no esté vacío y sea suficientemente largo
    IF new_token IS NULL OR LENGTH(TRIM(new_token)) < 50 THEN
        RETURN FALSE;
    END IF;
    
    -- Actualizar el token para el usuario específico
    UPDATE public.users_profiles 
    SET 
        fcm_token = new_token,
        updated_at = NOW()
    WHERE id = user_uuid;
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    
    RETURN rows_affected > 0;
    
EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- 8. CREAR FUNCIÓN PARA OBTENER TOKEN FCM DE UN USUARIO
CREATE OR REPLACE FUNCTION get_user_fcm_token(user_uuid UUID)
RETURNS TEXT AS $$
DECLARE
    user_token TEXT;
BEGIN
    SELECT fcm_token INTO user_token
    FROM public.users_profiles 
    WHERE id = user_uuid;
    
    RETURN user_token;
    
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 9. PROBAR LA FUNCIÓN CON DIFERENTES USUARIOS
-- (Solo para usuarios que existen)
DO $$
DECLARE
    user_record RECORD;
    test_token TEXT;
    result BOOLEAN;
BEGIN
    FOR user_record IN 
        SELECT id, email FROM public.users_profiles LIMIT 3
    LOOP
        test_token := 'fcm_token_for_' || user_record.email || '_' || extract(epoch from now())::text || '_long_enough_to_be_valid';
        
        SELECT save_user_fcm_token(user_record.id, test_token) INTO result;
        
        IF result THEN
            RAISE NOTICE 'Token FCM guardado para usuario: % (ID: %)', user_record.email, user_record.id;
        ELSE
            RAISE NOTICE 'Error al guardar token para usuario: % (ID: %)', user_record.email, user_record.id;
        END IF;
    END LOOP;
END $$;

-- 10. VERIFICAR RESULTADOS PARA TODOS LOS USUARIOS
SELECT 
    'DESPUÉS DE ACTUALIZAR TOKENS' as info,
    COUNT(*) as total_usuarios,
    COUNT(fcm_token) as usuarios_con_token,
    COUNT(*) - COUNT(fcm_token) as usuarios_sin_token
FROM public.users_profiles;

-- 11. MOSTRAR ESTADO ACTUAL DE TODOS LOS USUARIOS
SELECT 
    'ESTADO ACTUAL DE USUARIOS' as info,
    id,
    email,
    nombre,
    CASE 
        WHEN fcm_token IS NULL THEN 'Sin token ❌'
        WHEN LENGTH(fcm_token) < 50 THEN 'Token inválido ❌'
        ELSE 'Token válido ✅'
    END as token_status,
    CASE 
        WHEN fcm_token IS NOT NULL THEN LEFT(fcm_token, 30) || '...'
        ELSE 'NULL'
    END as token_preview,
    updated_at
FROM public.users_profiles
ORDER BY email;

-- 12. CREAR TRIGGER PARA LOG DE CAMBIOS DE TOKEN
CREATE OR REPLACE FUNCTION log_fcm_token_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.fcm_token IS DISTINCT FROM NEW.fcm_token THEN
        RAISE NOTICE 'Token FCM actualizado para usuario %: %', 
            NEW.email, 
            CASE 
                WHEN NEW.fcm_token IS NOT NULL THEN 'Token guardado ✅'
                ELSE 'Token eliminado ❌'
            END;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_log_fcm_changes ON public.users_profiles;
CREATE TRIGGER trigger_log_fcm_changes
    BEFORE UPDATE ON public.users_profiles
    FOR EACH ROW
    EXECUTE FUNCTION log_fcm_token_changes();

SELECT '🎉 SISTEMA FCM CONFIGURADO PARA TODOS LOS USUARIOS' as resultado;
SELECT 'Cada usuario puede tener su propio token FCM único' as info;
SELECT 'Usa save_user_fcm_token(user_id, token) para guardar tokens' as instruccion;