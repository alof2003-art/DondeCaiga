-- ============================================
-- HISTORIAL COMPLETO DE CAMBIOS SQL
-- Proyecto: Donde Caiga
-- Fecha: 2025-12-04
-- ============================================

-- Este archivo documenta TODOS los cambios SQL realizados
-- en el proyecto desde el inicio hasta la versión final

-- ============================================
-- FASE 1: CONFIGURACIÓN INICIAL
-- ============================================

-- Cambio 1.1: Crear tabla de perfiles de usuario
-- Fecha: Inicio del proyecto
-- Archivo original: supabase_setup.sql

CREATE TABLE IF NOT EXISTS users_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  nombre TEXT NOT NULL,
  telefono TEXT,
  foto_perfil_url TEXT,
  cedula_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  email_verified BOOLEAN DEFAULT FALSE
);

-- Cambio 1.2: Agregar índice para búsquedas por email
CREATE INDEX IF NOT EXISTS idx_users_profiles_email ON users_profiles(email);

-- Cambio 1.3: Habilitar RLS en users_profiles
ALTER TABLE users_profiles ENABLE ROW LEVEL SECURITY;

-- Cambio 1.4: Crear políticas iniciales para users_profiles
CREATE POLICY "Users can read own profile"
  ON users_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON users_profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON users_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Cambio 1.5: Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Cambio 1.6: Trigger para actualizar updated_at
CREATE TRIGGER update_users_profiles_updated_at
  BEFORE UPDATE ON users_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FASE 2: SISTEMA DE ROLES
-- ============================================

-- Cambio 2.1: Crear tabla de roles
-- Archivo: supabase_esquema_completo.sql

