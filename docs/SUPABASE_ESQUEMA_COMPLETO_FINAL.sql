-- =====================================================
-- DONDECAIGA - ESQUEMA COMPLETO DE BASE DE DATOS
-- Supabase PostgreSQL Schema
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

-- Tabla de perfiles de usuario
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

-- Tabla de propiedades
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

-- Tabla de reservas
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
    CONSTRAINT reservas_estado_check CHECK (estado = ANY (ARRAY['pendiente'::text, 'confirmada'::text, 'rechazada'::text, 'completada'::text, 'cancelada'::text]))
);

-- Tabla de reseñas
CREATE TABLE IF NOT EXISTS public.resenas (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    propiedad_id uuid NOT NULL,
    viajero_id uuid NOT NULL,
    reserva_id uuid,
    calificacion integer CHECK (calificacion >= 1 AND calificacion <= 5),
    comentario text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT resenas_pkey PRIMARY KEY (id),
    CONSTRAINT resenas_propiedad_id_fkey FOREIGN KEY (propiedad_id) REFERENCES public.propiedades(id) ON DELETE CASCADE,
    CONSTRAINT resenas_viajero_id_fkey FOREIGN KEY (viajero_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    CONSTRAINT resenas_reserva_id_fkey FOREIGN KEY (reserva_id) REFERENCES public.reservas(id) ON DELETE SET NULL
);

-- Tabla de mensajes
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

-- Tabla de solicitudes de anfitrión
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

-- Tabla de auditoría administrativa
CREATE TABLE IF NOT EXISTS public.admin_audit_log (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    admin_id uuid NOT NULL,
    target_user_id uuid NOT NULL,
    action_type character varying NOT NULL,
    action_data jsonb,
    reason text,
    was_successful boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT admin_audit_log_pkey PRIMARY KEY (id),
    CONSTRAINT admin_audit_log_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    CONSTRAINT admin_audit_log_target_user_id_fkey FOREIGN KEY (target_user_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    CONSTRAINT admin_audit_log_action_type_check CHECK (action_type::text = ANY (ARRAY['degrade_role'::character varying, 'block_account'::character varying, 'unblock_account'::character varying]::text[]))
);

-- Tabla de notificaciones (preparada para futuro uso)
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
    CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE
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

-- Tabla de tokens de dispositivos (para notificaciones push)
CREATE TABLE IF NOT EXISTS public.device_tokens (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    token text NOT NULL,
    platform character varying NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT device_tokens_pkey PRIMARY KEY (id),
    CONSTRAINT device_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    CONSTRAINT device_tokens_platform_check CHECK (platform::text = ANY (ARRAY['ios'::character varying, 'android'::character varying, 'web'::character varying]::text[]))
);

-- =====================================================
-- 3. ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

-- Índices para users_profiles
CREATE INDEX IF NOT EXISTS idx_users_profiles_email ON public.users_profiles(email);
CREATE INDEX IF NOT EXISTS idx_users_profiles_rol_id ON public.users_profiles(rol_id);
CREATE INDEX IF NOT EXISTS idx_users_profiles_estado_cuenta ON public.users_profiles(estado_cuenta);

-- Índices para propiedades
CREATE INDEX IF NOT EXISTS idx_propiedades_anfitrion_id ON public.propiedades(anfitrion_id);
CREATE INDEX IF NOT EXISTS idx_propiedades_estado ON public.propiedades(estado);
CREATE INDEX IF NOT EXISTS idx_propiedades_ciudad ON public.propiedades(ciudad);
CREATE INDEX IF NOT EXISTS idx_propiedades_created_at ON public.propiedades(created_at);

-- Índices para reservas
CREATE INDEX IF NOT EXISTS idx_reservas_propiedad_id ON public.reservas(propiedad_id);
CREATE INDEX IF NOT EXISTS idx_reservas_viajero_id ON public.reservas(viajero_id);
CREATE INDEX IF NOT EXISTS idx_reservas_estado ON public.reservas(estado);
CREATE INDEX IF NOT EXISTS idx_reservas_fecha_inicio ON public.reservas(fecha_inicio);
CREATE INDEX IF NOT EXISTS idx_reservas_fecha_fin ON public.reservas(fecha_fin);

-- Índices para reseñas
CREATE INDEX IF NOT EXISTS idx_resenas_propiedad_id ON public.resenas(propiedad_id);
CREATE INDEX IF NOT EXISTS idx_resenas_viajero_id ON public.resenas(viajero_id);
CREATE INDEX IF NOT EXISTS idx_resenas_created_at ON public.resenas(created_at);

-- Índices para mensajes
CREATE INDEX IF NOT EXISTS idx_mensajes_reserva_id ON public.mensajes(reserva_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_remitente_id ON public.mensajes(remitente_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_created_at ON public.mensajes(created_at);

-- Índices para notificaciones
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at);

-- =====================================================
-- 4. FUNCIONES Y TRIGGERS
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
CREATE TRIGGER update_users_profiles_updated_at BEFORE UPDATE ON public.users_profiles FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_propiedades_updated_at BEFORE UPDATE ON public.propiedades FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_reservas_updated_at BEFORE UPDATE ON public.reservas FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_notification_settings_updated_at BEFORE UPDATE ON public.notification_settings FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_device_tokens_updated_at BEFORE UPDATE ON public.device_tokens FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

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
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para crear perfil automáticamente
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Función para obtener propiedades con calificaciones
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
        COALESCE(ROUND(AVG(r_anf.calificacion), 1), 0) as calificacion_anfitrion
    FROM propiedades p
    LEFT JOIN users_profiles up ON p.anfitrion_id = up.id
    LEFT JOIN resenas r ON p.id = r.propiedad_id
    LEFT JOIN resenas r_anf ON p.anfitrion_id = (
        SELECT pr.anfitrion_id 
        FROM propiedades pr 
        WHERE pr.id = r_anf.propiedad_id
    )
    WHERE p.estado = 'activo'
    GROUP BY p.id, up.nombre, up.foto_perfil_url
    ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. POLÍTICAS DE SEGURIDAD (RLS)
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
ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

-- Políticas para users_profiles
CREATE POLICY "Users can view their own profile" ON public.users_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.users_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can view other profiles" ON public.users_profiles FOR SELECT USING (true);
CREATE POLICY "Admins can manage all profiles" ON public.users_profiles FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.users_profiles 
        WHERE id = auth.uid() AND rol_id = 3
    )
);

-- Políticas para propiedades
CREATE POLICY "Anyone can view active properties" ON public.propiedades FOR SELECT USING (estado = 'activo');
CREATE POLICY "Anfitriones can manage their properties" ON public.propiedades FOR ALL USING (anfitrion_id = auth.uid());
CREATE POLICY "Admins can manage all properties" ON public.propiedades FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.users_profiles 
        WHERE id = auth.uid() AND rol_id = 3
    )
);

