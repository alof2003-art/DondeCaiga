-- ============================================
-- SISTEMA DE CHAT COMPLETO - SQL FINAL
-- Ejecutar este archivo en Supabase
-- ============================================

-- ============================================
-- 1. AGREGAR CÓDIGO DE VERIFICACIÓN A RESERVAS
-- ============================================

-- Agregar columna de código de verificación (si no existe)
ALTER TABLE reservas ADD COLUMN IF NOT EXISTS codigo_verificacion TEXT;

-- Función para generar código de 6 dígitos
CREATE OR REPLACE FUNCTION generar_codigo_verificacion()
RETURNS TEXT AS $$
BEGIN
    RETURN LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Trigger para generar código cuando se confirma una reserva
CREATE OR REPLACE FUNCTION asignar_codigo_verificacion()
RETURNS TRIGGER AS $$
BEGIN
    -- Si el estado cambia a 'confirmada' y no tiene código
    IF NEW.estado = 'confirmada' AND (OLD.codigo_verificacion IS NULL OR OLD.codigo_verificacion = '') THEN
        NEW.codigo_verificacion = generar_codigo_verificacion();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear trigger (DROP IF EXISTS para evitar errores)
DROP TRIGGER IF EXISTS trigger_asignar_codigo_verificacion ON reservas;
CREATE TRIGGER trigger_asignar_codigo_verificacion
    BEFORE UPDATE ON reservas
    FOR EACH ROW
    EXECUTE FUNCTION asignar_codigo_verificacion();

-- ============================================
-- 2. CREAR TABLA DE MENSAJES
-- ============================================

-- Eliminar tabla si existe (para empezar limpio)
DROP TABLE IF EXISTS mensajes CASCADE;

-- Crear tabla de mensajes con estructura correcta
CREATE TABLE mensajes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reserva_id UUID NOT NULL REFERENCES reservas(id) ON DELETE CASCADE,
    remitente_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
    mensaje TEXT NOT NULL,
    leido BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para mejorar rendimiento
CREATE INDEX idx_mensajes_reserva ON mensajes(reserva_id);
CREATE INDEX idx_mensajes_remitente ON mensajes(remitente_id);
CREATE INDEX idx_mensajes_created_at ON mensajes(created_at);

-- Habilitar RLS
ALTER TABLE mensajes ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 3. POLÍTICAS RLS PARA MENSAJES
-- ============================================

-- Eliminar políticas existentes (si existen)
DROP POLICY IF EXISTS "Participantes pueden ver mensajes de su reserva" ON mensajes;
DROP POLICY IF EXISTS "Participantes pueden enviar mensajes" ON mensajes;
DROP POLICY IF EXISTS "Usuarios pueden actualizar estado de lectura" ON mensajes;
DROP POLICY IF EXISTS "Admins tienen acceso completo a mensajes" ON mensajes;

-- Los participantes de una reserva pueden ver los mensajes
CREATE POLICY "Participantes pueden ver mensajes de su reserva"
    ON mensajes FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM reservas
            WHERE reservas.id = mensajes.reserva_id
            AND (reservas.viajero_id = auth.uid() OR 
                 EXISTS (
                     SELECT 1 FROM propiedades
                     WHERE propiedades.id = reservas.propiedad_id
                     AND propiedades.anfitrion_id = auth.uid()
                 ))
        )
    );

-- Los participantes pueden enviar mensajes
CREATE POLICY "Participantes pueden enviar mensajes"
    ON mensajes FOR INSERT
    WITH CHECK (
        auth.uid() = remitente_id AND
        EXISTS (
            SELECT 1 FROM reservas
            WHERE reservas.id = mensajes.reserva_id
            AND reservas.estado = 'confirmada'
            AND (reservas.viajero_id = auth.uid() OR 
                 EXISTS (
                     SELECT 1 FROM propiedades
                     WHERE propiedades.id = reservas.propiedad_id
                     AND propiedades.anfitrion_id = auth.uid()
                 ))
        )
    );

-- Los usuarios pueden marcar sus mensajes como leídos
CREATE POLICY "Usuarios pueden actualizar estado de lectura"
    ON mensajes FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM reservas
            WHERE reservas.id = mensajes.reserva_id
            AND (reservas.viajero_id = auth.uid() OR 
                 EXISTS (
                     SELECT 1 FROM propiedades
                     WHERE propiedades.id = reservas.propiedad_id
                     AND propiedades.anfitrion_id = auth.uid()
                 ))
        )
    )
    WITH CHECK (leido = TRUE);

-- Admins pueden hacer todo
CREATE POLICY "Admins tienen acceso completo a mensajes"
    ON mensajes FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users_profiles
            WHERE users_profiles.id = auth.uid()
            AND users_profiles.rol_id = 3
        )
    );

-- ============================================
-- 4. HABILITAR REALTIME PARA MENSAJES
-- ============================================

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE mensajes;
EXCEPTION
    WHEN duplicate_object THEN
        NULL;
END $$;

-- ============================================
-- ✅ SISTEMA DE CHAT COMPLETADO
-- ============================================
-- 
-- Ahora tienes:
-- ✅ Tabla de reservas con código de verificación
-- ✅ Trigger que genera códigos automáticamente al confirmar
-- ✅ Tabla de mensajes con estructura correcta
-- ✅ Políticas RLS para seguridad
-- ✅ Realtime habilitado para mensajes instantáneos
--
-- Estructura de la tabla mensajes:
-- - id: UUID (primary key)
-- - reserva_id: UUID (referencia a reservas)
-- - remitente_id: UUID (referencia a users_profiles)
-- - mensaje: TEXT (contenido del mensaje)
-- - leido: BOOLEAN (estado de lectura)
-- - created_at: TIMESTAMPTZ (fecha de creación)
--
-- Flujo del sistema:
-- 1. Viajero crea reserva → estado: "pendiente"
-- 2. Anfitrión aprueba → estado: "confirmada" + código generado
-- 3. Ambos ven la reserva en "Chat"
-- 4. Pueden enviar mensajes en tiempo real
-- 5. Los mensajes aparecen instantáneamente
-- ============================================
