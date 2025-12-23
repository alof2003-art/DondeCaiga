-- =====================================================
-- DONDECAIGA - ESQUEMA COMPLETO DE BASE DE DATOS
-- Supabase PostgreSQL Schema - VERSIÓN FINAL 2024
-- Incluye todas las mejoras y optimizaciones implementadas
-- Última actualización: Diciembre 2024
-- =====================================================

-- =====================================================
-- 1. EXTENSIONES Y CONFIGURACIONES INICIALES
-- =====================================================

-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 2. TABLAS PRINCIPALES
-- =====================================================

-- Tabla de roles
CREATE TABLE IF NOT EXISTS public.roles (
    id integer NOT NULL DEFAULT nextval('roles_id_seq'::regclass),
    nombre character varying NOT NULL UNIQUE,
    descripcion text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT roles_pkey PRIMARY KEY (id)
);

-- Insertar roles por defecto
INSERT INTO public.roles (id, nombre, descripcion) VALUES 
(1, 'viajero', 'Usuario que busca alojamiento'),
(2, 'anfitrion', 'Usuario que ofrece propiedades'),
(3, 'admin', 'Administrador del sistema')
ON CONFLICT (nombre) DO NOTHING;

-- Tabla de perfiles de usuario (MEJORADA)
CREATE TABLE IF NOT EXISTS public.users_profiles (
    id uuid NOT NULL,
    email text NOT NULL UNIQUE,
    nombre text NOT NULL,
    telefono text,
    foto_perfil_url text,
    cedula_url text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    email_verified boolean DEFAULT false,
    rol_id integer DEFAULT 1,
    estado_cuenta character varying DEFAULT 'activo'::character varying,
    CONSTRAINT users_profiles_pkey PRIMARY KEY (id),
    CONSTRAINT users_profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT users_profiles_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.roles(id),
    CONSTRAINT users_profiles_estado_cuenta_check CHECK (estado_cuenta::text = ANY (ARRAY['activo'::character varying, 'bloqueado'::character varying, 'suspendido'::character varying]::text[]))
);

-- Tabla de razones de bloqueo
CREATE TABLE IF NOT EXISTS public.block_reasons (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    nombre character varying NOT NULL UNIQUE,
    descripcion text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT block_reasons_pkey PRIMARY KEY (id)
);

-- Insertar razones de bloqueo por defecto
INSERT INTO public.block_reasons (nombre, descripcion) VALUES 
('comportamiento_inapropiado', 'Comportamiento inapropiado hacia otros usuarios'),
('incumplimiento_normas', 'Incumplimiento de las normas de la plataforma'),
('actividad_sospechosa', 'Actividad sospechosa o fraudulenta'),
('spam', 'Envío de spam o contenido no deseado'),
('otros', 'Otras razones especificadas por el administrador')
ON CONFLICT (nombre) DO NOTHING;

