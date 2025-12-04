-- ============================================
-- ESQUEMA COMPLETO DE BASE DE DATOS
-- Aplicación: Donde Caiga
-- ============================================

-- ============================================
-- 1. TABLA DE ROLES
-- ============================================
CREATE TABLE IF NOT EXISTS roles (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(50) UNIQUE NOT NULL,
  descripcion TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insertar los 3 roles
INSERT INTO roles (nombre, descripcion) VALUES
  ('viajero', 'Usuario que busca alojamiento'),
  ('anfitrion', 'Usuario que ofrece alojamiento'),
  ('admin', 'Administrador del sistema')
ON CONFLICT (nombre) DO NOTHING;

-- ============================================
-- 2. ACTUALIZAR TABLA users_profiles
-- ============================================
-- Agregar columna de rol (por defecto viajero)
ALTER TABLE users_profiles 
ADD COLUMN IF NOT EXISTS rol_id INTEGER REFERENCES roles(id) DEFAULT 1;

-- Agregar columna de estado de cuenta
ALTER TABLE users_profiles
ADD COLUMN IF NOT EXISTS estado_cuenta VARCHAR(20) DEFAULT 'activo';

-- Agregar columna de fecha de actualización
ALTER TABLE users_profiles
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- ============================================
-- 3. TABLA DE PROPIEDADES/ALOJAMIENTOS
-- ============================================
CREATE TABLE IF NOT EXISTS propiedades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  anfitrion_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
  titulo VARCHAR(200) NOT NULL,
  descripcion TEXT,
  direccion TEXT NOT NULL,
  ciudad VARCHAR(100),
  pais VARCHAR(100),
  latitud DECIMAL(10, 8),
  longitud DECIMAL(11, 8),
  capacidad_personas INTEGER NOT NULL,
  numero_habitaciones INTEGER,
  numero_banos INTEGER,
  foto_principal_url TEXT,
  estado VARCHAR(20) DEFAULT 'activo', -- activo, inactivo, pendiente
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_propiedades_anfitrion ON propiedades(anfitrion_id);
CREATE INDEX IF NOT EXISTS idx_propiedades_ciudad ON propiedades(ciudad);
CREATE INDEX IF NOT EXISTS idx_propiedades_estado ON propiedades(estado);

-- ============================================
-- 4. TABLA DE FOTOS DE PROPIEDADES
-- ============================================
CREATE TABLE IF NOT EXISTS fotos_propiedades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  propiedad_id UUID NOT NULL REFERENCES propiedades(id) ON DELETE CASCADE,
  url_foto TEXT NOT NULL,
  es_principal BOOLEAN DEFAULT FALSE,
  orden INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fotos_propiedad ON fotos_propiedades(propiedad_id);

-- ============================================
-- 5. TABLA DE SOLICITUDES PARA SER ANFITRIÓN
-- ============================================
CREATE TABLE IF NOT EXISTS solicitudes_anfitrion (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
  foto_selfie_url TEXT NOT NULL,
  foto_propiedad_url TEXT NOT NULL,
  mensaje TEXT,
  estado VARCHAR(20) DEFAULT 'pendiente', -- pendiente, aprobada, rechazada
  fecha_solicitud TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  fecha_respuesta TIMESTAMP WITH TIME ZONE,
  admin_revisor_id UUID REFERENCES users_profiles(id),
  comentario_admin TEXT
);

CREATE INDEX IF NOT EXISTS idx_solicitudes_usuario ON solicitudes_anfitrion(usuario_id);
CREATE INDEX IF NOT EXISTS idx_solicitudes_estado ON solicitudes_anfitrion(estado);

-- ============================================
-- 6. TABLA DE RESERVAS
-- ============================================
CREATE TABLE IF NOT EXISTS reservas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  propiedad_id UUID NOT NULL REFERENCES propiedades(id) ON DELETE CASCADE,
  viajero_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  numero_personas INTEGER NOT NULL,
  estado VARCHAR(20) DEFAULT 'pendiente', -- pendiente, confirmada, cancelada, completada
  mensaje_viajero TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reservas_propiedad ON reservas(propiedad_id);
CREATE INDEX IF NOT EXISTS idx_reservas_viajero ON reservas(viajero_id);
CREATE INDEX IF NOT EXISTS idx_reservas_estado ON reservas(estado);

-- ============================================
-- 7. TABLA DE MENSAJES/CHAT
-- ============================================
CREATE TABLE IF NOT EXISTS mensajes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reserva_id UUID REFERENCES reservas(id) ON DELETE CASCADE,
  remitente_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
  destinatario_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
  contenido TEXT NOT NULL,
  leido BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mensajes_reserva ON mensajes(reserva_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_remitente ON mensajes(remitente_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_destinatario ON mensajes(destinatario_id);

-- ============================================
-- 8. TABLA DE RESEÑAS/CALIFICACIONES
-- ============================================
CREATE TABLE IF NOT EXISTS resenas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  propiedad_id UUID NOT NULL REFERENCES propiedades(id) ON DELETE CASCADE,
  viajero_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
  reserva_id UUID REFERENCES reservas(id) ON DELETE SET NULL,
  calificacion INTEGER CHECK (calificacion >= 1 AND calificacion <= 5),
  comentario TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_resenas_propiedad ON resenas(propiedad_id);
CREATE INDEX IF NOT EXISTS idx_resenas_viajero ON resenas(viajero_id);

-- ============================================
-- 9. POLÍTICAS DE SEGURIDAD (RLS)
-- ============================================

-- Habilitar RLS en todas las tablas
ALTER TABLE propiedades ENABLE ROW LEVEL SECURITY;
ALTER TABLE fotos_propiedades ENABLE ROW LEVEL SECURITY;
ALTER TABLE solicitudes_anfitrion ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservas ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes ENABLE ROW LEVEL SECURITY;
ALTER TABLE resenas ENABLE ROW LEVEL SECURITY;

-- Políticas para propiedades
CREATE POLICY "Todos pueden ver propiedades activas"
  ON propiedades FOR SELECT
  USING (estado = 'activo');

CREATE POLICY "Anfitriones pueden crear propiedades"
  ON propiedades FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = anfitrion_id);

CREATE POLICY "Anfitriones pueden actualizar sus propiedades"
  ON propiedades FOR UPDATE
  TO authenticated
  USING (auth.uid() = anfitrion_id);

-- Políticas para fotos de propiedades
CREATE POLICY "Todos pueden ver fotos de propiedades"
  ON fotos_propiedades FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Anfitriones pueden subir fotos de sus propiedades"
  ON fotos_propiedades FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM propiedades 
      WHERE id = propiedad_id AND anfitrion_id = auth.uid()
    )
  );