-- Políticas para reservas
CREATE POLICY "Users can view their own reservations" ON public.reservas FOR SELECT USING (
    viajero_id = auth.uid() OR 
    EXISTS (
        SELECT 1 FROM public.propiedades 
        WHERE id = propiedad_id AND anfitrion_id = auth.uid()
    )
);
CREATE POLICY "Viajeros can create reservations" ON public.reservas FOR INSERT WITH CHECK (viajero_id = auth.uid());
CREATE POLICY "Anfitriones can update reservations" ON public.reservas FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM public.propiedades 
        WHERE id = propiedad_id AND anfitrion_id = auth.uid()
    )
);

-- Políticas para reseñas
CREATE POLICY "Anyone can view reviews" ON public.resenas FOR SELECT USING (true);
CREATE POLICY "Viajeros can create reviews" ON public.resenas FOR INSERT WITH CHECK (viajero_id = auth.uid());
CREATE POLICY "Users can update their own reviews" ON public.resenas FOR UPDATE USING (viajero_id = auth.uid());

-- Políticas para mensajes
CREATE POLICY "Users can view messages from their reservations" ON public.mensajes FOR SELECT USING (
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
CREATE POLICY "Users can send messages" ON public.mensajes FOR INSERT WITH CHECK (remitente_id = auth.uid());

-- Políticas para solicitudes de anfitrión
CREATE POLICY "Users can view their own applications" ON public.solicitudes_anfitrion FOR SELECT USING (usuario_id = auth.uid());
CREATE POLICY "Users can create applications" ON public.solicitudes_anfitrion FOR INSERT WITH CHECK (usuario_id = auth.uid());
CREATE POLICY "Admins can manage all applications" ON public.solicitudes_anfitrion FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.users_profiles 
        WHERE id = auth.uid() AND rol_id = 3
    )
);

