-- Script para arreglar las calificaciones de reseñas de viajeros
-- Calcula la calificación general como el promedio de los aspectos individuales

-- 1. Cambiar el tipo de calificacion a numeric para permitir decimales
ALTER TABLE public.resenas_viajeros 
ALTER COLUMN calificacion TYPE numeric(3,2);

-- 2. Actualizar el constraint para permitir decimales
ALTER TABLE public.resenas_viajeros 
DROP CONSTRAINT IF EXISTS resenas_viajeros_calificacion_check;

ALTER TABLE public.resenas_viajeros 
ADD CONSTRAINT resenas_viajeros_calificacion_check 
CHECK (calificacion >= 1.0 AND calificacion <= 5.0);

-- 3. Función para calcular el promedio de aspectos
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

-- Verificar los cambios
SELECT 
    id,
    calificacion as calificacion_nueva,
    aspectos,
    calcular_promedio_aspectos(aspectos) as calificacion_calculada
FROM resenas_viajeros 
WHERE aspectos IS NOT NULL
ORDER BY created_at DESC;

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

-- Comentarios para entender el script
COMMENT ON FUNCTION calcular_promedio_aspectos(jsonb) IS 'Calcula el promedio exacto de los aspectos de una reseña de viajero (sin redondear)';
COMMENT ON FUNCTION trigger_calcular_calificacion_viajero() IS 'Trigger que calcula automáticamente la calificación general basada en los aspectos individuales';