-- Tabla de propiedades (OPTIMIZADA)
CREATE TABLE IF NOT EXISTS public.propiedades (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    anfitrion_id uuid NOT NULL,
    titulo character varying NOT NULL,
    descripcion text,
    direccion text NOT NULL,
    ciudad character varying,
    pais character varying,
    latitud numeric,
    longitud numeric,
    capacidad_personas integer NOT NULL,
    numero_habitaciones integer,
    numero_banos integer,
    foto_principal_url text,
    estado character varying DEFAULT 'activo'::character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    tiene_garaje boolean DEFAULT false,
    CONSTRAINT propiedades_pkey PRIMARY KEY (id),
    CONSTRAINT propiedades_anfitrion_id_fkey FOREIGN KEY (anfitrion_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    CONSTRAINT propiedades_estado_check CHECK (estado::text = ANY (ARRAY['activo'::character varying, 'inactivo'::character varying, 'pendiente'::character varying]::text[]))
);

-- Tabla de fotos de propiedades
CREATE TABLE IF NOT EXISTS public.fotos_propiedades (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    propiedad_id uuid NOT NULL,
    url_foto text NOT NULL,
    es_principal boolean DEFAULT false,
    orden integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT fotos_propiedades_pkey PRIMARY KEY (id),
    CONSTRAINT fotos_propiedades_propiedad_id_fkey FOREIGN KEY (propiedad_id) REFERENCES public.propiedades(id) ON DELETE CASCADE
);

-- Tabla de reservas (CON CÓDIGOS DE VERIFICACIÓN)
CREATE TABLE IF NOT EXISTS public.reservas (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    propiedad_id uuid NOT NULL,
    viajero_id uuid NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin date NOT NULL,
    estado text NOT NULL DEFAULT 'pendiente'::text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    codigo_verificacion text,
    CONSTRAINT reservas_pkey PRIMARY KEY (id),
    CONSTRAINT reservas_propiedad_id_fkey FOREIGN KEY (propiedad_id) REFERENCES public.propiedades(id) ON DELETE CASCADE,
    CONSTRAINT reservas_viajero_id_fkey FOREIGN KEY (viajero_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    CONSTRAINT reservas_estado_check CHECK (estado = ANY (ARRAY['pendiente'::text, 'confirmada'::text, 'rechazada'::text, 'completada'::text, 'cancelada'::text])),
    CONSTRAINT reservas_fechas_check CHECK (fecha_fin > fecha_inicio)
);

-- Tabla de reseñas (MEJORADA)
CREATE TABLE IF NOT EXISTS public.resenas (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    propiedad_id uuid NOT NULL,
    viajero_id uuid NOT NULL,
    reserva_id uuid,
    calificacion integer NOT NULL CHECK (calificacion >= 1 AND calificacion <= 5),
    comentario text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT resenas_pkey PRIMARY KEY (id),
    CONSTRAINT resenas_propiedad_id_fkey FOREIGN KEY (propiedad_id) REFERENCES public.propiedades(id) ON DELETE CASCADE,
    CONSTRAINT resenas_viajero_id_fkey FOREIGN KEY (viajero_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    CONSTRAINT resenas_reserva_id_fkey FOREIGN KEY (reserva_id) REFERENCES public.reservas(id) ON DELETE SET NULL,
    CONSTRAINT resenas_unique_per_reservation UNIQUE (reserva_id, viajero_id)
);

-- Tabla de mensajes (CHAT EN TIEMPO REAL)
CREATE TABLE IF NOT EXISTS public.mensajes (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    reserva_id uuid NOT NULL,
    remitente_id uuid NOT NULL,
    mensaje text NOT NULL,
    leido boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT mensajes_pkey PRIMARY KEY (id),
    CONSTRAINT mensajes_reserva_id_fkey FOREIGN KEY (reserva_id) REFERENCES public.reservas(id) ON DELETE CASCADE,
    CONSTRAINT mensajes_remitente_id_fkey FOREIGN KEY (remitente_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE
);

-- Tabla de solicitudes de anfitrión (COMPLETA)
CREATE TABLE IF NOT EXISTS public.solicitudes_anfitrion (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    usuario_id uuid NOT NULL,
    foto_selfie_url text NOT NULL,
    foto_propiedad_url text NOT NULL,
    mensaje text,
    estado character varying DEFAULT 'pendiente'::character varying,
    fecha_solicitud timestamp with time zone DEFAULT now(),
    fecha_respuesta timestamp with time zone,
    admin_revisor_id uuid,
    comentario_admin text,
    CONSTRAINT solicitudes_anfitrion_pkey PRIMARY KEY (id),
    CONSTRAINT solicitudes_anfitrion_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    CONSTRAINT solicitudes_anfitrion_admin_revisor_id_fkey FOREIGN KEY (admin_revisor_id) REFERENCES public.users_profiles(id) ON DELETE SET NULL,
    CONSTRAINT solicitudes_anfitrion_estado_check CHECK (estado::text = ANY (ARRAY['pendiente'::character varying, 'aprobada'::character varying, 'rechazada'::character varying]::text[]))
);

-- Tabla de auditoría administrativa (COMPLETA)
CREATE TABLE IF NOT EXISTS public.admin_audit_log (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    admin_id uuid NOT NULL,
    target_user_id uuid NOT NULL,
    action_type character varying NOT NULL,
    action_data jsonb,
    reason text,
    block_reason_id uuid,
    was_successful boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT admin_audit_log_pkey PRIMARY KEY (id),
    CONSTRAINT admin_audit_log_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    CONSTRAINT admin_audit_log_target_user_id_fkey FOREIGN KEY (target_user_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    CONSTRAINT admin_audit_log_block_reason_id_fkey FOREIGN KEY (block_reason_id) REFERENCES public.block_reasons(id) ON DELETE SET NULL,
    CONSTRAINT admin_audit_log_action_type_check CHECK (action_type::text = ANY (ARRAY['degrade_role'::character varying, 'block_account'::character varying, 'unblock_account'::character varying, 'approve_host'::character varying, 'reject_host'::character varying]::text[]))
);

-- Tabla de notificaciones (PREPARADA PARA FUTURO)
CREATE TABLE IF NOT EXISTS public.notifications (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    type character varying NOT NULL,
    title character varying NOT NULL,
    message text NOT NULL,
    metadata jsonb,
    is_read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    read_at timestamp with time zone,
    CONSTRAINT notifications_pkey PRIMARY KEY (id),
    CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    CONSTRAINT notifications_type_check CHECK (type::text = ANY (ARRAY['reservation'::character varying, 'message'::character varying, 'review'::character varying, 'admin'::character varying, 'system'::character varying]::text[]))
);

-- Tabla de configuraciones de notificaciones
CREATE TABLE IF NOT EXISTS public.notification_settings (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL UNIQUE,
    reservations_enabled boolean DEFAULT true,
    messages_enabled boolean DEFAULT true,
    reviews_enabled boolean DEFAULT true,
    reminders_enabled boolean DEFAULT true,
    admin_notifications_enabled boolean DEFAULT true,
    push_notifications_enabled boolean DEFAULT true,
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT notification_settings_pkey PRIMARY KEY (id),
    CONSTRAINT notification_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE
);

-- =====================================================
-- 3. ÍNDICES PARA OPTIMIZACIÓN DE PERFORMANCE
-- =====================================================

-- Índices para users_profiles
CREATE INDEX IF NOT EXISTS idx_users_profiles_email ON public.users_profiles(email);
CREATE INDEX IF NOT EXISTS idx_users_profiles_rol_id ON public.users_profiles(rol_id);
CREATE INDEX IF NOT EXISTS idx_users_profiles_estado_cuenta ON public.users_profiles(estado_cuenta);
CREATE INDEX IF NOT EXISTS idx_users_profiles_created_at ON public.users_profiles(created_at);

-- Índices para propiedades
CREATE INDEX IF NOT EXISTS idx_propiedades_anfitrion_id ON public.propiedades(anfitrion_id);
CREATE INDEX IF NOT EXISTS idx_propiedades_estado ON public.propiedades(estado);
CREATE INDEX IF NOT EXISTS idx_propiedades_ciudad ON public.propiedades(ciudad);
CREATE INDEX IF NOT EXISTS idx_propiedades_created_at ON public.propiedades(created_at);
CREATE INDEX IF NOT EXISTS idx_propiedades_location ON public.propiedades(latitud, longitud);

-- Índices para reservas (OPTIMIZADOS PARA FILTROS)
CREATE INDEX IF NOT EXISTS idx_reservas_propiedad_id ON public.reservas(propiedad_id);
CREATE INDEX IF NOT EXISTS idx_reservas_viajero_id ON public.reservas(viajero_id);
CREATE INDEX IF NOT EXISTS idx_reservas_estado ON public.reservas(estado);
CREATE INDEX IF NOT EXISTS idx_reservas_fecha_inicio ON public.reservas(fecha_inicio);
CREATE INDEX IF NOT EXISTS idx_reservas_fecha_fin ON public.reservas(fecha_fin);
CREATE INDEX IF NOT EXISTS idx_reservas_fechas_estado ON public.reservas(fecha_inicio, fecha_fin, estado);
CREATE INDEX IF NOT EXISTS idx_reservas_viajero_estado ON public.reservas(viajero_id, estado);

-- Índices para reseñas
CREATE INDEX IF NOT EXISTS idx_resenas_propiedad_id ON public.resenas(propiedad_id);
CREATE INDEX IF NOT EXISTS idx_resenas_viajero_id ON public.resenas(viajero_id);
CREATE INDEX IF NOT EXISTS idx_resenas_created_at ON public.resenas(created_at);
CREATE INDEX IF NOT EXISTS idx_resenas_calificacion ON public.resenas(calificacion);

-- Índices para mensajes (OPTIMIZADOS PARA CHAT)
CREATE INDEX IF NOT EXISTS idx_mensajes_reserva_id ON public.mensajes(reserva_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_remitente_id ON public.mensajes(remitente_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_created_at ON public.mensajes(created_at);
CREATE INDEX IF NOT EXISTS idx_mensajes_reserva_created ON public.mensajes(reserva_id, created_at);

-- Índices para solicitudes de anfitrión
CREATE INDEX IF NOT EXISTS idx_solicitudes_anfitrion_usuario_id ON public.solicitudes_anfitrion(usuario_id);
CREATE INDEX IF NOT EXISTS idx_solicitudes_anfitrion_estado ON public.solicitudes_anfitrion(estado);
CREATE INDEX IF NOT EXISTS idx_solicitudes_anfitrion_fecha ON public.solicitudes_anfitrion(fecha_solicitud);

-- Índices para auditoría
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_admin_id ON public.admin_audit_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_target_user_id ON public.admin_audit_log(target_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_created_at ON public.admin_audit_log(created_at);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_action_type ON public.admin_audit_log(action_type);

-- Índices para notificaciones
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read) WHERE is_read = false;

-- =====================================================
-- 4. FUNCIONES Y TRIGGERS AVANZADOS
-- =====================================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para updated_at
DROP TRIGGER IF EXISTS update_users_profiles_updated_at ON public.users_profiles;
CREATE TRIGGER update_users_profiles_updated_at BEFORE UPDATE ON public.users_profiles FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_propiedades_updated_at ON public.propiedades;
CREATE TRIGGER update_propiedades_updated_at BEFORE UPDATE ON public.propiedades FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_reservas_updated_at ON public.reservas;
CREATE TRIGGER update_reservas_updated_at BEFORE UPDATE ON public.reservas FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_resenas_updated_at ON public.resenas;
CREATE TRIGGER update_resenas_updated_at BEFORE UPDATE ON public.resenas FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

DROP TRIGGER IF EXISTS update_notification_settings_updated_at ON public.notification_settings;
CREATE TRIGGER update_notification_settings_updated_at BEFORE UPDATE ON public.notification_settings FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Función para generar código de verificación
CREATE OR REPLACE FUNCTION generar_codigo_verificacion()
RETURNS text AS $$
BEGIN
    RETURN LPAD(FLOOR(RANDOM() * 1000000)::text, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Función para asignar código de verificación automáticamente
CREATE OR REPLACE FUNCTION asignar_codigo_verificacion()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo asignar código cuando el estado cambia a 'confirmada'
    IF NEW.estado = 'confirmada' AND (OLD.estado IS NULL OR OLD.estado != 'confirmada') THEN
        NEW.codigo_verificacion = generar_codigo_verificacion();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para asignar código de verificación
DROP TRIGGER IF EXISTS trigger_asignar_codigo_verificacion ON public.reservas;
CREATE TRIGGER trigger_asignar_codigo_verificacion
    BEFORE INSERT OR UPDATE ON public.reservas
    FOR EACH ROW
    EXECUTE FUNCTION asignar_codigo_verificacion();

-- Función para crear perfil automáticamente al registrarse
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users_profiles (id, email, nombre, email_verified)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'nombre', split_part(new.email, '@', 1)),
    new.email_confirmed_at IS NOT NULL
  );
  
  -- Crear configuraciones de notificaciones por defecto
  INSERT INTO public.notification_settings (user_id)
  VALUES (new.id);
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para crear perfil automáticamente
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Función para obtener propiedades con calificaciones (OPTIMIZADA)
CREATE OR REPLACE FUNCTION get_propiedades_con_calificaciones()
RETURNS TABLE (
    id uuid,
    anfitrion_id uuid,
    titulo character varying,
    descripcion text,
    direccion text,
    ciudad character varying,
    pais character varying,
    latitud numeric,
    longitud numeric,
    capacidad_personas integer,
    numero_habitaciones integer,
    numero_banos integer,
    tiene_garaje boolean,
    foto_principal_url text,
    estado character varying,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    nombre_anfitrion text,
    foto_anfitrion text,
    calificacion_promedio numeric,
    numero_resenas bigint,
    calificacion_anfitrion numeric
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.anfitrion_id,
        p.titulo,
        p.descripcion,
        p.direccion,
        p.ciudad,
        p.pais,
        p.latitud,
        p.longitud,
        p.capacidad_personas,
        p.numero_habitaciones,
        p.numero_banos,
        p.tiene_garaje,
        p.foto_principal_url,
        p.estado,
        p.created_at,
        p.updated_at,
        up.nombre as nombre_anfitrion,
        up.foto_perfil_url as foto_anfitrion,
        COALESCE(ROUND(AVG(r.calificacion), 1), 0) as calificacion_promedio,
        COUNT(r.id) as numero_resenas,
        COALESCE(anf_stats.calificacion_promedio, 0) as calificacion_anfitrion
    FROM propiedades p
    LEFT JOIN users_profiles up ON p.anfitrion_id = up.id
    LEFT JOIN resenas r ON p.id = r.propiedad_id
    LEFT JOIN (
        SELECT 
            pr.anfitrion_id,
            ROUND(AVG(re.calificacion), 1) as calificacion_promedio
        FROM propiedades pr
        LEFT JOIN resenas re ON pr.id = re.propiedad_id
        GROUP BY pr.anfitrion_id
    ) anf_stats ON p.anfitrion_id = anf_stats.anfitrion_id
    WHERE p.estado = 'activo'
    GROUP BY p.id, up.nombre, up.foto_perfil_url, anf_stats.calificacion_promedio
    ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener estadísticas de reseñas de un usuario
CREATE OR REPLACE FUNCTION get_user_review_stats(user_uuid uuid)
RETURNS TABLE (
    total_resenas_recibidas bigint,
    calificacion_promedio_recibida numeric,
    total_resenas_hechas bigint,
    calificacion_promedio_hecha numeric,
    distribucion_calificaciones jsonb
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        -- Reseñas recibidas (como anfitrión)
        COUNT(r1.id) as total_resenas_recibidas,
        COALESCE(ROUND(AVG(r1.calificacion), 1), 0) as calificacion_promedio_recibida,
        
        -- Reseñas hechas (como viajero)
        COUNT(r2.id) as total_resenas_hechas,
        COALESCE(ROUND(AVG(r2.calificacion), 1), 0) as calificacion_promedio_hecha,
        
        -- Distribución de calificaciones recibidas
        COALESCE(
            jsonb_object_agg(
                dist.calificacion::text, 
                dist.cantidad
            ) FILTER (WHERE dist.calificacion IS NOT NULL),
            '{}'::jsonb
        ) as distribucion_calificaciones
    FROM (
        SELECT 1 as dummy -- Para permitir LEFT JOINs
    ) base
    LEFT JOIN propiedades p ON p.anfitrion_id = user_uuid
    LEFT JOIN resenas r1 ON p.id = r1.propiedad_id
    LEFT JOIN resenas r2 ON r2.viajero_id = user_uuid
    LEFT JOIN (
        SELECT 
            r.calificacion,
            COUNT(*) as cantidad
        FROM propiedades p
        JOIN resenas r ON p.id = r.propiedad_id
        WHERE p.anfitrion_id = user_uuid
        GROUP BY r.calificacion
    ) dist ON true
    GROUP BY base.dummy;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. POLÍTICAS DE SEGURIDAD (RLS) MEJORADAS
-- =====================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE public.users_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.propiedades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resenas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mensajes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.solicitudes_anfitrion ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.block_reasons ENABLE ROW LEVEL SECURITY;

-- Limpiar políticas existentes
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users_profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users_profiles;
DROP POLICY IF EXISTS "Users can view other profiles" ON public.users_profiles;
DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.users_profiles;

-- Políticas para users_profiles (MEJORADAS)
CREATE POLICY "Users can view their own profile" ON public.users_profiles 
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.users_profiles 
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view other profiles" ON public.users_profiles 
    FOR SELECT USING (true);

CREATE POLICY "Admins can manage all profiles" ON public.users_profiles 
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users_profiles 
            WHERE id = auth.uid() AND rol_id = 3
        )
    );

-- Políticas para propiedades
DROP POLICY IF EXISTS "Anyone can view active properties" ON public.propiedades;
DROP POLICY IF EXISTS "Anfitriones can manage their properties" ON public.propiedades;
DROP POLICY IF EXISTS "Admins can manage all properties" ON public.propiedades;

CREATE POLICY "Anyone can view active properties" ON public.propiedades 
    FOR SELECT USING (estado = 'activo');

CREATE POLICY "Anfitriones can manage their properties" ON public.propiedades 
    FOR ALL USING (anfitrion_id = auth.uid());

CREATE POLICY "Admins can manage all properties" ON public.propiedades 
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users_profiles 
            WHERE id = auth.uid() AND rol_id = 3
        )
    );

-- Políticas para reservas (OPTIMIZADAS PARA FILTROS)
DROP POLICY IF EXISTS "Users can view their own reservations" ON public.reservas;
DROP POLICY IF EXISTS "Viajeros can create reservations" ON public.reservas;
DROP POLICY IF EXISTS "Anfitriones can update reservations" ON public.reservas;

CREATE POLICY "Users can view their own reservations" ON public.reservas 
    FOR SELECT USING (
        viajero_id = auth.uid() OR 
        EXISTS (
            SELECT 1 FROM public.propiedades 
            WHERE id = propiedad_id AND anfitrion_id = auth.uid()
        )
    );

CREATE POLICY "Viajeros can create reservations" ON public.reservas 
    FOR INSERT WITH CHECK (viajero_id = auth.uid());

CREATE POLICY "Anfitriones can update reservations" ON public.reservas 
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.propiedades 
            WHERE id = propiedad_id AND anfitrion_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage all reservations" ON public.reservas 
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users_profiles 
            WHERE id = auth.uid() AND rol_id = 3
        )
    );

-- Políticas para reseñas
DROP POLICY IF EXISTS "Anyone can view reviews" ON public.resenas;
DROP POLICY IF EXISTS "Viajeros can create reviews" ON public.resenas;
DROP POLICY IF EXISTS "Users can update their own reviews" ON public.resenas;

CREATE POLICY "Anyone can view reviews" ON public.resenas 
    FOR SELECT USING (true);

CREATE POLICY "Viajeros can create reviews" ON public.resenas 
    FOR INSERT WITH CHECK (viajero_id = auth.uid());

CREATE POLICY "Users can update their own reviews" ON public.resenas 
    FOR UPDATE USING (viajero_id = auth.uid());

-- Políticas para mensajes (CHAT SEGURO)
DROP POLICY IF EXISTS "Users can view messages from their reservations" ON public.mensajes;
DROP POLICY IF EXISTS "Users can send messages" ON public.mensajes;

CREATE POLICY "Users can view messages from their reservations" ON public.mensajes 
    FOR SELECT USING (
        remitente_id = auth.uid() OR
        EXISTS (
            SELECT 1 FROM public.reservas r
            WHERE r.id = reserva_id AND (
                r.viajero_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM public.propiedades p
                    WHERE p.id = r.propiedad_id AND p.anfitrion_id = auth.uid()
                )
            )
        )
    );

CREATE POLICY "Users can send messages" ON public.mensajes 
    FOR INSERT WITH CHECK (
        remitente_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.reservas r
            WHERE r.id = reserva_id AND r.estado = 'confirmada' AND (
                r.viajero_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM public.propiedades p
                    WHERE p.id = r.propiedad_id AND p.anfitrion_id = auth.uid()
                )
            )
        )
    );

