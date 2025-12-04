-- ============================================
-- TEST: DESHABILITAR RLS TEMPORALMENTE
-- ============================================
-- Esto es SOLO para probar si el problema es RLS

-- Deshabilitar RLS en users_profiles
ALTER TABLE users_profiles DISABLE ROW LEVEL SECURITY;

-- Verificar
SELECT 
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'users_profiles';

SELECT '⚠️ RLS DESHABILITADO - Solo para pruebas' as mensaje;
