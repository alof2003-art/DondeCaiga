-- ============================================
-- ARREGLAR POLÍTICAS DE STORAGE DEFINITIVAMENTE
-- ============================================

-- 1. ELIMINAR TODAS LAS POLÍTICAS EXISTENTES DE STORAGE
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname, tablename 
        FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
    END LOOP;
END $$;

-- 2. CREAR POLÍTICAS SIMPLES Y PERMISIVAS PARA profile-photos
CREATE POLICY "Permitir todo en profile-photos para autenticados"
  ON storage.objects
  FOR ALL
  TO authenticated
  USING (bucket_id = 'profile-photos')
  WITH CHECK (bucket_id = 'profile-photos');

-- 3. CREAR POLÍTICAS SIMPLES Y PERMISIVAS PARA id-documents
CREATE POLICY "Permitir todo en id-documents para autenticados"
  ON storage.objects
  FOR ALL
  TO authenticated
  USING (bucket_id = 'id-documents')
  WITH CHECK (bucket_id = 'id-documents');

-- 4. CREAR POLÍTICAS PARA solicitudes-anfitrion (si existe)
CREATE POLICY "Permitir todo en solicitudes-anfitrion para autenticados"
  ON storage.objects
  FOR ALL
  TO authenticated
  USING (bucket_id = 'solicitudes-anfitrion')
  WITH CHECK (bucket_id = 'solicitudes-anfitrion');

-- 5. CREAR POLÍTICAS PARA propiedades-fotos (si existe)
CREATE POLICY "Permitir todo en propiedades-fotos para autenticados"
  ON storage.objects
  FOR ALL
  TO authenticated
  USING (bucket_id = 'propiedades-fotos')
  WITH CHECK (bucket_id = 'propiedades-fotos');

-- 6. VERIFICAR QUE LAS POLÍTICAS SE CREARON
SELECT 
    policyname as nombre_politica,
    cmd as comando,
    qual as condicion_using,
    with_check as condicion_check
FROM pg_policies 
WHERE schemaname = 'storage' AND tablename = 'objects'
ORDER BY policyname;

-- ============================================
-- NOTA IMPORTANTE
-- ============================================
-- Estas políticas son MUY PERMISIVAS y solo deben usarse en desarrollo
-- En producción deberías restringir el acceso por usuario
