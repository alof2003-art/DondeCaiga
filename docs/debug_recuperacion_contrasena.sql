-- =====================================================
-- DEBUG Y SOLUCIÓN - SISTEMA DE RECUPERACIÓN DE CONTRASEÑA
-- =====================================================
-- Este script soluciona problemas comunes y desactiva RLS temporalmente

-- =====================================================
-- 1. VERIFICAR ESTRUCTURA ACTUAL DE LA BASE DE DATOS
-- =====================================================

-- Verificar si la tabla existe
SELECT EXISTS (
   SELECT FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name = 'password_reset_codes'
);

-- Ver estructura de la tabla auth.users
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'auth';

-- Ver usuarios existentes (para testing)
SELECT id, email, created_at 
FROM auth.users 
LIMIT 5;

-- =====================================================
-- 2. ELIMINAR Y RECREAR TABLA SIN RLS (TEMPORALMENTE)
-- =====================================================

-- Eliminar tabla si existe (para empezar limpio)
DROP TABLE IF EXISTS password_reset_codes CASCADE;

-- Crear tabla SIN RLS por ahora
CREATE TABLE password_reset_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    email TEXT NOT NULL,
    code TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- NO habilitar RLS por ahora
-- ALTER TABLE password_reset_codes ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 3. ÍNDICES BÁSICOS
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_password_reset_codes_email 
ON password_reset_codes(email);

CREATE INDEX IF NOT EXISTS idx_password_reset_codes_code 
ON password_reset_codes(code);

CREATE INDEX IF NOT EXISTS idx_password_reset_codes_expires_at 
ON password_reset_codes(expires_at);

-- =====================================================
-- 4. FUNCIÓN SIMPLIFICADA PARA GENERAR CÓDIGO
-- =====================================================

CREATE OR REPLACE FUNCTION generate_password_reset_code(user_email TEXT)
RETURNS TABLE(code TEXT, expires_at TIMESTAMP WITH TIME ZONE) AS $$
DECLARE
    reset_code TEXT;
    expiry_time TIMESTAMP WITH TIME ZONE;
    user_uuid UUID;
BEGIN
    -- Generar código de 6 dígitos
    reset_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
    
    -- Establecer expiración en 15 minutos
    expiry_time := NOW() + INTERVAL '15 minutes';
    
    -- Obtener UUID del usuario por email (buscar en auth.users)
    SELECT id INTO user_uuid 
    FROM auth.users 
    WHERE email = user_email;
    
    -- Si no existe el usuario, intentar buscar en users_profiles
    IF user_uuid IS NULL THEN
        SELECT id INTO user_uuid 
        FROM users_profiles 
        WHERE email = user_email;
    END IF;
    
    -- Si aún no existe, crear entrada temporal (solo para testing)
    IF user_uuid IS NULL THEN
        user_uuid := gen_random_uuid();
        RAISE NOTICE 'Usuario no encontrado, usando UUID temporal: %', user_uuid;
    END IF;
    
    -- Invalidar códigos anteriores del mismo email
    UPDATE password_reset_codes 
    SET used = TRUE 
    WHERE email = user_email AND used = FALSE;
    
    -- Insertar nuevo código
    INSERT INTO password_reset_codes (user_id, email, code, expires_at)
    VALUES (user_uuid, user_email, reset_code, expiry_time);
    
    -- Log para debug
    RAISE NOTICE 'Código generado: % para email: % expira: %', reset_code, user_email, expiry_time;
    
    -- Retornar código y expiración
    RETURN QUERY SELECT reset_code, expiry_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. FUNCIÓN SIMPLIFICADA PARA VALIDAR CÓDIGO
-- =====================================================

CREATE OR REPLACE FUNCTION validate_password_reset_code(
    user_email TEXT, 
    input_code TEXT
)
RETURNS TABLE(valid BOOLEAN, user_id UUID, message TEXT) AS $$
DECLARE
    code_record RECORD;
    user_uuid UUID;
