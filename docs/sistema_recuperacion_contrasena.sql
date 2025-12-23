-- =====================================================
-- SISTEMA DE RECUPERACIÓN DE CONTRASEÑA
-- =====================================================
-- Este archivo contiene todas las modificaciones necesarias
-- para implementar el sistema de recuperación de contraseña

-- =====================================================
-- 1. TABLA PARA CÓDIGOS DE RECUPERACIÓN
-- =====================================================

-- Crear tabla para almacenar códigos de recuperación temporales
CREATE TABLE IF NOT EXISTS password_reset_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    code TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 2. ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

-- Índice para búsquedas por email
CREATE INDEX IF NOT EXISTS idx_password_reset_codes_email 
ON password_reset_codes(email);

-- Índice para búsquedas por código
CREATE INDEX IF NOT EXISTS idx_password_reset_codes_code 
ON password_reset_codes(code);

-- Índice para búsquedas por usuario
CREATE INDEX IF NOT EXISTS idx_password_reset_codes_user_id 
ON password_reset_codes(user_id);

-- Índice para limpiar códigos expirados
CREATE INDEX IF NOT EXISTS idx_password_reset_codes_expires_at 
ON password_reset_codes(expires_at);

-- =====================================================
-- 3. POLÍTICAS RLS (ROW LEVEL SECURITY)
-- =====================================================

-- Habilitar RLS en la tabla
ALTER TABLE password_reset_codes ENABLE ROW LEVEL SECURITY;

-- Política para que los usuarios solo puedan ver sus propios códigos
CREATE POLICY "Users can view their own reset codes" ON password_reset_codes
    FOR SELECT USING (auth.uid() = user_id);

-- Política para insertar códigos (permitir a todos para el proceso de recuperación)
CREATE POLICY "Allow insert reset codes" ON password_reset_codes
    FOR INSERT WITH CHECK (true);

-- Política para actualizar códigos (marcar como usados)
CREATE POLICY "Users can update their own reset codes" ON password_reset_codes
    FOR UPDATE USING (auth.uid() = user_id);

-- =====================================================
-- 4. FUNCIÓN PARA GENERAR CÓDIGO DE RECUPERACIÓN
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
    
    -- Obtener UUID del usuario por email
    SELECT id INTO user_uuid 
    FROM auth.users 
    WHERE email = user_email;
    
    -- Si no existe el usuario, retornar error
    IF user_uuid IS NULL THEN
        RAISE EXCEPTION 'Usuario no encontrado con email: %', user_email;
    END IF;
    
    -- Invalidar códigos anteriores del mismo usuario
    UPDATE password_reset_codes 
    SET used = TRUE 
    WHERE user_id = user_uuid AND used = FALSE;
    
    -- Insertar nuevo código
    INSERT INTO password_reset_codes (user_id, email, code, expires_at)
    VALUES (user_uuid, user_email, reset_code, expiry_time);
    
    -- Retornar código y expiración
    RETURN QUERY SELECT reset_code, expiry_time;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. FUNCIÓN PARA VALIDAR CÓDIGO DE RECUPERACIÓN
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
    -- Obtener UUID del usuario por email
    SELECT id INTO user_uuid 
    FROM auth.users 
    WHERE email = user_email;
    
    -- Si no existe el usuario
    IF user_uuid IS NULL THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, 'Usuario no encontrado';
        RETURN;
    END IF;
    
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
        -- Verificar si existe pero está expirado
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
    
    -- Retornar éxito
    RETURN QUERY SELECT TRUE, user_uuid, 'Código válido';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. FUNCIÓN PARA LIMPIAR CÓDIGOS EXPIRADOS
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_expired_reset_codes()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- Eliminar códigos expirados (más de 24 horas)
    DELETE FROM password_reset_codes 
    WHERE expires_at < NOW() - INTERVAL '24 hours';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. TRIGGER PARA ACTUALIZAR updated_at
-- =====================================================

CREATE OR REPLACE FUNCTION update_password_reset_codes_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_password_reset_codes_updated_at
    BEFORE UPDATE ON password_reset_codes
    FOR EACH ROW
    EXECUTE FUNCTION update_password_reset_codes_updated_at();

-- =====================================================
-- 8. CONFIGURACIÓN DE LIMPIEZA AUTOMÁTICA (OPCIONAL)
-- =====================================================

-- Crear extensión para cron jobs si no existe
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Programar limpieza diaria a las 2:00 AM
-- SELECT cron.schedule('cleanup-reset-codes', '0 2 * * *', 'SELECT cleanup_expired_reset_codes();');

-- =====================================================
-- 9. PERMISOS Y SEGURIDAD
-- =====================================================

-- Otorgar permisos necesarios para las funciones
GRANT EXECUTE ON FUNCTION generate_password_reset_code(TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION validate_password_reset_code(TEXT, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION cleanup_expired_reset_codes() TO authenticated;

-- =====================================================
-- 10. COMENTARIOS Y DOCUMENTACIÓN
-- =====================================================

COMMENT ON TABLE password_reset_codes IS 'Almacena códigos temporales para recuperación de contraseña';
COMMENT ON COLUMN password_reset_codes.code IS 'Código de 6 dígitos enviado por email';
COMMENT ON COLUMN password_reset_codes.expires_at IS 'Fecha y hora de expiración del código (15 minutos)';
COMMENT ON COLUMN password_reset_codes.used IS 'Indica si el código ya fue utilizado';

COMMENT ON FUNCTION generate_password_reset_code(TEXT) IS 'Genera un nuevo código de recuperación para un email';
COMMENT ON FUNCTION validate_password_reset_code(TEXT, TEXT) IS 'Valida un código de recuperación';
COMMENT ON FUNCTION cleanup_expired_reset_codes() IS 'Limpia códigos expirados de la base de datos';

-- =====================================================
-- INSTRUCCIONES DE INSTALACIÓN
-- =====================================================

/*
PASOS PARA IMPLEMENTAR:

1. Ejecutar este script completo en el SQL Editor de Supabase
2. Verificar que todas las tablas y funciones se crearon correctamente
3. Probar las funciones con datos de prueba
4. Configurar el servicio de email en Supabase (opcional para emails automáticos)

FUNCIONES PRINCIPALES:
- generate_password_reset_code('email@ejemplo.com') - Genera código
- validate_password_reset_code('email@ejemplo.com', '123456') - Valida código
- cleanup_expired_reset_codes() - Limpia códigos expirados

SEGURIDAD:
- Códigos expiran en 15 minutos
- Solo un código activo por usuario
- RLS habilitado para proteger datos
- Códigos se marcan como usados después de validación
*/