CREATE TABLE IF NOT EXISTS roles (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(50) UNIQUE NOT NULL,
  descripcion TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cambio 2.2: Insertar roles del sistema
INSERT INTO roles (nombre, descripcion) VALUES
  ('viajero', 'Usuario que busca alojamiento'),
  ('anfitrion', 'Usuario que ofrece alojamiento'),
  ('admin', 'Administrador del sistema')
ON CONFLICT (nombre) DO NOTHING;

-- Cambio 2.3: Agregar columna rol_id a users_profiles
ALTER TABLE users_profiles 
ADD COLUMN IF NOT EXISTS rol_id INTEGER REFERENCES roles(id) DEFAULT 1;

-- Cambio 2.4: Agregar columna estado_cuenta
ALTER TABLE users_profiles
ADD COLUMN IF NOT EXISTS estado_cuenta VARCHAR(20) DEFAULT 'activo';

-- Cambio 2.5: Habilitar RLS en roles
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;

-- Cambio 2.6: Política para leer roles
CREATE POLICY "Todos pueden leer roles"
ON roles FOR SELECT
TO public
USING (true);

-- ============================================
-- FASE 3: PROPIEDADES Y ALOJAMIENTOS
-- ============================================

-- Cambio 3.1: Crear tabla de propiedades
CREATE TABLE IF NOT EXISTS propiedades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
  estado VARCHAR(20) DEFAULT 'activo',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cambio 3.2: Índices para propiedades
CREATE INDEX IF NOT EXISTS idx_propiedades_anfitrion ON propiedades(anfitrion_id);
CREATE INDEX IF NOT EXISTS idx_propiedades_ciudad ON propiedades(ciudad);
CREATE INDEX IF NOT EXISTS idx_propiedades_estado ON propiedades(estado);

-- Cambio 3.3: Trigger para updated_at en propiedades
CREATE TRIGGER trigger_actualizar_propiedades_updated_at
  BEFORE UPDATE ON propiedades
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Cambio 3.4: Agregar campo tiene_garaje
-- Archivo: agregar_campo_garaje.sql
-- Fecha: Durante desarrollo
ALTER TABLE propiedades 
ADD COLUMN IF NOT EXISTS tiene_garaje BOOLEAN DEFAULT false;

-- Cambio 3.5: Crear tabla de fotos de propiedades
CREATE TABLE IF NOT EXISTS fotos_propiedades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  propiedad_id UUID NOT NULL REFERENCES propiedades(id) ON DELETE CASCADE,
  url_foto TEXT NOT NULL,
  es_principal BOOLEAN DEFAULT FALSE,
  orden INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fotos_propiedad ON fotos_propiedades(propiedad_id);

-- ============================================
-- FASE 4: SOLICITUDES DE ANFITRIÓN
-- ============================================

-- Cambio 4.1: Crear tabla de solicitudes
CREATE TABLE IF NOT EXISTS solicitudes_anfitrion (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
  foto_selfie_url TEXT NOT NULL,
  foto_propiedad_url TEXT NOT NULL,
  mensaje TEXT,
  estado VARCHAR(20) DEFAULT 'pendiente',
  fecha_solicitud TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  fecha_respuesta TIMESTAMP WITH TIME ZONE,
  admin_revisor_id UUID REFERENCES users_profiles(id),
  comentario_admin TEXT
);

-- Cambio 4.2: Índices para solicitudes
CREATE INDEX IF NOT EXISTS idx_solicitudes_usuario ON solicitudes_anfitrion(usuario_id);
CREATE INDEX IF NOT EXISTS idx_solicitudes_estado ON solicitudes_anfitrion(estado);

-- ============================================
-- FASE 5: SISTEMA DE RESERVAS
-- ============================================

-- Cambio 5.1: Crear tabla de reservas
-- Archivo: crear_tabla_reservas.sql
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

-- Cambio 5.2: Índices para reservas
CREATE INDEX IF NOT EXISTS idx_reservas_propiedad ON reservas(propiedad_id);
CREATE INDEX IF NOT EXISTS idx_reservas_viajero ON reservas(viajero_id);
CREATE INDEX IF NOT EXISTS idx_reservas_estado ON reservas(estado);
CREATE INDEX IF NOT EXISTS idx_reservas_fechas ON reservas(fecha_inicio, fecha_fin);

-- Cambio 5.3: Trigger para updated_at en reservas
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

-- ============================================
-- FASE 6: CÓDIGOS DE VERIFICACIÓN
-- ============================================

-- Cambio 6.1: Agregar campo codigo_verificacion a reservas
-- Archivo: agregar_codigo_verificacion_reservas.sql (ELIMINADO - consolidado en SISTEMA_CHAT_FINAL.sql)
-- Fecha: 2025-12-04
-- Nota: Este archivo fue consolidado en la versión final del sistema de chat
ALTER TABLE reservas ADD COLUMN IF NOT EXISTS codigo_verificacion TEXT;

-- Cambio 6.2: Función para generar código de 6 dígitos
CREATE OR REPLACE FUNCTION generar_codigo_verificacion()
RETURNS TEXT AS $$
BEGIN
    RETURN LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Cambio 6.3: Función para asignar código al confirmar
CREATE OR REPLACE FUNCTION asignar_codigo_verificacion()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estado = 'confirmada' AND (OLD.codigo_verificacion IS NULL OR OLD.codigo_verificacion = '') THEN
        NEW.codigo_verificacion = generar_codigo_verificacion();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Cambio 6.4: Trigger para generar código automáticamente
DROP TRIGGER IF EXISTS trigger_asignar_codigo_verificacion ON reservas;
CREATE TRIGGER trigger_asignar_codigo_verificacion
    BEFORE UPDATE ON reservas
    FOR EACH ROW
    EXECUTE FUNCTION asignar_codigo_verificacion();

-- ============================================
-- FASE 7: SISTEMA DE MENSAJES/CHAT
-- ============================================

-- Cambio 7.0: Primera versión de tabla mensajes (INCORRECTA)
-- Archivo: crear_tabla_mensajes.sql (ELIMINADO - estructura incorrecta)
-- Fecha: 2025-12-04
-- Problema: Tenía campos 'contenido' y 'destinatario_id' que no coincidían con el modelo Flutter
-- Solución: Se recreó la tabla con estructura correcta

-- Cambio 7.1: Crear tabla de mensajes (VERSIÓN FINAL)
-- Archivo: arreglar_tabla_mensajes.sql (ELIMINADO - consolidado en SISTEMA_CHAT_FINAL.sql)
-- Fecha: 2025-12-04
-- Nota: Primera versión tenía estructura incorrecta, fue recreada

DROP TABLE IF EXISTS mensajes CASCADE;

CREATE TABLE mensajes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reserva_id UUID NOT NULL REFERENCES reservas(id) ON DELETE CASCADE,
    remitente_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
    mensaje TEXT NOT NULL,
    leido BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cambio 7.2: Índices para mensajes
CREATE INDEX IF NOT EXISTS idx_mensajes_reserva ON mensajes(reserva_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_remitente ON mensajes(remitente_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_created_at ON mensajes(created_at);

-- Cambio 7.3: Habilitar RLS en mensajes
ALTER TABLE mensajes ENABLE ROW LEVEL SECURITY;

-- ============================================
-- FASE 8: POLÍTICAS RLS PARA MENSAJES
-- ============================================

-- Cambio 8.1: Eliminar políticas existentes
DROP POLICY IF EXISTS "Participantes pueden ver mensajes de su reserva" ON mensajes;
DROP POLICY IF EXISTS "Participantes pueden enviar mensajes" ON mensajes;
DROP POLICY IF EXISTS "Usuarios pueden actualizar estado de lectura" ON mensajes;
DROP POLICY IF EXISTS "Admins tienen acceso completo a mensajes" ON mensajes;

-- Cambio 8.2: Política para ver mensajes
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

-- Cambio 8.3: Política para enviar mensajes
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

-- Cambio 8.4: Política para actualizar estado de lectura
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

-- Cambio 8.5: Política para admins
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
-- FASE 9: REALTIME PARA MENSAJES
-- ============================================

-- Cambio 9.1: Habilitar Realtime en tabla mensajes
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE mensajes;
EXCEPTION
    WHEN duplicate_object THEN
        NULL;
END $$;

-- ============================================
-- FASE 10: POLÍTICAS RLS PARA OTRAS TABLAS
-- ============================================

-- Cambio 10.1: Políticas para propiedades
ALTER TABLE propiedades ENABLE ROW LEVEL SECURITY;

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

-- Cambio 10.2: Políticas para reservas
ALTER TABLE reservas ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Viajeros pueden ver sus reservas"
    ON reservas FOR SELECT
    USING (auth.uid() = viajero_id);

CREATE POLICY "Anfitriones pueden ver reservas de sus propiedades"
    ON reservas FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM propiedades
            WHERE propiedades.id = reservas.propiedad_id
            AND propiedades.anfitrion_id = auth.uid()
        )
    );

CREATE POLICY "Viajeros pueden crear reservas"
    ON reservas FOR INSERT
    WITH CHECK (auth.uid() = viajero_id);

CREATE POLICY "Anfitriones pueden actualizar estado de reservas"
    ON reservas FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM propiedades
            WHERE propiedades.id = reservas.propiedad_id
            AND propiedades.anfitrion_id = auth.uid()
        )
    );

