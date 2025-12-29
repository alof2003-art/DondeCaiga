-- =====================================================
-- DEBUG COMPLETO PARA VER SI EL TOKEN FCM SE ESTÁ ENVIANDO
-- =====================================================

-- PASO 1: Ver estado actual del token para el usuario de prueba
SELECT 
    'ESTADO ACTUAL TOKEN' as debug_step,
    email,
    id,
    CASE 
        WHEN fcm_token IS NOT NULL THEN 
            'TOKEN EXISTE: ' || LEFT(fcm_token, 30) || '...' || RIGHT(fcm_token, 10)
        ELSE 'TOKEN ES NULL'
    END as token_status,
    updated_at,
    EXTRACT(EPOCH FROM (NOW() - updated_at)) as segundos_desde_actualizacion
FROM users_profiles 
WHERE email = 'alof2003@gmail.com';

-- PASO 2: Función para monitorear cambios en tiempo real
CREATE OR REPLACE FUNCTION debug_token_changes() RETURNS TABLE(
    timestamp_check TIMESTAMP WITH TIME ZONE,
    user_email TEXT,
    token_status TEXT,
    token_length INTEGER,
    seconds_since_update NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        NOW() as timestamp_check,
        up.email,
        CASE 
            WHEN up.fcm_token IS NOT NULL THEN 'TOKEN PRESENTE'
            ELSE 'TOKEN AUSENTE'
        END as token_status,
        COALESCE(LENGTH(up.fcm_token), 0) as token_length,
        EXTRACT(EPOCH FROM (NOW() - up.updated_at)) as seconds_since_update
    FROM users_profiles up
    WHERE up.email = 'alof2003@gmail.com';
END;
$$ LANGUAGE plpgsql;

-- PASO 3: Función para simular lo que hace Flutter
CREATE OR REPLACE FUNCTION simular_flutter_token_update() RETURNS TEXT AS $$
DECLARE
    test_token TEXT;
    user_id_target UUID;
    update_result INTEGER;
BEGIN
    -- Generar token de prueba similar a FCM
    test_token := 'flutter_test_' || EXTRACT(EPOCH FROM NOW())::text || '_' || 
                  md5(random()::text || clock_timestamp()::text);
    
    -- Obtener ID del usuario
    SELECT id INTO user_id_target 
    FROM users_profiles 
    WHERE email = 'alof2003@gmail.com';
    
    IF user_id_target IS NULL THEN
        RETURN '❌ Usuario alof2003@gmail.com no encontrado';
    END IF;
    
    -- Simular UPDATE que hace Flutter
    UPDATE users_profiles 
    SET fcm_token = test_token, updated_at = NOW()
    WHERE id = user_id_target;
    
    GET DIAGNOSTICS update_result = ROW_COUNT;
    
    IF update_result > 0 THEN
        RETURN '✅ Simulación exitosa - Token: ' || LEFT(test_token, 30) || '...';
    ELSE
        RETURN '❌ Simulación falló - No se actualizó ninguna fila';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- PASO 4: Función para verificar permisos RLS
CREATE OR REPLACE FUNCTION verificar_permisos_rls() RETURNS TABLE(
    tabla TEXT,
    rls_enabled BOOLEAN,
    politicas_count INTEGER,
    puede_actualizar TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'users_profiles'::TEXT,
        pg_tables.rowsecurity,
        (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'users_profiles')::INTEGER,
        CASE 
            WHEN pg_tables.rowsecurity THEN 
                'RLS ACTIVADO - Puede bloquear actualizaciones'
            ELSE 
                'RLS DESACTIVADO - Actualizaciones permitidas'
        END::TEXT
    FROM pg_tables 
    WHERE tablename = 'users_profiles' AND schemaname = 'public';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- EJECUTAR DIAGNÓSTICOS
-- =====================================================

-- Ver estado actual
SELECT * FROM debug_token_changes();

-- Verificar permisos
SELECT * FROM verificar_permisos_rls();

-- Simular lo que hace Flutter
SELECT simular_flutter_token_update();

-- Ver resultado después de simulación
SELECT * FROM debug_token_changes();

-- Monitoreo continuo (ejecutar varias veces mientras pruebas la app)
-- SELECT 
--     NOW() as momento_check,
--     * 
-- FROM debug_token_changes();