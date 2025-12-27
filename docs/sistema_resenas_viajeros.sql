-- =====================================================
-- SISTEMA DE RESEÑAS BIDIRECCIONAL - RESEÑAS DE VIAJEROS
-- Permite a los anfitriones reseñar a los viajeros
-- =====================================================

-- Crear tabla de reseñas de viajeros
CREATE TABLE IF NOT EXISTS public.resenas_viajeros (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    viajero_id uuid NOT NULL,
    anfitrion_id uuid NOT NULL,
    reserva_id uuid NOT NULL,
    calificacion integer NOT NULL CHECK (calificacion >= 1 AND calificacion <= 5),
    comentario text,
    aspectos jsonb DEFAULT '{
        "limpieza": null,
        "comunicacion": null,
        "respeto_normas": null,
        "cuidado_propiedad": null,
        "puntualidad": null
    }'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT resenas_viajeros_pkey PRIMARY KEY (id),
    CONSTRAINT resenas_viajeros_viajero_id_fkey FOREIGN KEY (viajero_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    CONSTRAINT resenas_viajeros_anfitrion_id_fkey FOREIGN KEY (anfitrion_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE,
    CONSTRAINT resenas_viajeros_reserva_id_fkey FOREIGN KEY (reserva_id) REFERENCES public.reservas(id) ON DELETE CASCADE,
    CONSTRAINT resenas_viajeros_unique_per_reservation UNIQUE (reserva_id, anfitrion_id)
);

-- Índices para optimización
CREATE INDEX IF NOT EXISTS idx_resenas_viajeros_viajero_id ON public.resenas_viajeros(viajero_id);
CREATE INDEX IF NOT EXISTS idx_resenas_viajeros_anfitrion_id ON public.resenas_viajeros(anfitrion_id);
CREATE INDEX IF NOT EXISTS idx_resenas_viajeros_reserva_id ON public.resenas_viajeros(reserva_id);
CREATE INDEX IF NOT EXISTS idx_resenas_viajeros_created_at ON public.resenas_viajeros(created_at);
CREATE INDEX IF NOT EXISTS idx_resenas_viajeros_calificacion ON public.resenas_viajeros(calificacion);

-- Verificar si la función update_updated_at_column existe, si no, crearla
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_updated_at_column') THEN
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $func$
        BEGIN
            NEW.updated_at = now();
            RETURN NEW;
        END;
        $func$ language 'plpgsql';
    END IF;
END $$;

-- Trigger para updated_at
DROP TRIGGER IF EXISTS update_resenas_viajeros_updated_at ON public.resenas_viajeros;
CREATE TRIGGER update_resenas_viajeros_updated_at 
    BEFORE UPDATE ON public.resenas_viajeros 
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Habilitar RLS
ALTER TABLE public.resenas_viajeros ENABLE ROW LEVEL SECURITY;

-- Limpiar políticas existentes si existen
DROP POLICY IF EXISTS "Anyone can view traveler reviews" ON public.resenas_viajeros;
DROP POLICY IF EXISTS "Anfitriones can create traveler reviews" ON public.resenas_viajeros;
DROP POLICY IF EXISTS "Anfitriones can update their own traveler reviews" ON public.resenas_viajeros;
DROP POLICY IF EXISTS "Admins can manage all traveler reviews" ON public.resenas_viajeros;

-- Políticas de seguridad
CREATE POLICY "Anyone can view traveler reviews" ON public.resenas_viajeros 
    FOR SELECT USING (true);

CREATE POLICY "Anfitriones can create traveler reviews" ON public.resenas_viajeros 
    FOR INSERT WITH CHECK (
        anfitrion_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.reservas r
            JOIN public.propiedades p ON r.propiedad_id = p.id
            WHERE r.id = reserva_id 
            AND p.anfitrion_id = auth.uid()
            AND r.estado = 'completada'
        )
    );

CREATE POLICY "Anfitriones can update their own traveler reviews" ON public.resenas_viajeros 
    FOR UPDATE USING (anfitrion_id = auth.uid());

CREATE POLICY "Admins can manage all traveler reviews" ON public.resenas_viajeros 
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users_profiles 
            WHERE id = auth.uid() AND rol_id = 3
        )
    );

