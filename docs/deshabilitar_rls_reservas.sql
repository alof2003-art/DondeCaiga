-- ============================================
-- DESHABILITAR RLS PARA TABLA RESERVAS
-- ============================================
-- ADVERTENCIA: Esto desactiva la seguridad a nivel de fila
-- Solo usar en desarrollo o para debugging
-- ============================================

-- Deshabilitar RLS en la tabla reservas
ALTER TABLE reservas DISABLE ROW LEVEL SECURITY;

-- Verificar que RLS está deshabilitado
SELECT 
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'reservas';

-- Si rowsecurity = false, entonces RLS está deshabilitado

-- ============================================
-- PARA VOLVER A HABILITAR RLS (cuando termines de probar)
-- ============================================
-- ALTER TABLE reservas ENABLE ROW LEVEL SECURITY;
-- ============================================

SELECT '✅ RLS DESHABILITADO EN TABLA RESERVAS' as resultado;
