-- =====================================================
-- LIMPIAR SISTEMA DE RECUPERACIÓN PERSONALIZADO - VERSIÓN SIMPLE
-- =====================================================
-- Este script elimina todo el sistema personalizado de recuperación
-- Ejecutar línea por línea si hay problemas

-- 1. ELIMINAR FUNCIONES
DROP FUNCTION IF EXISTS generate_password_reset_code(TEXT);
DROP FUNCTION IF EXISTS validate_password_reset_code(TEXT, TEXT);
DROP FUNCTION IF EXISTS cleanup_expired_reset_codes();
DROP FUNCTION IF EXISTS update_password_reset_codes_updated_at();

-- 2. ELIMINAR TRIGGERS
DROP TRIGGER IF EXISTS trigger_update_password_reset_codes_updated_at ON password_reset_codes;

-- 3. ELIMINAR POLÍTICAS RLS
DROP POLICY IF EXISTS "Users can view their own reset codes" ON password_reset_codes;
DROP POLICY IF EXISTS "Allow insert reset codes" ON password_reset_codes;
DROP POLICY IF EXISTS "Users can update their own reset codes" ON password_reset_codes;

-- 4. ELIMINAR ÍNDICES
DROP INDEX IF EXISTS idx_password_reset_codes_email;
DROP INDEX IF EXISTS idx_password_reset_codes_code;
DROP INDEX IF EXISTS idx_password_reset_codes_user_id;
DROP INDEX IF EXISTS idx_password_reset_codes_expires_at;

-- 5. ELIMINAR TABLA
DROP TABLE IF EXISTS password_reset_codes;

-- 6. VERIFICAR (ejecutar por separado si es necesario)
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'password_reset_codes') 
        THEN 'ADVERTENCIA: La tabla password_reset_codes aún existe'
        ELSE 'Sistema eliminado correctamente'
    END as resultado;