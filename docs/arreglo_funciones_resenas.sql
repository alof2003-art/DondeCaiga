-- Arreglo de funciones para permitir reseñas en reservas pasadas
-- Ejecutar este SQL en Supabase para arreglar el problema del botón de reseñar viajero

-- Función actualizada para verificar si se puede reseñar a un viajero
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

-- Función actualizada para verificar si se puede reseñar una propiedad
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

-- Comentarios sobre las funciones
COMMENT ON FUNCTION can_review_traveler(uuid, uuid) IS 'Verifica si un anfitrión puede reseñar a un viajero para una reserva específica (completada o pasada)';
COMMENT ON FUNCTION can_review_property(uuid, uuid) IS 'Verifica si un viajero puede reseñar una propiedad para una reserva específica (completada o pasada)';