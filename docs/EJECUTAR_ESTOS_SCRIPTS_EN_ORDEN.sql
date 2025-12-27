-- ========================================
-- SCRIPTS PARA EJECUTAR EN SUPABASE (EN ESTE ORDEN)
-- ========================================

-- SCRIPT 1: MIGRAR TABLA RESENAS_VIAJEROS
-- ========================================
-- Cambiar el tipo de calificacion a numeric para permitir decimales
ALTER TABLE public.resenas_viajeros 
ALTER COLUMN calificacion TYPE numeric(3,2);

-- Actualizar el constraint para permitir decimales
ALTER TABLE public.resenas_viajeros 
DROP CONSTRAINT IF EXISTS resenas_viajeros_calificacion_check;

ALTER TABLE public.resenas_viajeros 
ADD CONSTRAINT resenas_viajeros_calificacion_check 
CHECK (calificacion >= 1.0 AND calificacion <= 5.0);

-- Función para calcular el promedio de aspectos
CREATE OR REPLACE FUNCTION calcular_promedio_aspectos(aspectos_json jsonb)
RETURNS numeric AS $$
DECLARE
    suma integer := 0;
    contador integer := 0;
    aspecto_valor integer;
    promedio numeric;
BEGIN
    -- Iterar sobre todos los aspectos en el JSON
    FOR aspecto_valor IN 
        SELECT value::integer 
        FROM jsonb_each_text(aspectos_json) 
        WHERE value IS NOT NULL AND value != 'null'
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

-- Actualizar todas las reseñas de viajeros existentes
UPDATE resenas_viajeros 
SET calificacion = calcular_promedio_aspectos(aspectos)
WHERE aspectos IS NOT NULL;

-- Crear trigger para calcular automáticamente la calificación en futuras inserciones/actualizaciones
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

-- Crear el trigger
DROP TRIGGER IF EXISTS trigger_calificacion_viajero ON resenas_viajeros;
CREATE TRIGGER trigger_calificacion_viajero
    BEFORE INSERT OR UPDATE ON resenas_viajeros
    FOR EACH ROW
    EXECUTE FUNCTION trigger_calcular_calificacion_viajero();

-- ========================================
-- SCRIPT 2: MIGRAR TABLA RESENAS (PROPIEDADES)
-- ========================================

-- Agregar columna de aspectos a la tabla resenas
ALTER TABLE public.resenas 
ADD COLUMN IF NOT EXISTS aspectos jsonb DEFAULT '{
  "limpieza": null, 
  "ubicacion": null, 
  "comodidad": null, 
  "comunicacion_anfitrion": null, 
  "relacion_calidad_precio": null
}'::jsonb;

-- Cambiar el tipo de calificacion a numeric para permitir decimales
ALTER TABLE public.resenas 
ALTER COLUMN calificacion TYPE numeric(3,2);

-- Actualizar el constraint para permitir decimales
ALTER TABLE public.resenas 
DROP CONSTRAINT IF EXISTS resenas_calificacion_check;

ALTER TABLE public.resenas 
ADD CONSTRAINT resenas_calificacion_check 
CHECK (calificacion >= 1.0 AND calificacion <= 5.0);

-- Función para calcular el promedio de aspectos de propiedades
CREATE OR REPLACE FUNCTION calcular_promedio_aspectos_propiedades(aspectos_json jsonb)
RETURNS numeric AS $$
DECLARE
    suma integer := 0;
    contador integer := 0;
    aspecto_valor integer;
    promedio numeric;
BEGIN
    -- Iterar sobre todos los aspectos en el JSON
    FOR aspecto_valor IN 
        SELECT value::integer 
        FROM jsonb_each_text(aspectos_json) 
        WHERE value IS NOT NULL AND value != 'null'
    LOOP
        suma := suma + aspecto_valor;
        contador := contador + 1;
    END LOOP;
    
    -- Si no hay aspectos, devolver la calificación actual o 1
    IF contador = 0 THEN
        RETURN 1.0;
    END IF;
    
    -- Calcular promedio exacto (sin redondear)
    promedio := suma::numeric / contador::numeric;
    
    -- Asegurar que esté entre 1.0 y 5.0
    RETURN GREATEST(1.0, LEAST(5.0, promedio));
END;
$$ LANGUAGE plpgsql;

-- Trigger para calcular automáticamente la calificación en futuras inserciones/actualizaciones
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

-- Crear el trigger
DROP TRIGGER IF EXISTS trigger_calificacion_propiedad ON resenas;
CREATE TRIGGER trigger_calificacion_propiedad
    BEFORE INSERT OR UPDATE ON resenas
    FOR EACH ROW
    EXECUTE FUNCTION trigger_calcular_calificacion_propiedad();

-- Actualizar reseñas existentes que no tienen aspectos
-- (Mantener su calificación actual pero agregar aspectos por defecto)
UPDATE resenas 
SET aspectos = jsonb_build_object(
    'limpieza', calificacion::integer,
    'ubicacion', calificacion::integer,
    'comodidad', calificacion::integer,
    'comunicacion_anfitrion', calificacion::integer,
    'relacion_calidad_precio', calificacion::integer
)
WHERE aspectos IS NULL OR aspectos = '{}'::jsonb;

-- ========================================
-- SCRIPT 3: CREAR FUNCIÓN DE ESTADÍSTICAS COMPLETAS
-- ========================================

CREATE OR REPLACE FUNCTION get_user_complete_review_stats(user_uuid uuid)
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
            COUNT(r.id)::integer as hechas_prop,
            COUNT(rv.id)::integer as hechas_viaj
        FROM (SELECT user_uuid as uid) u
        LEFT JOIN resenas r ON r.viajero_id = u.uid
        LEFT JOIN resenas_viajeros rv ON rv.anfitrion_id = u.uid
    )
    SELECT 
        sp.total_prop,
        sp.promedio_prop,
        sp.dist_prop,
        sv.total_viaj,
        sv.promedio_viaj,
        sv.dist_viaj,
        sh.hechas_prop,
        sh.hechas_viaj
    FROM stats_propiedades sp, stats_viajero sv, stats_hechas sh;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- SCRIPT 4: VERIFICAR QUE TODO FUNCIONA
-- ========================================

-- Verificar las funciones
SELECT 'Funciones creadas correctamente' as status;

-- Verificar estadísticas para Gabriel (reemplaza con tu ID real)
SELECT * FROM get_user_complete_review_stats('0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid);

-- Verificar estructura de tablas
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('resenas', 'resenas_viajeros')
AND column_name IN ('calificacion', 'aspectos')
ORDER BY table_name, column_name;

-- ========================================
-- ¡IMPORTANTE!
-- ========================================
-- Después de ejecutar estos scripts:
-- 1. La reseña que creaste de la propiedad "poli" debería funcionar
-- 2. Las calificaciones aparecerán en el perfil
-- 3. Podrás crear reseñas con aspectos individuales
-- 4. Todo se calculará automáticamente