CREATE POLICY "Viajeros pueden cancelar sus reservas"
    ON reservas FOR UPDATE
    USING (auth.uid() = viajero_id)
    WITH CHECK (estado = 'cancelada');

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
-- FASE 11: CONFIGURACIÓN DE STORAGE
-- ============================================

-- Cambio 11.1: Habilitar RLS en storage
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- Cambio 11.2: Eliminar políticas existentes de storage
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
    END LOOP;
END $$;

-- Cambio 11.3: Políticas permisivas para storage (desarrollo)
-- Archivo: storage_policies_final.sql

CREATE POLICY "profile_photos_all"
ON storage.objects FOR ALL
TO public
USING (bucket_id = 'profile-photos')
WITH CHECK (bucket_id = 'profile-photos');

CREATE POLICY "id_documents_all"
ON storage.objects FOR ALL
TO public
USING (bucket_id = 'id-documents')
WITH CHECK (bucket_id = 'id-documents');

CREATE POLICY "solicitudes_anfitrion_all"
ON storage.objects FOR ALL
TO public
USING (bucket_id = 'solicitudes-anfitrion')
WITH CHECK (bucket_id = 'solicitudes-anfitrion');

CREATE POLICY "propiedades_fotos_all"
ON storage.objects FOR ALL
TO public
USING (bucket_id = 'propiedades-fotos')
WITH CHECK (bucket_id = 'propiedades-fotos');

-- Cambio 11.4: Política para buckets
CREATE POLICY "Permitir acceso a todos los buckets"
ON storage.buckets FOR SELECT
TO public
USING (true);

-- ============================================
-- FASE 12: TRIGGER PARA CREAR PERFIL AUTOMÁTICO
-- ============================================

-- Cambio 12.1: Función para crear perfil al registrarse
-- Archivo: supabase_trigger_perfil_usuario.sql
CREATE OR REPLACE FUNCTION crear_perfil_usuario_automatico()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users_profiles (id, email, nombre, email_verified)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'nombre', 'Usuario'),
    NEW.email_confirmed_at IS NOT NULL
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cambio 12.2: Trigger para crear perfil automáticamente
DROP TRIGGER IF EXISTS trigger_crear_perfil_usuario ON auth.users;
CREATE TRIGGER trigger_crear_perfil_usuario
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION crear_perfil_usuario_automatico();

-- ============================================
-- FASE 13: TABLA DE RESEÑAS
-- ============================================

