-- ========================================
-- SCRIPT PARA ARREGLAR ERRORES SQL
-- ========================================

-- PASO 1: Eliminar funciones existentes que causan conflicto
DROP FUNCTION IF EXISTS get_user_complete_review_stats(uuid);
DROP FUNCTION IF EXISTS get_user_complete_review_stats(text);

-- PASO 2: Verificar si las columnas ya existen antes de agregarlas
DO $$ 
BEGIN
    -- Verificar si la columna aspectos existe en resenas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'resenas' AND column_name = 'aspectos'
    ) THEN
        ALTER TABLE public.resenas 
        ADD COLUMN aspectos jsonb DEFAULT '{
          "limpieza": null, 
          "ubicacion": null, 
          "comodidad": null, 
          "comunicacion_anfitrion": null, 
          "relacion_calidad_precio": null
        }'::jsonb;
    END IF;
END $$;

-- PASO 3: Cambiar tipos de columnas (solo si es necesario)
DO $$
BEGIN
    -- Cambiar calificacion en resenas_viajeros
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'resenas_viajeros' 
        AND column_name = 'calificacion' 
        AND data_type != 'numeric'
    ) THEN
        ALTER TABLE public.resenas_viajeros 
        ALTER COLUMN calificacion TYPE numeric(3,2);
    END IF;
    
    -- Cambiar calificacion en resenas
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'resenas' 
        AND column_name = 'calificacion' 
        AND data_type != 'numeric'
    ) THEN
        ALTER TABLE public.resenas 
        ALTER COLUMN calificacion TYPE numeric(3,2);
    END IF;
END $$;

-- PASO 4: Actualizar constraints
ALTER TABLE public.resenas_viajeros 
DROP CONSTRAINT IF EXISTS resenas_viajeros_calificacion_check;

ALTER TABLE public.resenas_viajeros 
ADD CONSTRAINT resenas_viajeros_calificacion_check 
CHECK (calificacion >= 1.0 AND calificacion <= 5.0);

ALTER TABLE public.resenas 
DROP CONSTRAINT IF EXISTS resenas_calificacion_check;

ALTER TABLE public.resenas 
ADD CONSTRAINT resenas_calificacion_check 
CHECK (calificacion >= 1.0 AND calificacion <= 5.0);

-- PASO 5: Crear funciones de cálculo
CREATE OR REPLACE FUNCTION calcular_promedio_aspectos(aspectos_json jsonb)
RETURNS numeric AS $$
DECLARE
    suma integer := 0;
    contador integer := 0;
    aspecto_valor integer;
    promedio numeric;
BEGIN
    IF aspectos_json IS NULL THEN
        RETURN 1.0;
    END IF;
    
    -- Iterar sobre todos los aspectos en el JSON
    FOR aspecto_valor IN 
        SELECT value::integer 
        FROM jsonb_each_text(aspectos_json) 
        WHERE value IS NOT NULL AND value != 'null' AND value ~ '^[0-9]+$'
    LOOP
        suma := suma + aspecto_valor;
        contador := contador + 1;
    END LOOP;
    
    -- Si no hay aspectos, devolver 1
    IF contador = 0 THEN
        RETURN 1.0;
    END IF;
    
    -- Calcular promedio exacto (sin redondear)
    promedio := suma::numeric / contador::numeric;
    
    -- Asegurar que esté entre 1.0 y 5.0
    RETURN GREATEST(1.0, LEAST(5.0, promedio));
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION calcular_promedio_aspectos_propiedades(aspectos_json jsonb)
RETURNS numeric AS $$
DECLARE
    suma integer := 0;
    contador integer := 0;
    aspecto_valor integer;
    promedio numeric;
BEGIN
    IF aspectos_json IS NULL THEN
        RETURN 1.0;
    END IF;
    
    -- Iterar sobre todos los aspectos en el JSON
    FOR aspecto_valor IN 
        SELECT value::integer 
        FROM jsonb_each_text(aspectos_json) 
        WHERE value IS NOT NULL AND value != 'null' AND value ~ '^[0-9]+$'
    LOOP
        suma := suma + aspecto_valor;
        contador := contador + 1;
    END LOOP;
    
    -- Si no hay aspectos, devolver 1
    IF contador = 0 THEN
        RETURN 1.0;
    END IF;
    
    -- Calcular promedio exacto (sin redondear)
    promedio := suma::numeric / contador::numeric;
    
    -- Asegurar que esté entre 1.0 y 5.0
    RETURN GREATEST(1.0, LEAST(5.0, promedio));
END;
$$ LANGUAGE plpgsql;

-- PASO 6: Crear triggers
CREATE OR REPLACE FUNCTION trigger_calcular_calificacion_viajero()
RETURNS TRIGGER AS $$
BEGIN
    -- Si hay aspectos, calcular la calificación automáticamente
    IF NEW.aspectos IS NOT NULL THEN
        NEW.calificacion := calcular_promedio_aspectos(NEW.aspectos);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trigger_calcular_calificacion_propiedad()