CREATE POLICY "Users can update message read status" ON public.mensajes 
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.reservas r
            WHERE r.id = reserva_id AND (
                r.viajero_id = auth.uid() OR
                EXISTS (
                    SELECT 1 FROM public.propiedades p
                    WHERE p.id = r.propiedad_id AND p.anfitrion_id = auth.uid()
                )
            )
        )
    );

-- Políticas para solicitudes de anfitrión
DROP POLICY IF EXISTS "Users can view their own applications" ON public.solicitudes_anfitrion;
DROP POLICY IF EXISTS "Users can create applications" ON public.solicitudes_anfitrion;
DROP POLICY IF EXISTS "Admins can manage all applications" ON public.solicitudes_anfitrion;

CREATE POLICY "Users can view their own applications" ON public.solicitudes_anfitrion 
    FOR SELECT USING (usuario_id = auth.uid());

CREATE POLICY "Users can create applications" ON public.solicitudes_anfitrion 
    FOR INSERT WITH CHECK (usuario_id = auth.uid());

CREATE POLICY "Admins can manage all applications" ON public.solicitudes_anfitrion 
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users_profiles 
            WHERE id = auth.uid() AND rol_id = 3
        )
    );

-- Políticas para admin_audit_log
DROP POLICY IF EXISTS "Admins can view audit log" ON public.admin_audit_log;
DROP POLICY IF EXISTS "Admins can create audit entries" ON public.admin_audit_log;