-- Cambio 13.1: Crear tabla de reseñas
CREATE TABLE IF NOT EXISTS resenas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  propiedad_id UUID NOT NULL REFERENCES propiedades(id) ON DELETE CASCADE,
  viajero_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
  reserva_id UUID REFERENCES reservas(id) ON DELETE SET NULL,
  calificacion INTEGER CHECK (calificacion >= 1 AND calificacion <= 5),
  comentario TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cambio 13.2: Índices para reseñas
CREATE INDEX IF NOT EXISTS idx_resenas_propiedad ON resenas(propiedad_id);
CREATE INDEX IF NOT EXISTS idx_resenas_viajero ON resenas(viajero_id);

-- ============================================
-- CAMBIOS ADMINISTRATIVOS
-- ============================================

-- Cambio Admin.1: Convertir usuario en admin
-- Archivo: crear_cuenta_admin.sql
-- Uso: Ejecutar después de registrar usuario

UPDATE users_profiles
SET rol_id = 3
WHERE email = 'alof2003@gmail.com';

-- Cambio Admin.2: Deshabilitar RLS para desarrollo
-- Archivo: deshabilitar_rls_todas_tablas.sql
-- Nota: Solo para desarrollo, NO usar en producción

ALTER TABLE users_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE solicitudes_anfitrion DISABLE ROW LEVEL SECURITY;
ALTER TABLE propiedades DISABLE ROW LEVEL SECURITY;
ALTER TABLE fotos_propiedades DISABLE ROW LEVEL SECURITY;
ALTER TABLE reservas DISABLE ROW LEVEL SECURITY;
ALTER TABLE mensajes DISABLE ROW LEVEL SECURITY;
ALTER TABLE resenas DISABLE ROW LEVEL SECURITY;

-- Cambio Admin.3: Borrar todos los usuarios (desarrollo)
-- Archivo: borrar_todos_usuarios.sql
-- ⚠️ PELIGROSO: Solo usar en desarrollo

DELETE FROM users_profiles;

DO $$
DECLARE
  usuario RECORD;
BEGIN
  FOR usuario IN SELECT id FROM auth.users LOOP
    PERFORM auth.delete_user_by_id(usuario.id);
  END LOOP;
END $$;

-- ============================================
-- ARCHIVOS SQL ELIMINADOS (CONSOLIDADOS)
-- ============================================

-- Los siguientes archivos fueron eliminados el 2025-12-04
-- porque su contenido fue consolidado en SISTEMA_CHAT_FINAL.sql

-- 1. agregar_codigo_verificacion_reservas.sql
--    Contenido: Agregaba campo codigo_verificacion y triggers
--    Razón: Consolidado en versión final del chat

-- 2. crear_tabla_mensajes.sql
--    Contenido: Primera versión de tabla mensajes (estructura incorrecta)
--    Razón: Estructura incorrecta, reemplazada por versión corregida

-- 3. arreglar_tabla_mensajes.sql
--    Contenido: Versión corregida de tabla mensajes con políticas RLS
--    Razón: Consolidado en versión final del chat

-- 4. actualizar_chat_completo.sql
--    Contenido: Versión intermedia del sistema de chat
--    Razón: Reemplazado por SISTEMA_CHAT_FINAL.sql

-- ============================================
-- RESUMEN DE CAMBIOS
-- ============================================

-- Total de tablas creadas: 8
-- 1. roles
-- 2. users_profiles
-- 3. propiedades
-- 4. fotos_propiedades
-- 5. solicitudes_anfitrion
-- 6. reservas
-- 7. mensajes
-- 8. resenas

-- Total de funciones creadas: 5
-- 1. update_updated_at_column()
-- 2. update_reservas_updated_at()
-- 3. generar_codigo_verificacion()
-- 4. asignar_codigo_verificacion()
-- 5. crear_perfil_usuario_automatico()

-- Total de triggers creados: 6
-- 1. update_users_profiles_updated_at
-- 2. trigger_actualizar_propiedades_updated_at
-- 3. trigger_update_reservas_updated_at
-- 4. trigger_asignar_codigo_verificacion
-- 5. trigger_codigo_verificacion (alternativo)
-- 6. trigger_crear_perfil_usuario

-- Total de políticas RLS: ~25 políticas
-- Distribuidas en todas las tablas principales

-- Buckets de Storage: 4
-- 1. profile-photos
-- 2. id-documents
-- 3. solicitudes-anfitrion
-- 4. propiedades-fotos

-- ============================================
-- FIN DEL HISTORIAL DE CAMBIOS SQL
-- ============================================

SELECT '✅ HISTORIAL COMPLETO DE CAMBIOS SQL DOCUMENTADO' as resultado;