RETURNS TRIGGER AS $$
BEGIN
    -- Si hay aspectos, calcular la calificación automáticamente
    IF NEW.aspectos IS NOT NULL THEN
        NEW.calificacion := calcular_promedio_aspectos_propiedades(NEW.aspectos);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear los triggers
DROP TRIGGER IF EXISTS trigger_calificacion_viajero ON resenas_viajeros;
CREATE TRIGGER trigger_calificacion_viajero
    BEFORE INSERT OR UPDATE ON resenas_viajeros
    FOR EACH ROW
    EXECUTE FUNCTION trigger_calcular_calificacion_viajero();

DROP TRIGGER IF EXISTS trigger_calificacion_propiedad ON resenas;
CREATE TRIGGER trigger_calificacion_propiedad
    BEFORE INSERT OR UPDATE ON resenas
    FOR EACH ROW
    EXECUTE FUNCTION trigger_calcular_calificacion_propiedad();

-- PASO 7: Crear función de estadísticas (con nombre único)
CREATE OR REPLACE FUNCTION get_user_review_statistics(user_uuid uuid)
RETURNS TABLE(
    total_resenas_propiedades integer,
    calificacion_promedio_propiedades numeric,
    distribucion_propiedades jsonb,
    total_resenas_como_viajero integer,
    calificacion_promedio_como_viajero numeric,
    distribucion_viajero jsonb,
    total_resenas_hechas_propiedades integer,
    total_resenas_hechas_viajeros integer
) AS $$
BEGIN
    RETURN QUERY
    WITH stats_propiedades AS (
        SELECT 
            COUNT(*)::integer as total_prop,
            COALESCE(AVG(r.calificacion), 0)::numeric as promedio_prop,
            jsonb_build_object(
                '1', COUNT(*) FILTER (WHERE r.calificacion >= 1 AND r.calificacion < 2),
                '2', COUNT(*) FILTER (WHERE r.calificacion >= 2 AND r.calificacion < 3),
                '3', COUNT(*) FILTER (WHERE r.calificacion >= 3 AND r.calificacion < 4),
                '4', COUNT(*) FILTER (WHERE r.calificacion >= 4 AND r.calificacion < 5),
                '5', COUNT(*) FILTER (WHERE r.calificacion = 5)
            ) as dist_prop
        FROM resenas r
        JOIN propiedades p ON r.propiedad_id = p.id
        WHERE p.anfitrion_id = user_uuid
    ),
    stats_viajero AS (
        SELECT 
            COUNT(*)::integer as total_viaj,
            COALESCE(AVG(rv.calificacion), 0)::numeric as promedio_viaj,
            jsonb_build_object(
                '1', COUNT(*) FILTER (WHERE rv.calificacion >= 1 AND rv.calificacion < 2),
                '2', COUNT(*) FILTER (WHERE rv.calificacion >= 2 AND rv.calificacion < 3),
                '3', COUNT(*) FILTER (WHERE rv.calificacion >= 3 AND rv.calificacion < 4),
                '4', COUNT(*) FILTER (WHERE rv.calificacion >= 4 AND rv.calificacion < 5),
                '5', COUNT(*) FILTER (WHERE rv.calificacion = 5)
            ) as dist_viaj
        FROM resenas_viajeros rv
        WHERE rv.viajero_id = user_uuid
    ),
    stats_hechas AS (
        SELECT 
            (SELECT COUNT(*)::integer FROM resenas WHERE viajero_id = user_uuid) as hechas_prop,
            (SELECT COUNT(*)::integer FROM resenas_viajeros WHERE anfitrion_id = user_uuid) as hechas_viaj
    )
    SELECT 
        COALESCE(sp.total_prop, 0),
        COALESCE(sp.promedio_prop, 0),
        COALESCE(sp.dist_prop, '{}'::jsonb),
        COALESCE(sv.total_viaj, 0),
        COALESCE(sv.promedio_viaj, 0),
        COALESCE(sv.dist_viaj, '{}'::jsonb),
        COALESCE(sh.hechas_prop, 0),
        COALESCE(sh.hechas_viaj, 0)
    FROM stats_propiedades sp
    FULL OUTER JOIN stats_viajero sv ON true
    FULL OUTER JOIN stats_hechas sh ON true;
END;
$$ LANGUAGE plpgsql;

-- PASO 8: Actualizar reseñas existentes
UPDATE resenas 
SET aspectos = jsonb_build_object(
    'limpieza', LEAST(5, GREATEST(1, calificacion::integer)),
    'ubicacion', LEAST(5, GREATEST(1, calificacion::integer)),
    'comodidad', LEAST(5, GREATEST(1, calificacion::integer)),
    'comunicacion_anfitrion', LEAST(5, GREATEST(1, calificacion::integer)),
    'relacion_calidad_precio', LEAST(5, GREATEST(1, calificacion::integer))
)
WHERE aspectos IS NULL OR aspectos = '{}'::jsonb;

-- PASO 9: Verificar que todo funciona
SELECT 'Migración completada exitosamente' as status;

-- Probar la función con tu ID
SELECT * FROM get_user_review_statistics('0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid);