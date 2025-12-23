-- =====================================================
-- LIMPIAR SISTEMA DE RECUPERACIÓN PERSONALIZADO
-- =====================================================
-- Este script elimina todo el sistema personalizado de recuperación
-- para usar el sistema nativo de Supabase

-- =====================================================
-- 1. ELIMINAR FUNCIONES PERSONALIZADAS
-- =====================================================

-- Eliminar función de generar código
DROP FUNCTION IF EXISTS generate_password_reset_code(TEXT);

-- Eliminar función de validar código
DROP FUNCTION IF EXISTS validate_password_reset_code(TEXT, TEXT);

-- Eliminar función de limpieza
DROP FUNCTION IF EXISTS cleanup_expired_reset_codes();

-- Eliminar función de trigger
DROP FUNCTION IF EXISTS update_password_reset_codes_updated_at();

-- =====================================================
-- 2. ELIMINAR TRIGGERS
-- =====================================================

-- Eliminar trigger de updated_at
DROP TRIGGER IF EXISTS trigger_update_password_reset_codes_updated_at ON password_reset_codes;

-- =====================================================
-- 3. ELIMINAR POLÍTICAS RLS
-- =====================================================

-- Eliminar políticas de la tabla
DROP POLICY IF EXISTS "Users can view their own reset codes" ON password_reset_codes;
DROP POLICY IF EXISTS "Allow insert reset codes" ON password_reset_codes;
DROP POLICY IF EXISTS "Users can update their own reset codes" ON password_reset_codes;

-- =====================================================
-- 4. ELIMINAR ÍNDICES
-- =====================================================

-- Eliminar índices personalizados
DROP INDEX IF EXISTS idx_password_reset_codes_email;
DROP INDEX IF EXISTS idx_password_reset_codes_code;
DROP INDEX IF EXISTS idx_password_reset_codes_user_id;
DROP INDEX IF EXISTS idx_password_reset_codes_expires_at;

-- =====================================================
-- 5. ELIMINAR TABLA COMPLETA
-- =====================================================

-- Eliminar tabla de códigos de recuperación
DROP TABLE IF EXISTS password_reset_codes;

-- =====================================================
-- 6. LIMPIAR CRON JOBS (SI EXISTEN)
-- =====================================================

-- Eliminar job de limpieza automática si existe
-- SELECT cron.unschedule('cleanup-reset-codes');

-- =====================================================
-- CONFIRMACIÓN
-- =====================================================

-- Verificar que todo se eliminó correctamente
DO $$
BEGIN
    -- Verificar que la tabla no existe
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'password_reset_codes') THEN
        RAISE NOTICE 'Sistema de recuperación personalizado eliminado correctamente';
    ELSE
        RAISE NOTICE 'ADVERTENCIA: La tabla password_reset_codes aún existe';
    END IF;
END;
$$;

-- =====================================================
-- NOTAS IMPORTANTES
-- =====================================================

/*
DESPUÉS DE EJECUTAR ESTE SCRIPT:

1. El sistema personalizado de códigos de recuperación será eliminado completamente
2. Usar el sistema nativo de Supabase: supabase.auth.resetPasswordForEmail()
3. Configurar la URL de redirección en Supabase Dashboard
4. Actualizar el código Flutter para usar el sistema nativo

VENTAJAS DEL SISTEMA NATIVO:
- Más seguro y confiable
- Mantenido por Supabase
- Integración automática con auth
- Menos código personalizado
- Mejor experiencia de usuario
*/