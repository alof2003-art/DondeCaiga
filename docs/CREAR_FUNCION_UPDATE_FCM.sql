-- =====================================================
-- CREAR FUNCIÓN PARA ACTUALIZAR FCM TOKEN
-- =====================================================

-- Función para actualizar FCM token (método alternativo)
CREATE OR REPLACE FUNCTION update_fcm_token(user_id UUID, new_token TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    rows_affected INTEGER;
BEGIN
    -- Intentar actualizar el token
    UPDATE public.users_profiles 
    SET fcm_token = new_token, updated_at = NOW()
    WHERE id = user_id;
    
    GET DIAGNOSTICS rows_affected = ROW_COUNT;
    
    IF rows_affected > 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    -- Log del error
    RAISE NOTICE 'Error al actualizar FCM token: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para verificar y mostrar estado del token
CREATE OR REPLACE FUNCTION debug_fcm_token_status()
RETURNS TABLE(
    paso TEXT,
    resultado TEXT,
    detalles TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Paso 1: Verificar usuario existe
    SELECT 
        'Paso 1: Usuario existe'::TEXT,
        CASE 
            WHEN EXISTS(SELECT 1 FROM public.users_profiles WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid)
            THEN '✅ SÍ'
            ELSE '❌ NO'
        END::TEXT,
        'Verificando si el usuario está en la base de datos'::TEXT
    
    UNION ALL
    
    -- Paso 2: Verificar RLS
    SELECT 
        'Paso 2: RLS Status'::TEXT,
        CASE 
            WHEN (SELECT rowsecurity FROM pg_tables WHERE tablename = 'users_profiles' AND schemaname = 'public')
            THEN '❌ ACTIVADO'
            ELSE '✅ DESACTIVADO'
        END::TEXT,
        'Row Level Security puede bloquear actualizaciones'::TEXT
    
    UNION ALL
    
    -- Paso 3: Verificar token actual
    SELECT 
        'Paso 3: Token actual'::TEXT,
        CASE 
            WHEN EXISTS(
                SELECT 1 FROM public.users_profiles 
                WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid 
                AND fcm_token IS NOT NULL
            ) THEN '✅ EXISTE'
            ELSE '❌ NULL'
        END::TEXT,
        COALESCE(
            (SELECT LEFT(fcm_token, 30) || '...' FROM public.users_profiles WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid),
            'No hay token'
        )::TEXT
    
    UNION ALL
    
    -- Paso 4: Probar actualización
    SELECT 
        'Paso 4: Prueba actualización'::TEXT,
        CASE 
            WHEN update_fcm_token('0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid, 'test_token_' || EXTRACT(EPOCH FROM NOW())::text)
            THEN '✅ FUNCIONA'
            ELSE '❌ FALLA'
        END::TEXT,
        'Probando si se puede actualizar el token'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- Ejecutar diagnóstico
SELECT debug_fcm_token_status();

SELECT '🔧 FUNCIÓN CREADA - AHORA PRUEBA EL SERVICIO SIMPLE' as resultado;