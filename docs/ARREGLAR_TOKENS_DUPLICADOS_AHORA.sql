-- ========================================
-- ARREGLAR TOKENS DUPLICADOS AHORA
-- ========================================

-- PASO 1: VER TOKENS DUPLICADOS ACTUALES
SELECT 
    'TOKENS DUPLICADOS ACTUALES' as problema,
    fcm_token,
    COUNT(*) as usuarios_afectados,
    STRING_AGG(email || ' (ID: ' || id::text || ')', ', ') as detalles_usuarios
FROM users_profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != ''
GROUP BY fcm_token
HAVING COUNT(*) > 1;

-- PASO 2: LIMPIAR TOKENS DUPLICADOS (MANTENER SOLO EL MÁS RECIENTE)
DO $$
DECLARE
    duplicate_token TEXT;
    tokens_limpiados INTEGER := 0;
BEGIN
    -- Para cada token duplicado
    FOR duplicate_token IN 
        SELECT fcm_token
        FROM users_profiles 
        WHERE fcm_token IS NOT NULL AND fcm_token != ''
        GROUP BY fcm_token
        HAVING COUNT(*) > 1
    LOOP
        -- Limpiar tokens de usuarios más antiguos, mantener el más reciente
        UPDATE users_profiles 
        SET fcm_token = NULL, updated_at = NOW()
        WHERE fcm_token = duplicate_token
        AND id NOT IN (
            SELECT id FROM users_profiles 
            WHERE fcm_token = duplicate_token
            ORDER BY updated_at DESC 
            LIMIT 1
        );
        
        GET DIAGNOSTICS tokens_limpiados = tokens_limpiados + ROW_COUNT;
        
        RAISE NOTICE 'Limpiado token duplicado: % (% usuarios afectados)', 
                     LEFT(duplicate_token, 30) || '...', 
                     tokens_limpiados;
    END LOOP;
    
    RAISE NOTICE 'TOTAL: % tokens duplicados limpiados', tokens_limpiados;
END $$;

-- PASO 3: CREAR CONSTRAINT PARA PREVENIR DUPLICADOS EN EL FUTURO
-- (Opcional - puede causar errores si no se maneja bien en la app)
-- CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_fcm_token 
-- ON users_profiles (fcm_token) 
-- WHERE fcm_token IS NOT NULL AND fcm_token != '';

-- PASO 4: FUNCIÓN MEJORADA PARA GUARDAR TOKENS SIN DUPLICADOS
CREATE OR REPLACE FUNCTION save_user_fcm_token_sin_duplicados(user_uuid UUID, new_token TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    rows_affected INTEGER;
    existing_user_with_token UUID;
BEGIN
    -- Validar que el token no esté vacío y sea suficientemente largo
    IF new_token IS NULL OR LENGTH(TRIM(new_token)) < 50 THEN
        RETURN FALSE;
    END IF;
    
    -- Verificar si otro usuario ya tiene este token
    SELECT id INTO existing_user_with_token
    FROM public.users_profiles 
    WHERE fcm_token = new_token AND id != user_uuid
    LIMIT 1;
    
    -- Si otro usuario tiene el token, limpiarlo
    IF existing_user_with_token IS NOT NULL THEN
        UPDATE public.users_profiles 
        SET fcm_token = NULL, updated_at = NOW()
        WHERE id = existing_user_with_token;
        
        RAISE NOTICE 'Token duplicado limpiado del usuario: %', existing_user_with_token;
    END IF;
    
    -- Actualizar el token para el usuario actual
    UPDATE public.users_profiles 
    SET 
        fcm_token = new_token,
        updated_at = NOW()
    WHERE id = user_uuid;
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    
    RETURN rows_affected > 0;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error al guardar token FCM: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 5: REEMPLAZAR LA FUNCIÓN ANTERIOR
DROP FUNCTION IF EXISTS save_user_fcm_token(UUID, TEXT);
CREATE OR REPLACE FUNCTION save_user_fcm_token(user_uuid UUID, new_token TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN save_user_fcm_token_sin_duplicados(user_uuid, new_token);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 6: VERIFICAR RESULTADO
SELECT 
    'RESULTADO FINAL' as status,
    COUNT(DISTINCT fcm_token) as tokens_unicos,
    COUNT(*) as usuarios_con_token,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT fcm_token) THEN '✅ SIN DUPLICADOS'
        ELSE '❌ AÚN HAY DUPLICADOS'
    END as estado
FROM users_profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != '';

-- PASO 7: MOSTRAR USUARIOS QUE NECESITAN REABRIR LA APP
SELECT 
    'USUARIOS QUE DEBEN REABRIR LA APP' as info,
    email,
    'Token limpiado - debe reabrir la app' as accion_requerida
FROM users_profiles 
WHERE fcm_token IS NULL
ORDER BY updated_at DESC;