-- Función para obtener estadísticas completas de reseñas de un usuario (actualizada)
CREATE OR REPLACE FUNCTION get_user_complete_review_stats(user_uuid uuid)
RETURNS TABLE (
    -- Reseñas como anfitrión (recibidas en sus propiedades)
    total_resenas_propiedades bigint,
    calificacion_promedio_propiedades numeric,
    
    -- Reseñas como viajero (recibidas de anfitriones)
    total_resenas_como_viajero bigint,
    calificacion_promedio_como_viajero numeric,
    
    -- Reseñas hechas por el usuario
    total_resenas_hechas_propiedades bigint,
    total_resenas_hechas_viajeros bigint,
    
    -- Distribuciones
    distribucion_propiedades jsonb,
    distribucion_viajero jsonb
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        -- Reseñas recibidas en propiedades (como anfitrión)
        COALESCE(prop_stats.total_resenas, 0::bigint) as total_resenas_propiedades,
        COALESCE(prop_stats.calificacion_promedio, 0::numeric) as calificacion_promedio_propiedades,
        
        -- Reseñas recibidas como viajero
        COALESCE(viaj_stats.total_resenas, 0::bigint) as total_resenas_como_viajero,
        COALESCE(viaj_stats.calificacion_promedio, 0::numeric) as calificacion_promedio_como_viajero,
        
        -- Reseñas hechas
        COALESCE(hechas_prop.total, 0::bigint) as total_resenas_hechas_propiedades,
        COALESCE(hechas_viaj.total, 0::bigint) as total_resenas_hechas_viajeros,
        
        -- Distribuciones
        COALESCE(prop_stats.distribucion, '{}'::jsonb) as distribucion_propiedades,
        COALESCE(viaj_stats.distribucion, '{}'::jsonb) as distribucion_viajero
    FROM (SELECT 1 as dummy) base
    LEFT JOIN (
        -- Estadísticas de propiedades
        SELECT 
            COUNT(r.id) as total_resenas,
            ROUND(AVG(r.calificacion), 1) as calificacion_promedio,
            COALESCE(
                jsonb_object_agg(r.calificacion::text, COUNT(*)) 
                FILTER (WHERE r.calificacion IS NOT NULL),
                '{}'::jsonb
            ) as distribucion
        FROM propiedades p
        JOIN resenas r ON p.id = r.propiedad_id
        WHERE p.anfitrion_id = user_uuid
    ) prop_stats ON true
    LEFT JOIN (
        -- Estadísticas como viajero
        SELECT 
            COUNT(rv.id) as total_resenas,
            ROUND(AVG(rv.calificacion), 1) as calificacion_promedio,
            COALESCE(
                jsonb_object_agg(rv.calificacion::text, COUNT(*)) 
                FILTER (WHERE rv.calificacion IS NOT NULL),
                '{}'::jsonb
            ) as distribucion
        FROM resenas_viajeros rv
        WHERE rv.viajero_id = user_uuid
    ) viaj_stats ON true
    LEFT JOIN (
        -- Reseñas hechas a propiedades
        SELECT COUNT(*) as total
        FROM resenas r
        WHERE r.viajero_id = user_uuid
    ) hechas_prop ON true
    LEFT JOIN (
        -- Reseñas hechas a viajeros
        SELECT COUNT(*) as total
        FROM resenas_viajeros rv
        WHERE rv.anfitrion_id = user_uuid
    ) hechas_viaj ON true;
END;
$$ LANGUAGE plpgsql;

-- Función para verificar si se puede reseñar a un viajero
CREATE OR REPLACE FUNCTION can_review_traveler(anfitrion_uuid uuid, reserva_uuid uuid)
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.reservas r
        JOIN public.propiedades p ON r.propiedad_id = p.id
        WHERE r.id = reserva_uuid
        AND p.anfitrion_id = anfitrion_uuid
        AND (r.estado = 'completada' OR r.fecha_fin < NOW())
        AND NOT EXISTS (
            SELECT 1 FROM public.resenas_viajeros rv
            WHERE rv.reserva_id = reserva_uuid 
            AND rv.anfitrion_id = anfitrion_uuid
        )
    );
END;
$$ LANGUAGE plpgsql;

-- Función para verificar si se puede reseñar una propiedad
CREATE OR REPLACE FUNCTION can_review_property(viajero_uuid uuid, reserva_uuid uuid)
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.reservas r
        WHERE r.id = reserva_uuid
        AND r.viajero_id = viajero_uuid
        AND (r.estado = 'completada' OR r.fecha_fin < NOW())
        AND NOT EXISTS (
            SELECT 1 FROM public.resenas re
            WHERE re.reserva_id = reserva_uuid 
            AND re.viajero_id = viajero_uuid
        )
    );
END;
$$ LANGUAGE plpgsql;

-- Comentarios
COMMENT ON TABLE public.resenas_viajeros IS 'Reseñas que los anfitriones hacen a los viajeros después de completar una reserva';
COMMENT ON FUNCTION get_user_complete_review_stats(uuid) IS 'Obtiene estadísticas completas de reseñas de un usuario (como anfitrión y como viajero)';
COMMENT ON FUNCTION can_review_traveler(uuid, uuid) IS 'Verifica si un anfitrión puede reseñar a un viajero para una reserva específica';
COMMENT ON FUNCTION can_review_property(uuid, uuid) IS 'Verifica si un viajero puede reseñar una propiedad para una reserva específica';

-- Habilitar Realtime para reseñas de viajeros (solo si la publicación existe)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.resenas_viajeros;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Ignorar errores si la publicación no existe
        NULL;
END $$;

SELECT 'Sistema de reseñas bidireccional implementado correctamente' as status;