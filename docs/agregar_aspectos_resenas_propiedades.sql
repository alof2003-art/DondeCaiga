-- Script para agregar aspectos a las reseñas de propiedades
-- Similar al sistema de reseñas de viajeros pero con aspectos relevantes para propiedades

-- 1. Agregar columna de aspectos a la tabla resenas
ALTER TABLE public.resenas 
ADD COLUMN IF NOT EXISTS aspectos jsonb DEFAULT '{
  "limpieza": null, 
  "ubicacion": null, 
  "comodidad": null, 
  "comunicacion_anfitrion": null, 
  "relacion_calidad_precio": null
}'::jsonb;

-- 2. Cambiar el tipo de calificacion a numeric para permitir decimales
ALTER TABLE public.resenas 
ALTER COLUMN calificacion TYPE numeric(3,2);

-- 3. Actualizar el constraint para permitir decimales
ALTER TABLE public.resenas 
DROP CONSTRAINT IF EXISTS resenas_calificacion_check;

ALTER TABLE public.resenas 
ADD CONSTRAINT resenas_calificacion_check 
CHECK (calificacion >= 1.0 AND calificacion <= 5.0);

-- 4. Función para calcular el promedio de aspectos de propiedades
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

-- 5. Trigger para calcular automáticamente la calificación en futuras inserciones/actualizaciones
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

-- 6. Crear el trigger
DROP TRIGGER IF EXISTS trigger_calificacion_propiedad ON resenas;
CREATE TRIGGER trigger_calificacion_propiedad
    BEFORE INSERT OR UPDATE ON resenas
    FOR EACH ROW
    EXECUTE FUNCTION trigger_calcular_calificacion_propiedad();

-- 7. Actualizar reseñas existentes que no tienen aspectos
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

-- 8. Verificar los cambios
SELECT 
    id,
    calificacion,
    aspectos,
    calcular_promedio_aspectos_propiedades(aspectos) as calificacion_calculada
FROM resenas 
WHERE aspectos IS NOT NULL
ORDER BY created_at DESC
LIMIT 10;

-- Comentarios para entender el script
COMMENT ON FUNCTION calcular_promedio_aspectos_propiedades(jsonb) IS 'Calcula el promedio exacto de los aspectos de una reseña de propiedad (sin redondear)';
COMMENT ON FUNCTION trigger_calcular_calificacion_propiedad() IS 'Trigger que calcula automáticamente la calificación general basada en los aspectos individuales de propiedades';

-- Aspectos para propiedades:
-- - limpieza: Qué tan limpia estaba la propiedad
-- - ubicacion: Qué tan buena es la ubicación
-- - comodidad: Comodidad de la propiedad (camas, muebles, etc.)
-- - comunicacion_anfitrion: Qué tan buena fue la comunicación con el anfitrión
-- - relacion_calidad_precio: Si el precio vale la pena por lo que ofrece