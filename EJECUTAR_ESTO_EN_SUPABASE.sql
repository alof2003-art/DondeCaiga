-- ============================================
-- EJECUTAR ESTE SQL EN SUPABASE
-- ============================================

-- 1. Borrar tabla si existe (para empezar limpio)
DROP TABLE IF EXISTS reservas CASCADE;

-- 2. Crear tabla de reservas
CREATE TABLE reservas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    propiedad_id UUID NOT NULL REFERENCES propiedades(id) ON DELETE CASCADE,
    viajero_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'confirmada', 'rechazada', 'completada', 'cancelada')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fechas_validas CHECK (fecha_fin >= fecha_inicio)
);

-- 3. Crear índices
CREATE INDEX idx_reservas_propiedad ON reservas(propiedad_id);
CREATE INDEX idx_reservas_viajero ON reservas(viajero_id);
CREATE INDEX idx_reservas_estado ON reservas(estado);
CREATE INDEX idx_reservas_fechas ON reservas(fecha_inicio, fecha_fin);

-- 4. Trigger para updated_at
CREATE OR REPLACE FUNCTION update_reservas_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_reservas_updated_at
    BEFORE UPDATE ON reservas
    FOR EACH ROW
    EXECUTE FUNCTION update_reservas_updated_at();

-- 5. Habilitar RLS
ALTER TABLE reservas ENABLE ROW LEVEL SECURITY;

-- 6. Políticas RLS

-- Viajeros pueden ver sus propias reservas
CREATE POLICY "Viajeros pueden ver sus reservas"
    ON reservas FOR SELECT
    USING (auth.uid() = viajero_id);

-- Anfitriones pueden ver reservas de sus propiedades
CREATE POLICY "Anfitriones pueden ver reservas de sus propiedades"
    ON reservas FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM propiedades
            WHERE propiedades.id = reservas.propiedad_id
            AND propiedades.anfitrion_id = auth.uid()
        )
    );

-- Viajeros pueden crear reservas
CREATE POLICY "Viajeros pueden crear reservas"
    ON reservas FOR INSERT
    WITH CHECK (auth.uid() = viajero_id);

-- Anfitriones pueden actualizar estado de reservas de sus propiedades
CREATE POLICY "Anfitriones pueden actualizar estado de reservas"
    ON reservas FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM propiedades
            WHERE propiedades.id = reservas.propiedad_id
            AND propiedades.anfitrion_id = auth.uid()
        )
    );

-- Viajeros pueden cancelar sus propias reservas
CREATE POLICY "Viajeros pueden cancelar sus reservas"
    ON reservas FOR UPDATE
    USING (auth.uid() = viajero_id)
    WITH CHECK (estado = 'cancelada');

-- Admins pueden hacer todo
CREATE POLICY "Admins tienen acceso completo a reservas"
    ON reservas FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users_profiles
            WHERE users_profiles.id = auth.uid()
            AND users_profiles.rol_id = 3
        )
    );

-- ============================================
-- 7. AGREGAR CÓDIGO DE VERIFICACIÓN
-- ============================================

-- Agregar columna de código de verificación
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

-- Crear trigger
DROP TRIGGER IF EXISTS trigger_asignar_codigo_verificacion ON reservas;
CREATE TRIGGER trigger_asignar_codigo_verificacion
    BEFORE UPDATE ON reservas
    FOR EACH ROW
    EXECUTE FUNCTION asignar_codigo_verificacion();

-- ============================================
-- 8. CREAR TABLA DE MENSAJES
-- ============================================

-- Crear tabla de mensajes
CREATE TABLE IF NOT EXISTS mensajes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reserva_id UUID NOT NULL REFERENCES reservas(id) ON DELETE CASCADE,
    remitente_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
    mensaje TEXT NOT NULL,
    leido BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_mensajes_reserva ON mensajes(reserva_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_remitente ON mensajes(remitente_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_created_at ON mensajes(created_at);

-- Habilitar RLS
ALTER TABLE mensajes ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para mensajes

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

-- Habilitar Realtime para la tabla mensajes
ALTER PUBLICATION supabase_realtime ADD TABLE mensajes;

-- ============================================
-- ✅ ¡LISTO! Sistema de Chat Completo
-- ============================================
-- 
-- Ahora tienes:
-- ✅ Tabla de reservas con código de verificación
-- ✅ Tabla de mensajes con RLS y Realtime
-- ✅ Códigos generados automáticamente al confirmar
-- ✅ Chat en tiempo real funcionando
--
-- Prueba:
-- 1. Crear una reserva como viajero
-- 2. Aprobar la reserva como anfitrión
-- 3. Ver el código en la pestaña "Chat"
-- 4. Enviar mensajes en tiempo real
-- ============================================