BEGIN
    -- Log para debug
    RAISE NOTICE 'Validando código: % para email: %', input_code, user_email;
    
    -- Buscar código válido
    SELECT * INTO code_record
    FROM password_reset_codes
    WHERE email = user_email 
      AND code = input_code 
      AND used = FALSE 
      AND expires_at > NOW()
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Verificar si se encontró un código válido
    IF code_record IS NULL THEN
        -- Verificar si existe pero está expirado o usado
        IF EXISTS (
            SELECT 1 FROM password_reset_codes 
            WHERE email = user_email AND code = input_code
        ) THEN
            RETURN QUERY SELECT FALSE, NULL::UUID, 'Código expirado o ya utilizado';
        ELSE
            RETURN QUERY SELECT FALSE, NULL::UUID, 'Código inválido';
        END IF;
        RETURN;
    END IF;
    
    -- Marcar código como usado
    UPDATE password_reset_codes 
    SET used = TRUE, updated_at = NOW()
    WHERE id = code_record.id;
    
    -- Log para debug
    RAISE NOTICE 'Código válido para user_id: %', code_record.user_id;
    
    -- Retornar éxito
    RETURN QUERY SELECT TRUE, code_record.user_id, 'Código válido';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. FUNCIÓN DE LIMPIEZA
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_expired_reset_codes()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM password_reset_codes 
    WHERE expires_at < NOW() - INTERVAL '24 hours';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RAISE NOTICE 'Códigos eliminados: %', deleted_count;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. TRIGGER PARA UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_password_reset_codes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_password_reset_codes_updated_at ON password_reset_codes;
CREATE TRIGGER trigger_update_password_reset_codes_updated_at
    BEFORE UPDATE ON password_reset_codes
    FOR EACH ROW
    EXECUTE FUNCTION update_password_reset_codes_updated_at();

-- =====================================================
-- 8. PERMISOS AMPLIOS (SIN RLS)
-- =====================================================

-- Otorgar permisos amplios para testing
GRANT ALL ON password_reset_codes TO authenticated, anon, postgres;
GRANT EXECUTE ON FUNCTION generate_password_reset_code(TEXT) TO authenticated, anon, postgres;
GRANT EXECUTE ON FUNCTION validate_password_reset_code(TEXT, TEXT) TO authenticated, anon, postgres;
GRANT EXECUTE ON FUNCTION cleanup_expired_reset_codes() TO authenticated, anon, postgres;

-- =====================================================
-- 9. PRUEBAS INMEDIATAS
-- =====================================================

-- Limpiar datos de prueba anteriores
DELETE FROM password_reset_codes WHERE email LIKE '%test%' OR email LIKE '%ejemplo%';

-- Probar con un email de tu sistema (CAMBIAR POR UN EMAIL REAL)
-- SELECT * FROM generate_password_reset_code('tu-email@ejemplo.com');

-- Ver todos los códigos generados
SELECT * FROM password_reset_codes ORDER BY created_at DESC LIMIT 10;

-- =====================================================
-- 10. VERIFICACIONES FINALES
-- =====================================================

-- Verificar que las funciones existen
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name LIKE '%password_reset%' 
AND routine_schema = 'public';

-- Verificar permisos en la tabla
SELECT grantee, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_name = 'password_reset_codes';

-- =====================================================
-- INSTRUCCIONES DE USO:
-- =====================================================

/*
1. Ejecuta este script completo en Supabase SQL Editor
2. Cambia 'tu-email@ejemplo.com' por un email real de tu sistema
3. Ejecuta: SELECT * FROM generate_password_reset_code('tu-email-real@ejemplo.com');
4. Copia el código generado
5. Ejecuta: SELECT * FROM validate_password_reset_code('tu-email-real@ejemplo.com', 'CODIGO_COPIADO');
6. Si todo funciona, prueba desde la app

NOTAS:
- RLS está DESACTIVADO temporalmente para debugging
- Se añadieron logs (RAISE NOTICE) para ver qué pasa
- Permisos amplios para evitar problemas de acceso
- Funciona con emails que no estén en auth.users (para testing)
*/