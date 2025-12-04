-- ============================================
-- FIX: POLÍTICAS RLS PARA users_profiles
-- ============================================
-- Este script agrega las políticas necesarias para que
-- los usuarios puedan actualizar su propio perfil

-- Habilitar RLS en users_profiles (si no está habilitado)
ALTER TABLE users_profiles ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes para evitar conflictos
DROP POLICY IF EXISTS "Usuarios pueden ver su propio perfil" ON users_profiles;
DROP POLICY IF EXISTS "Usuarios pueden actualizar su propio perfil" ON users_profiles;
DROP POLICY IF EXISTS "Usuarios pueden insertar su propio perfil" ON users_profiles;
DROP POLICY IF EXISTS "Todos pueden ver perfiles públicos" ON users_profiles;

-- 1. Política para SELECT: Usuarios pueden ver su propio perfil
CREATE POLICY "Usuarios pueden ver su propio perfil"
ON users_profiles
FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- 2. Política para UPDATE: Usuarios pueden actualizar su propio perfil
CREATE POLICY "Usuarios pueden actualizar su propio perfil"
ON users_profiles
FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 3. Política para INSERT: Permitir que el trigger cree perfiles
CREATE POLICY "Usuarios pueden insertar su propio perfil"
ON users_profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- 4. Política adicional: Todos pueden ver perfiles públicos (para mostrar anfitriones, etc.)
CREATE POLICY "Todos pueden ver perfiles públicos"
ON users_profiles
FOR SELECT
TO authenticated
USING (true);

-- Verificar que se crearon las políticas
SELECT 
    schemaname,
    tablename,
    policyname,
    cmd,
    roles
FROM pg_policies 
WHERE tablename = 'users_profiles'
ORDER BY policyname;

-- Mensaje de éxito
SELECT 'Políticas RLS para users_profiles creadas exitosamente' as mensaje;
