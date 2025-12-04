-- ============================================
-- CREAR BUCKETS DE STORAGE
-- ============================================
-- Nota: Los buckets se crean desde la interfaz de Supabase Storage
-- Este archivo es solo una guía de qué buckets crear

-- BUCKETS A CREAR:
-- 1. profile-photos (ya existe)
-- 2. id-documents (ya existe)
-- 3. solicitudes-anfitrion (NUEVO)
-- 4. propiedades-fotos (NUEVO)

-- ============================================
-- POLÍTICAS PARA: solicitudes-anfitrion
-- ============================================

CREATE POLICY "Usuarios pueden subir fotos de solicitud"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'solicitudes-anfitrion');

CREATE POLICY "Usuarios pueden ver fotos de solicitud"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'solicitudes-anfitrion');

-- ============================================
-- POLÍTICAS PARA: propiedades-fotos
-- ============================================

CREATE POLICY "Anfitriones pueden subir fotos de propiedades"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'propiedades-fotos');

CREATE POLICY "Todos pueden ver fotos de propiedades"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'propiedades-fotos');

CREATE POLICY "Anfitriones pueden actualizar fotos de propiedades"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'propiedades-fotos');

CREATE POLICY "Anfitriones pueden eliminar fotos de propiedades"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'propiedades-fotos');
