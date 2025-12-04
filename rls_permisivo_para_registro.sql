-- ============================================
-- SOLUCIÓN: RLS PERMISIVO PARA REGISTRO
-- ============================================
-- Mantiene RLS habilitado pero permite actualizaciones durante registro

-- Habilitar RLS
ALTER TABLE users_profiles ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes
DROP POLICY IF EXISTS "users_profiles_insert_own" ON users_profiles;
DROP POLICY IF EXISTS "users_profiles_select_own" ON users_profiles;
DROP POLICY IF EXISTS "users_profiles_select_public" ON users_profiles;
DROP POLICY IF EXISTS "users_profiles_update_own" ON users_profiles;

-- 1. INSERT: Más permisivo - permite crear perfiles para usuarios autenticados
CREATE POLICY "users_profiles_insert_own"
ON users_profiles
FOR INSERT
TO authenticated
WITH CHECK (true);  -- Permite cualquier insert de usuarios autenticados

-- 2. SELECT (propia): Usuarios pueden ver su propio perfil
CREATE POLICY "users_profiles_select_own"
ON users_profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- 3. SELECT (pública): Todos pueden ver perfiles de otros
CREATE POLICY "users_profiles_select_public"
ON users_profiles
FOR SELECT
TO authenticated
USING (true);

-- 4. UPDATE: Más permisivo - permite actualizar si eres el dueño O si el perfil es reciente
CREATE POLICY "users_profiles_update_own"
ON users_profiles
FOR UPDATE
TO authenticated
USING (
  auth.uid() = id OR 
  created_at > (NOW() - INTERVAL '5 minutes')  -- Permite updates en los primeros 5 minutos
)
WITH CHECK (auth.uid() = id);

-- Verificar
SELECT 
    tablename,
    policyname,
    cmd as operacion
FROM pg_policies 
WHERE tablename = 'users_profiles'
ORDER BY cmd, policyname;

SELECT '✅ RLS habilitado con políticas permisivas para registro' as resultado;
