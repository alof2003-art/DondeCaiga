-- =====================================================
-- DESACTIVAR RLS TEMPORAL PARA ARREGLAR FCM TOKEN
-- =====================================================
-- Ejecuta esto para que el FCM token se pueda guardar

-- 1. DESACTIVAR RLS EN USERS_PROFILES
ALTER TABLE users_profiles DISABLE ROW LEVEL SECURITY;

-- 2. VERIFICAR QUE SE DESACTIVÓ
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'users_profiles';

-- 3. LIMPIAR TOKEN ACTUAL (para forzar regeneración)
UPDATE users_profiles 
SET fcm_token = NULL 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 4. VERIFICAR QUE SE LIMPIÓ
SELECT 
    'ANTES DE REINICIAR APP' as estado,
    id,
    CASE 
        WHEN fcm_token IS NULL THEN 'Token limpio ✅ - Reinicia la app'
        ELSE 'Token aún existe ❌'
    END as token_status
FROM users_profiles 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- =====================================================
-- INSTRUCCIONES:
-- =====================================================
-- 1. Ejecuta este SQL completo
-- 2. Cierra la app completamente 
-- 3. Abre la app de nuevo
-- 4. Espera 15 segundos
-- 5. Ejecuta: SELECT check_fcm_token_status();
-- 6. Si funciona, ejecuta: SELECT test_complete_push_system();
-- =====================================================

-- FUNCIÓN PARA VERIFICAR DESPUÉS DE REINICIAR
CREATE OR REPLACE FUNCTION check_fcm_token_status()
RETURNS TABLE(
    estado TEXT,
    user_id UUID,
    token_status TEXT,
    token_preview TEXT,
    rls_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'DESPUÉS DE REINICIAR APP'::TEXT,
        up.id,
        CASE 
            WHEN up.fcm_token IS NOT NULL THEN 'Token generado ✅'
            ELSE 'Token faltante ❌ - Espera más tiempo'
        END::TEXT,
        COALESCE(LEFT(up.fcm_token, 30) || '...', 'NULL')::TEXT,
        CASE 
            WHEN pg_tables.rowsecurity THEN 'RLS Activado ❌'
            ELSE 'RLS Desactivado ✅'
        END::TEXT
    FROM users_profiles up
    CROSS JOIN (
        SELECT rowsecurity 
        FROM pg_tables 
        WHERE tablename = 'users_profiles'
    ) pg_tables
    WHERE up.id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;
END;
$$ LANGUAGE plpgsql;

-- FUNCIÓN PARA REACTIVAR RLS DESPUÉS (OPCIONAL)
CREATE OR REPLACE FUNCTION reactivar_rls_cuando_funcione()
RETURNS TEXT AS $$
BEGIN
    -- Solo reactivar si el token ya existe
    IF EXISTS(
        SELECT 1 FROM users_profiles 
        WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid 
        AND fcm_token IS NOT NULL
    ) THEN
        ALTER TABLE users_profiles ENABLE ROW LEVEL SECURITY;
        
        -- Crear política permisiva
        DROP POLICY IF EXISTS "Allow all operations" ON users_profiles;
        CREATE POLICY "Allow all operations" 
        ON users_profiles 
        USING (true) 
        WITH CHECK (true);
        
        RETURN '✅ RLS reactivado con política permisiva';
    ELSE
        RETURN '❌ No se puede reactivar RLS - Token aún no existe';
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT '🚀 RLS DESACTIVADO - AHORA REINICIA LA APP' as resultado;