-- ============================================
-- POLÍTICAS DE STORAGE - SOLUCIÓN FINAL
-- ============================================

-- Habilitar RLS en storage.objects si no está habilitado
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes para evitar conflictos
DROP POLICY IF EXISTS "Permitir todo en profile-photos para autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir todo en id-documents para autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir todo en solicitudes-anfitrion para autenticados" ON storage.objects;
DROP POLICY IF EXISTS "Permitir todo en propiedades-fotos para autenticados" ON storage.objects;

-- Política SUPER PERMISIVA para profile-photos
CREATE POLICY "profile_photos_all"
ON storage.objects
FOR ALL
TO public
USING (bucket_id = 'profile-photos')
WITH CHECK (bucket_id = 'profile-photos');

-- Política SUPER PERMISIVA para id-documents
CREATE POLICY "id_documents_all"
ON storage.objects
FOR ALL
TO public
USING (bucket_id = 'id-documents')
WITH CHECK (bucket_id = 'id-documents');

-- Política SUPER PERMISIVA para solicitudes-anfitrion
CREATE POLICY "solicitudes_anfitrion_all"
ON storage.objects
FOR ALL
TO public
USING (bucket_id = 'solicitudes-anfitrion')
WITH CHECK (bucket_id = 'solicitudes-anfitrion');

-- Política SUPER PERMISIVA para propiedades-fotos
CREATE POLICY "propiedades_fotos_all"
ON storage.objects
FOR ALL
TO public
USING (bucket_id = 'propiedades-fotos')
WITH CHECK (bucket_id = 'propiedades-fotos');

-- Verificar que se crearon
SELECT 
    policyname,
    cmd,
    roles
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'objects'
ORDER BY policyname;