-- Políticas para admin_audit_log
CREATE POLICY "Admins can view audit log" ON public.admin_audit_log FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM public.users_profiles 
        WHERE id = auth.uid() AND rol_id = 3
    )
);
CREATE POLICY "Admins can create audit entries" ON public.admin_audit_log FOR INSERT WITH CHECK (admin_id = auth.uid());

-- Políticas para notificaciones
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "System can create notifications" ON public.notifications FOR INSERT WITH CHECK (true);

-- Políticas para configuraciones de notificaciones
CREATE POLICY "Users can manage their notification settings" ON public.notification_settings FOR ALL USING (user_id = auth.uid());

-- Políticas para tokens de dispositivos
CREATE POLICY "Users can manage their device tokens" ON public.device_tokens FOR ALL USING (user_id = auth.uid());

-- =====================================================
-- 6. CONFIGURACIÓN DE STORAGE
-- =====================================================

-- Crear buckets de storage
INSERT INTO storage.buckets (id, name, public) VALUES 
('profile-photos', 'profile-photos', true),
('property-photos', 'property-photos', true),
('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;

-- Políticas de storage para fotos de perfil
CREATE POLICY "Users can upload their profile photos" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'profile-photos' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Users can view profile photos" ON storage.objects FOR SELECT USING (bucket_id = 'profile-photos');
CREATE POLICY "Users can update their profile photos" ON storage.objects FOR UPDATE USING (
    bucket_id = 'profile-photos' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Users can delete their profile photos" ON storage.objects FOR DELETE USING (
    bucket_id = 'profile-photos' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Políticas de storage para fotos de propiedades
CREATE POLICY "Anfitriones can upload property photos" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'property-photos' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Anyone can view property photos" ON storage.objects FOR SELECT USING (bucket_id = 'property-photos');
CREATE POLICY "Anfitriones can update their property photos" ON storage.objects FOR UPDATE USING (
    bucket_id = 'property-photos' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Anfitriones can delete their property photos" ON storage.objects FOR DELETE USING (
    bucket_id = 'property-photos' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);

-- Políticas de storage para documentos
CREATE POLICY "Users can upload their documents" ON storage.objects FOR INSERT WITH CHECK (
    bucket_id = 'documents' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Users can view their documents" ON storage.objects FOR SELECT USING (
    bucket_id = 'documents' AND 
    auth.uid()::text = (storage.foldername(name))[1]
);
CREATE POLICY "Admins can view all documents" ON storage.objects FOR SELECT USING (
    bucket_id = 'documents' AND
    EXISTS (
        SELECT 1 FROM public.users_profiles 
        WHERE id = auth.uid() AND rol_id = 3
    )
);

-- =====================================================
-- 7. DATOS INICIALES
-- =====================================================

-- Crear usuario administrador por defecto (opcional)
-- NOTA: Esto debe ejecutarse después de que el usuario se registre en Auth
-- INSERT INTO public.users_profiles (id, email, nombre, rol_id) 
-- VALUES ('uuid-del-admin', 'admin@dondecaiga.com', 'Administrador', 3)
-- ON CONFLICT (id) DO UPDATE SET rol_id = 3;

-- =====================================================
-- 8. COMENTARIOS Y DOCUMENTACIÓN
-- =====================================================

COMMENT ON TABLE public.users_profiles IS 'Perfiles de usuario con información personal y roles';
COMMENT ON TABLE public.propiedades IS 'Propiedades disponibles para alquiler';
COMMENT ON TABLE public.reservas IS 'Reservas realizadas por viajeros';
COMMENT ON TABLE public.resenas IS 'Reseñas de viajeros sobre propiedades';
COMMENT ON TABLE public.mensajes IS 'Sistema de mensajería entre usuarios';
COMMENT ON TABLE public.solicitudes_anfitrion IS 'Solicitudes para convertirse en anfitrión';
COMMENT ON TABLE public.admin_audit_log IS 'Registro de acciones administrativas';
COMMENT ON TABLE public.notifications IS 'Sistema de notificaciones (preparado para futuro)';

-- =====================================================
-- FIN DEL ESQUEMA
-- =====================================================

-- Verificar que todo se creó correctamente
SELECT 'Esquema DondeCaiga creado exitosamente' as status;