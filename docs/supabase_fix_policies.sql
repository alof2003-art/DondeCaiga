-- ============================================
-- SCRIPT PARA CORREGIR POLÍTICAS DE SEGURIDAD
-- ============================================

-- 1. ELIMINAR POLÍTICAS EXISTENTES QUE PUEDEN ESTAR CAUSANDO PROBLEMAS
DROP POLICY IF EXISTS "Users can insert own profile" ON users_profiles;
DROP POLICY IF EXISTS "Users can read own profile" ON users_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON users_profiles;

-- 2. CREAR POLÍTICA MÁS PERMISIVA PARA INSERCIÓN
-- Esta política permite que cualquier usuario autenticado cree su perfil
CREATE POLICY "Enable insert for authenticated users"
  ON users_profiles FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 3. CREAR POLÍTICA PARA LECTURA
CREATE POLICY "Enable read for own profile"
  ON users_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- 4. CREAR POLÍTICA PARA ACTUALIZACIÓN
CREATE POLICY "Enable update for own profile"
  ON users_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ============================================
-- POLÍTICAS DE STORAGE - PROFILE PHOTOS
-- ============================================

-- Eliminar políticas existentes
DROP POLICY IF EXISTS "Users can upload own profile photo" ON storage.objects;
DROP POLICY IF EXISTS "Users can read own profile photo" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own profile photo" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own profile photo" ON storage.objects;

-- Crear políticas más permisivas para profile-photos
CREATE POLICY "Allow authenticated users to upload profile photos"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'profile-photos');

CREATE POLICY "Allow authenticated users to read profile photos"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'profile-photos');

CREATE POLICY "Allow authenticated users to update profile photos"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'profile-photos')
  WITH CHECK (bucket_id = 'profile-photos');

CREATE POLICY "Allow authenticated users to delete profile photos"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'profile-photos');

-- ============================================
-- POLÍTICAS DE STORAGE - ID DOCUMENTS
-- ============================================

-- Eliminar políticas existentes
DROP POLICY IF EXISTS "Users can upload own id document" ON storage.objects;
DROP POLICY IF EXISTS "Users can read own id document" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own id document" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own id document" ON storage.objects;

-- Crear políticas más permisivas para id-documents
CREATE POLICY "Allow authenticated users to upload id documents"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'id-documents');

CREATE POLICY "Allow authenticated users to read id documents"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'id-documents');

CREATE POLICY "Allow authenticated users to update id documents"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'id-documents')
  WITH CHECK (bucket_id = 'id-documents');

CREATE POLICY "Allow authenticated users to delete id documents"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'id-documents');

-- ============================================
-- VERIFICACIÓN
-- ============================================

-- Ver todas las políticas de users_profiles
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE tablename = 'users_profiles';

-- Nota: Para ver las políticas de storage, ve a Storage > Policies en la interfaz de Supabase
