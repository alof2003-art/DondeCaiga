-- Crear tabla de reservas
CREATE TABLE IF NOT EXISTS reservas (
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

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_reservas_propiedad ON reservas(propiedad_id);
CREATE INDEX IF NOT EXISTS idx_reservas_viajero ON reservas(viajero_id);
CREATE INDEX IF NOT EXISTS idx_reservas_estado ON reservas(estado);
CREATE INDEX IF NOT EXISTS idx_reservas_fechas ON reservas(fecha_inicio, fecha_fin);

-- Trigger para actualizar updated_at
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

-- Habilitar RLS
ALTER TABLE reservas ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para reservas

-- Los viajeros pueden ver sus propias reservas
CREATE POLICY "Viajeros pueden ver sus reservas"
    ON reservas FOR SELECT
    USING (auth.uid() = viajero_id);

-- Los anfitriones pueden ver reservas de sus propiedades
CREATE POLICY "Anfitriones pueden ver reservas de sus propiedades"
    ON reservas FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM propiedades
            WHERE propiedades.id = reservas.propiedad_id
            AND propiedades.anfitrion_id = auth.uid()
        )
    );

-- Los viajeros pueden crear reservas
CREATE POLICY "Viajeros pueden crear reservas"
    ON reservas FOR INSERT
    WITH CHECK (auth.uid() = viajero_id);

-- Los anfitriones pueden actualizar el estado de reservas de sus propiedades
CREATE POLICY "Anfitriones pueden actualizar estado de reservas"
    ON reservas FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM propiedades
            WHERE propiedades.id = reservas.propiedad_id
            AND propiedades.anfitrion_id = auth.uid()
        )
    );

-- Los viajeros pueden cancelar sus propias reservas
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