-- Políticas para solicitudes de anfitrión
CREATE POLICY "Usuarios pueden crear solicitudes"
  ON solicitudes_anfitrion FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "Usuarios pueden ver sus propias solicitudes"
  ON solicitudes_anfitrion FOR SELECT
  TO authenticated
  USING (auth.uid() = usuario_id);

CREATE POLICY "Admins pueden ver todas las solicitudes"
  ON solicitudes_anfitrion FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles 
      WHERE id = auth.uid() AND rol_id = 3
    )
  );

CREATE POLICY "Admins pueden actualizar solicitudes"
  ON solicitudes_anfitrion FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles 
      WHERE id = auth.uid() AND rol_id = 3
    )
  );

-- Políticas para reservas
CREATE POLICY "Usuarios pueden crear reservas"
  ON reservas FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = viajero_id);

CREATE POLICY "Usuarios pueden ver sus reservas"
  ON reservas FOR SELECT
  TO authenticated
  USING (
    auth.uid() = viajero_id OR 
    EXISTS (
      SELECT 1 FROM propiedades 
      WHERE id = propiedad_id AND anfitrion_id = auth.uid()
    )
  );

-- Políticas para mensajes
CREATE POLICY "Usuarios pueden enviar mensajes"
  ON mensajes FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = remitente_id);

CREATE POLICY "Usuarios pueden ver sus mensajes"
  ON mensajes FOR SELECT
  TO authenticated
  USING (auth.uid() = remitente_id OR auth.uid() = destinatario_id);

-- Políticas para reseñas
CREATE POLICY "Todos pueden ver reseñas"
  ON resenas FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Viajeros pueden crear reseñas"
  ON resenas FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = viajero_id);

-- ============================================
-- 10. FUNCIONES Y TRIGGERS
-- ============================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION actualizar_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para actualizar updated_at
CREATE TRIGGER trigger_actualizar_propiedades_updated_at
  BEFORE UPDATE ON propiedades
  FOR EACH ROW
  EXECUTE FUNCTION actualizar_updated_at();

CREATE TRIGGER trigger_actualizar_reservas_updated_at
  BEFORE UPDATE ON reservas
  FOR EACH ROW
  EXECUTE FUNCTION actualizar_updated_at();

-- ============================================
-- 11. CREAR CUENTA ADMIN
-- ============================================
-- Nota: La cuenta admin se creará cuando el usuario se registre
-- Luego ejecutaremos un script para darle privilegios de admin

-- ============================================
-- VERIFICACIÓN
-- ============================================
SELECT 'Esquema creado exitosamente' as mensaje;
