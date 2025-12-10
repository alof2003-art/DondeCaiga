-- ============================================
-- POLÍTICAS PARA STORAGE.BUCKETS
-- ============================================
-- Estas políticas permiten que los usuarios autenticados
-- puedan acceder y listar los buckets de storage

-- Habilitar RLS en storage.buckets
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas existentes para evitar conflictos
DROP POLICY IF EXISTS "Permitir acceso a buckets públicos" ON storage.buckets;
DROP POLICY IF EXISTS "Permitir acceso a todos los buckets" ON storage.buckets;

-- Política para permitir que usuarios autenticados vean todos los buckets
CREATE POLICY "Permitir acceso a todos los buckets"
ON storage.buckets
FOR SELECT
TO public
USING (true);

-- Verificar que se creó la política
SELECT 
    policyname,
    cmd,
    roles,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'storage' 
  AND tablename = 'buckets'
ORDER BY policyname;
