-- Agregar campo tiene_garaje a la tabla propiedades
ALTER TABLE propiedades 
ADD COLUMN IF NOT EXISTS tiene_garaje BOOLEAN DEFAULT false;

-- Actualizar propiedades existentes (opcional, ya tienen false por defecto)
UPDATE propiedades 
SET tiene_garaje = false 
WHERE tiene_garaje IS NULL;