CREATE POLICY "Admins can view audit log" ON public.admin_audit_log 
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users_profiles 
            WHERE id = auth.uid() AND rol_id = 3
        )
    );

CREATE POLICY "Admins can create audit entries" ON public.admin_audit_log 
    FOR INSERT WITH CHECK (admin_id = auth.uid());

-- Políticas para block_reasons
CREATE POLICY "Admins can manage block reasons" ON public.block_reasons 
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users_profiles 
            WHERE id = auth.uid() AND rol_id = 3
        )
    );

CREATE POLICY "Users can view active block reasons" ON public.block_reasons 
    FOR SELECT USING (is_active = true);

-- Políticas para notificaciones
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "System can create notifications" ON public.notifications;

CREATE POLICY "Users can view their own notifications" ON public.notifications 
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications" ON public.notifications 
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "System can create notifications" ON public.notifications 
    FOR INSERT WITH CHECK (true);

-- Políticas para configuraciones de notificaciones
DROP POLICY IF EXISTS "Users can manage their notification settings" ON public.notification_settings;

CREATE POLICY "Users can manage their notification settings" ON public.notification_settings 
    FOR ALL USING (user_id = auth.uid());

-- =====================================================
-- 6. CONFIGURACIÓN DE STORAGE OPTIMIZADA
-- =====================================================

