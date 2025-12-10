-- ============================================
-- HABILITAR RLS EN TABLA ROLES
-- ============================================

-- Habilitar RLS
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;

-- Crear política para que todos puedan leer los roles
CREATE POLICY "Todos pueden leer roles"
ON roles
FOR SELECT
TO public
USING (true);

-- Verificar
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'roles';
