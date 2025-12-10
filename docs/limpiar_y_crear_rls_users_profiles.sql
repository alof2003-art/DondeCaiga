-- ============================================
-- LIMPIAR Y CREAR POLÍTICAS RLS CORRECTAS
-- Para tabla: users_profiles
-- ============================================

-- Paso 1: Eliminar TODAS las políticas existentes
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON users_profiles;
DROP POLICY IF EXISTS "Enable read for own profile" ON users_profiles;
DROP POLICY IF EXISTS "Enable update for own profile" ON users_profiles;
DROP POLICY IF EXISTS "Todos pueden ver perfiles públicos" ON users_profiles;
DROP POLICY IF EXISTS "Usuarios pueden actualizar su propio perfil" ON users_profiles;
DROP POLICY IF EXISTS "Usuarios pueden insertar su propio perfil" ON users_profiles;
DROP POLICY IF EXISTS "Usuarios pueden ver su propio perfil" ON users_profiles;

-- Paso 2: Asegurar que RLS está habilitado
ALTER TABLE users_profiles ENABLE ROW LEVEL SECURITY;

-- Paso 3: Crear las 4 políticas necesarias (SIN DUPLICADOS)

-- 1. INSERT: Permitir que usuarios autenticados creen su propio perfil
CREATE POLICY "users_profiles_insert_own"
ON users_profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- 2. SELECT (propia): Usuarios pueden ver su propio perfil
CREATE POLICY "users_profiles_select_own"
ON users_profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- 3. SELECT (pública): Todos pueden ver perfiles de otros usuarios
CREATE POLICY "users_profiles_select_public"
ON users_profiles
FOR SELECT
TO authenticated
USING (true);

-- 4. UPDATE: Usuarios pueden actualizar su propio perfil
CREATE POLICY "users_profiles_update_own"
ON users_profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Paso 4: Verificar que se crearon correctamente
SELECT 
    tablename,
    policyname,
    cmd as operacion,
    roles
FROM pg_policies 
WHERE tablename = 'users_profiles'
ORDER BY cmd, policyname;

-- Mensaje de éxito
SELECT '✅ Políticas RLS limpiadas y creadas correctamente' as resultado;
