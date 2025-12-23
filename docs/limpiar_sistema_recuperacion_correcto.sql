-- =====================================================
-- LIMPIAR SISTEMA DE RECUPERACIÓN PERSONALIZADO - ORDEN CORRECTO
-- =====================================================
-- Este script elimina todo en el orden correcto para evitar dependencias

-- 1. PRIMERO: ELIMINAR TRIGGERS (que dependen de las funciones)
DROP TRIGGER IF EXISTS trigger_update_password_reset_codes_updated_at ON password_reset_codes;

-- 2. ELIMINAR POLÍTICAS RLS (que dependen de la tabla)
DROP POLICY IF EXISTS "Users can view their own reset codes" ON password_reset_codes;
DROP POLICY IF EXISTS "Allow insert reset codes" ON password_reset_codes;
DROP POLICY IF EXISTS "Users can update their own reset codes" ON password_reset_codes;

-- 3. ELIMINAR ÍNDICES (que dependen de la tabla)
DROP INDEX IF EXISTS idx_password_reset_codes_email;
DROP INDEX IF EXISTS idx_password_reset_codes_code;
DROP INDEX IF EXISTS idx_password_reset_codes_user_id;
DROP INDEX IF EXISTS idx_password_reset_codes_expires_at;

-- 4. ELIMINAR TABLA COMPLETA (esto eliminará automáticamente las dependencias restantes)
DROP TABLE IF EXISTS password_reset_codes CASCADE;

-- 5. AHORA SÍ: ELIMINAR FUNCIONES (ya no tienen dependencias)
DROP FUNCTION IF EXISTS generate_password_reset_code(TEXT);
DROP FUNCTION IF EXISTS validate_password_reset_code(TEXT, TEXT);
DROP FUNCTION IF EXISTS cleanup_expired_reset_codes();
DROP FUNCTION IF EXISTS update_password_reset_codes_updated_at();

-- 6. VERIFICAR RESULTADO
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'password_reset_codes') 
        THEN 'ADVERTENCIA: La tabla password_reset_codes aún existe'
        ELSE 'Sistema eliminado correctamente ✅'
    END as resultado;

-- 7. VERIFICAR QUE NO QUEDEN FUNCIONES
SELECT 
    COUNT(*) as funciones_restantes,
    string_agg(routine_name, ', ') as nombres_funciones
FROM information_schema.routines 
WHERE routine_name IN (
    'generate_password_reset_code',
    'validate_password_reset_code', 
    'cleanup_expired_reset_codes',
    'update_password_reset_codes_updated_at'
);