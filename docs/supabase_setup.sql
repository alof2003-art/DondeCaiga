-- ============================================
-- SCRIPTS SQL PARA CONFIGURAR SUPABASE
-- Aplicación: Donde Caiga
-- Feature: Autenticación de Usuario
-- ============================================

-- INSTRUCCIONES:
-- 1. Abre tu proyecto en Supabase (https://supabase.com)
-- 2. Ve a SQL Editor
-- 3. Copia y pega estos scripts uno por uno
-- 4. Ejecuta cada sección en orden

-- ============================================
-- 1. CREAR TABLA DE PERFILES DE USUARIO
-- ============================================

CREATE TABLE IF NOT EXISTS users_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  nombre TEXT NOT NULL,
  telefono TEXT,
  foto_perfil_url TEXT,
  cedula_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  email_verified BOOLEAN DEFAULT FALSE
);

-- Crear índice para búsquedas por email
CREATE INDEX IF NOT EXISTS idx_users_profiles_email ON users_profiles(email);

-- Comentarios para documentación
COMMENT ON TABLE users_profiles IS 'Perfiles de usuario de la aplicación Donde Caiga';
COMMENT ON COLUMN users_profiles.id IS 'ID del usuario, referencia a auth.users';
COMMENT ON COLUMN users_profiles.email IS 'Email del usuario';
COMMENT ON COLUMN users_profiles.nombre IS 'Nombre completo del usuario';
COMMENT ON COLUMN users_profiles.telefono IS 'Número de teléfono del usuario';
COMMENT ON COLUMN users_profiles.foto_perfil_url IS 'URL de la foto de perfil en Supabase Storage';
COMMENT ON COLUMN users_profiles.cedula_url IS 'URL del documento de identidad en Supabase Storage';
COMMENT ON COLUMN users_profiles.email_verified IS 'Indica si el email ha sido verificado';

-- ============================================
-- 2. HABILITAR ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE users_profiles ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. CREAR POLÍTICAS DE SEGURIDAD PARA users_profiles
-- ============================================

-- Política: Los usuarios pueden leer su propio perfil
CREATE POLICY "Users can read own profile"
  ON users_profiles FOR SELECT
  USING (auth.uid() = id);

-- Política: Los usuarios pueden actualizar su propio perfil
CREATE POLICY "Users can update own profile"
  ON users_profiles FOR UPDATE
  USING (auth.uid() = id);

-- Política: Permitir inserción durante registro
CREATE POLICY "Users can insert own profile"
  ON users_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ============================================
-- 4. CREAR STORAGE BUCKETS
-- ============================================

-- NOTA: Los buckets se crean desde la interfaz de Supabase Storage
-- Ve a Storage > Create a new bucket

-- Bucket 1: profile-photos
-- - Nombre: profile-photos
-- - Público: NO (desmarcar "Public bucket")
-- - Tamaño máximo de archivo: 5MB
-- - Tipos permitidos: image/jpeg, image/png, image/webp

-- Bucket 2: id-documents
-- - Nombre: id-documents
-- - Público: NO (desmarcar "Public bucket")
-- - Tamaño máximo de archivo: 10MB
-- - Tipos permitidos: image/jpeg, image/png, image/pdf

-- ============================================
-- 5. POLÍTICAS DE STORAGE PARA profile-photos
-- ============================================

-- Política: Los usuarios pueden subir su propia foto de perfil
CREATE POLICY "Users can upload own profile photo"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'profile-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Política: Los usuarios pueden leer su propia foto de perfil
CREATE POLICY "Users can read own profile photo"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'profile-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Política: Los usuarios pueden actualizar su propia foto de perfil
CREATE POLICY "Users can update own profile photo"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'profile-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Política: Los usuarios pueden eliminar su propia foto de perfil
CREATE POLICY "Users can delete own profile photo"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'profile-photos' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================
-- 6. POLÍTICAS DE STORAGE PARA id-documents
-- ============================================

-- Política: Los usuarios pueden subir su propio documento de identidad
CREATE POLICY "Users can upload own id document"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'id-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Política: Los usuarios pueden leer su propio documento de identidad
CREATE POLICY "Users can read own id document"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'id-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Política: Los usuarios pueden actualizar su propio documento de identidad
CREATE POLICY "Users can update own id document"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'id-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Política: Los usuarios pueden eliminar su propio documento de identidad
CREATE POLICY "Users can delete own id document"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'id-documents' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- ============================================
-- 7. FUNCIÓN PARA ACTUALIZAR updated_at AUTOMÁTICAMENTE
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger para actualizar updated_at
CREATE TRIGGER update_users_profiles_updated_at
  BEFORE UPDATE ON users_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 8. CONFIGURACIÓN DE AUTENTICACIÓN
-- ============================================

-- NOTA: Estas configuraciones se hacen desde la interfaz de Supabase
-- Ve a Authentication > Settings

-- Configuraciones recomendadas:
-- 1. Email confirmation: HABILITADO
--    - Ir a Authentication > Settings > Email Auth
--    - Marcar "Enable email confirmations"

-- 2. Session duration: 7 días (por defecto)
--    - Ir a Authentication > Settings > Security
--    - JWT expiry: 604800 segundos (7 días)

-- 3. Personalizar plantilla de email de verificación:
--    - Ir a Authentication > Email Templates
--    - Seleccionar "Confirm signup"
--    - Personalizar con el branding de "Donde Caiga"

-- ============================================
-- VERIFICACIÓN
-- ============================================

-- Ejecuta estas consultas para verificar que todo está configurado:

-- Verificar que la tabla existe
SELECT COUNT(*) as tabla_creada FROM users_profiles;

-- Verificar políticas de RLS
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename = 'users_profiles';

-- Verificar buckets de storage (ejecuta esto desde la interfaz de Storage)
-- Ve a Storage y verifica que existan los buckets:
-- - profile-photos
-- - id-documents

-- ============================================
-- FIN DE LA CONFIGURACIÓN
-- ============================================
