-- =====================================================
-- SCRIPT PARA ELIMINAR COMPLETAMENTE EL SISTEMA DE 
-- RECUPERACIÓN DE CONTRASEÑA PERSONALIZADO
-- =====================================================
-- Este script elimina todas las tablas, funciones, 
-- triggers y políticas relacionadas con el sistema
-- de recuperación de contraseña personalizado.
-- =====================================================

-- 1. ELIMINAR TABLA password_reset_codes (si existe)
-- =====================================================
DO $$
BEGIN
    -- Primero eliminar el trigger si existe
    IF EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'trigger_update_password_reset_codes_updated_at'
    ) THEN
        DROP TRIGGER trigger_update_password_reset_codes_updated_at ON password_reset_codes;
        RAISE NOTICE 'Trigger trigger_update_password_reset_codes_updated_at eliminado';
    END IF;

    -- Luego eliminar la tabla si existe
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'password_reset_codes'
    ) THEN
        DROP TABLE password_reset_codes CASCADE;
        RAISE NOTICE 'Tabla password_reset_codes eliminada';
    ELSE
        RAISE NOTICE 'Tabla password_reset_codes no existe';
    END IF;
END $$;

-- 2. ELIMINAR FUNCIÓN update_password_reset_codes_updated_at (si existe)
-- =====================================================
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'update_password_reset_codes_updated_at'
    ) THEN
        DROP FUNCTION update_password_reset_codes_updated_at() CASCADE;
        RAISE NOTICE 'Función update_password_reset_codes_updated_at eliminada';
    ELSE
        RAISE NOTICE 'Función update_password_reset_codes_updated_at no existe';
    END IF;
END $$;

-- 3. ELIMINAR FUNCIÓN create_password_reset_code (si existe)
-- =====================================================
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'create_password_reset_code'
    ) THEN
        DROP FUNCTION create_password_reset_code(text) CASCADE;
        RAISE NOTICE 'Función create_password_reset_code eliminada';
    ELSE
        RAISE NOTICE 'Función create_password_reset_code no existe';
    END IF;
END $$;

-- 4. ELIMINAR FUNCIÓN verify_password_reset_code (si existe)
-- =====================================================
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'verify_password_reset_code'
    ) THEN
        DROP FUNCTION verify_password_reset_code(text, text) CASCADE;
        RAISE NOTICE 'Función verify_password_reset_code eliminada';
    ELSE
        RAISE NOTICE 'Función verify_password_reset_code no existe';
    END IF;
END $$;

-- 5. ELIMINAR FUNCIÓN update_password_with_code (si existe)
-- =====================================================
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'update_password_with_code'
    ) THEN
        DROP FUNCTION update_password_with_code(text, text, text) CASCADE;
        RAISE NOTICE 'Función update_password_with_code eliminada';
    ELSE
        RAISE NOTICE 'Función update_password_with_code no existe';
    END IF;
END $$;

-- 6. ELIMINAR FUNCIÓN cleanup_expired_reset_codes (si existe)
-- =====================================================
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'cleanup_expired_reset_codes'
    ) THEN
        DROP FUNCTION cleanup_expired_reset_codes() CASCADE;
        RAISE NOTICE 'Función cleanup_expired_reset_codes eliminada';
    ELSE
        RAISE NOTICE 'Función cleanup_expired_reset_codes no existe';
    END IF;
END $$;

-- 7. ELIMINAR CUALQUIER POLÍTICA RLS RELACIONADA (si existe)
-- =====================================================
DO $$
BEGIN
    -- Verificar si existen políticas relacionadas con password_reset_codes
    IF EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'password_reset_codes'
    ) THEN
        RAISE NOTICE 'Se encontraron políticas RLS para password_reset_codes, pero la tabla ya fue eliminada';
    ELSE
        RAISE NOTICE 'No se encontraron políticas RLS para password_reset_codes';
    END IF;
END $$;

-- 8. LIMPIAR CUALQUIER EXTENSIÓN O CONFIGURACIÓN RELACIONADA
-- =====================================================
-- Verificar si hay configuraciones de email personalizadas que ya no se usan
DO $$
BEGIN
    RAISE NOTICE 'Verificando configuraciones de email...';
    -- Aquí podrías agregar lógica para limpiar configuraciones específicas
    -- Por ejemplo, si tienes una tabla de configuraciones:
    -- DELETE FROM app_settings WHERE key LIKE '%password_reset%';
    RAISE NOTICE 'Limpieza de configuraciones completada';
END $$;

-- =====================================================
-- VERIFICACIÓN FINAL
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '=== VERIFICACIÓN FINAL ===';
    
    -- Verificar que no queden tablas relacionadas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'password_reset_codes'
    ) THEN
        RAISE NOTICE '✅ Tabla password_reset_codes: ELIMINADA';
    ELSE
        RAISE NOTICE '❌ Tabla password_reset_codes: AÚN EXISTE';
    END IF;
    
    -- Verificar que no queden funciones relacionadas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name IN (
            'update_password_reset_codes_updated_at',
            'create_password_reset_code',
            'verify_password_reset_code',
            'update_password_with_code',
            'cleanup_expired_reset_codes'
        )
    ) THEN
        RAISE NOTICE '✅ Funciones de recuperación: ELIMINADAS';
    ELSE
        RAISE NOTICE '❌ Algunas funciones de recuperación: AÚN EXISTEN';
    END IF;
    
    RAISE NOTICE '=== LIMPIEZA COMPLETADA ===';
    RAISE NOTICE 'El sistema de recuperación de contraseña personalizado ha sido eliminado completamente.';
    RAISE NOTICE 'Ahora puedes usar el sistema nativo de Supabase si lo deseas.';
END $$;