-- ============================================
-- DESHABILITAR RLS EN TODAS LAS TABLAS
-- ============================================
-- Para evitar problemas de permisos durante desarrollo

-- Tablas principales
ALTER TABLE users_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE solicitudes_anfitrion DISABLE ROW LEVEL SECURITY;
ALTER TABLE propiedades DISABLE ROW LEVEL SECURITY;
ALTER TABLE fotos_propiedades DISABLE ROW LEVEL SECURITY;
ALTER TABLE reservas DISABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes DISABLE ROW LEVEL SECURITY;
ALTER TABLE resenas DISABLE ROW LEVEL SECURITY;

-- Verificar que se deshabilitó
SELECT 
    tablename,
    rowsecurity as rls_habilitado
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN (
    'users_profiles',
    'solicitudes_anfitrion', 
    'propiedades',
    'fotos_propiedades',
    'reservas',
    'mensajes',
    'resenas'
  )
ORDER BY tablename;

SELECT '✅ RLS deshabilitado en todas las tablas' as resultado;