-- Crear buckets de storage
INSERT INTO storage.buckets (id, name, public) VALUES 
('profile-photos', 'profile-photos', true),
('property-photos', 'property-photos', true),
('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;

-- Limpiar políticas de storage existentes
DROP POLICY IF EXISTS "Users can upload their profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Anfitriones can upload property photos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view property photos" ON storage.objects;
DROP POLICY IF EXISTS "Anfitriones can update their property photos" ON storage.objects;
DROP POLICY IF EXISTS "Anfitriones can delete their property photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can view their documents" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all documents" ON storage.objects;

-- Políticas de storage para fotos de perfil
CREATE POLICY "Users can upload their profile photos" ON storage.objects 
    FOR INSERT WITH CHECK (
        bucket_id = 'profile-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view profile photos" ON storage.objects 
    FOR SELECT USING (bucket_id = 'profile-photos');

CREATE POLICY "Users can update their profile photos" ON storage.objects 
    FOR UPDATE USING (
        bucket_id = 'profile-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can delete their profile photos" ON storage.objects 
    FOR DELETE USING (
        bucket_id = 'profile-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Políticas de storage para fotos de propiedades
CREATE POLICY "Anfitriones can upload property photos" ON storage.objects 
    FOR INSERT WITH CHECK (
        bucket_id = 'property-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Anyone can view property photos" ON storage.objects 
    FOR SELECT USING (bucket_id = 'property-photos');

CREATE POLICY "Anfitriones can update their property photos" ON storage.objects 
    FOR UPDATE USING (
        bucket_id = 'property-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Anfitriones can delete their property photos" ON storage.objects 
    FOR DELETE USING (
        bucket_id = 'property-photos' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Políticas de storage para documentos
CREATE POLICY "Users can upload their documents" ON storage.objects 
    FOR INSERT WITH CHECK (
        bucket_id = 'documents' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Users can view their documents" ON storage.objects 
    FOR SELECT USING (
        bucket_id = 'documents' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Admins can view all documents" ON storage.objects 
    FOR SELECT USING (
        bucket_id = 'documents' AND
        EXISTS (
            SELECT 1 FROM public.users_profiles 
            WHERE id = auth.uid() AND rol_id = 3
        )
    );

-- =====================================================
-- 7. CONFIGURACIÓN DE REALTIME
-- =====================================================

-- Habilitar Realtime para mensajes (chat en tiempo real)
ALTER PUBLICATION supabase_realtime ADD TABLE public.mensajes;

-- Habilitar Realtime para reservas (actualizaciones de estado)
ALTER PUBLICATION supabase_realtime ADD TABLE public.reservas;

-- Habilitar Realtime para notificaciones
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- =====================================================
-- 8. DATOS INICIALES Y CONFIGURACIÓN
-- =====================================================

-- Crear secuencia para roles si no existe
CREATE SEQUENCE IF NOT EXISTS roles_id_seq;
ALTER TABLE public.roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq');

-- Asegurar que la secuencia esté sincronizada
SELECT setval('roles_id_seq', COALESCE((SELECT MAX(id) FROM public.roles), 0) + 1, false);

-- =====================================================
-- 9. COMENTARIOS Y DOCUMENTACIÓN
-- =====================================================

COMMENT ON TABLE public.users_profiles IS 'Perfiles de usuario con información personal, roles y estado de cuenta';
COMMENT ON TABLE public.propiedades IS 'Propiedades disponibles para alquiler con información completa';
COMMENT ON TABLE public.reservas IS 'Reservas realizadas por viajeros con códigos de verificación automáticos';
COMMENT ON TABLE public.resenas IS 'Reseñas de viajeros sobre propiedades con calificaciones de 1-5 estrellas';
COMMENT ON TABLE public.mensajes IS 'Sistema de mensajería en tiempo real entre usuarios por reserva';
COMMENT ON TABLE public.solicitudes_anfitrion IS 'Solicitudes para convertirse en anfitrión con documentos adjuntos';
COMMENT ON TABLE public.admin_audit_log IS 'Registro completo de acciones administrativas para auditoría';
COMMENT ON TABLE public.notifications IS 'Sistema de notificaciones (preparado para implementación futura)';
COMMENT ON TABLE public.block_reasons IS 'Razones predefinidas para bloqueo de cuentas de usuario';

COMMENT ON FUNCTION get_propiedades_con_calificaciones() IS 'Obtiene propiedades con calificaciones calculadas y información del anfitrión';
COMMENT ON FUNCTION get_user_review_stats(uuid) IS 'Obtiene estadísticas completas de reseñas de un usuario';
COMMENT ON FUNCTION generar_codigo_verificacion() IS 'Genera código de verificación de 6 dígitos para reservas';
COMMENT ON FUNCTION asignar_codigo_verificacion() IS 'Asigna automáticamente código de verificación al confirmar reserva';

-- =====================================================
-- 10. VERIFICACIÓN FINAL
-- =====================================================

-- Verificar que todas las tablas se crearon correctamente
DO $$
DECLARE
    table_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name IN (
        'users_profiles', 'propiedades', 'reservas', 'resenas', 
        'mensajes', 'solicitudes_anfitrion', 'admin_audit_log', 
        'notifications', 'notification_settings', 'block_reasons', 'roles'
    );
    
    IF table_count = 11 THEN
        RAISE NOTICE 'SUCCESS: Todas las 11 tablas principales fueron creadas correctamente';
    ELSE
        RAISE NOTICE 'WARNING: Solo % de 11 tablas fueron creadas', table_count;
    END IF;
END $$;

-- Verificar que los índices se crearon
SELECT 
    schemaname,
    tablename,
    indexname
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename IN ('users_profiles', 'propiedades', 'reservas', 'resenas', 'mensajes')
ORDER BY tablename, indexname;

-- Verificar que las políticas RLS están habilitadas
SELECT 
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users_profiles', 'propiedades', 'reservas', 'resenas', 'mensajes')
ORDER BY tablename;

-- =====================================================
-- FIN DEL ESQUEMA - VERSIÓN FINAL 2024
-- =====================================================

SELECT 
    'DondeCaiga Database Schema v2024 - Implementación Completa' as status,
    'Todas las funcionalidades implementadas y optimizadas' as description,
    now() as created_at;