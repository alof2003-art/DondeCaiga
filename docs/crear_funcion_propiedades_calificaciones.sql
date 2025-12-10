-- Función para obtener propiedades con calificaciones
-- Ejecutar esto en Supabase SQL Editor

CREATE OR REPLACE FUNCTION get_propiedades_con_calificaciones()
RETURNS TABLE (
  id uuid,
  anfitrion_id uuid,
  titulo text,
  descripcion text,
  direccion text,
  ciudad text,
  pais text,
  latitud double precision,
  longitud double precision,
  capacidad_personas integer,
  numero_habitaciones integer,
  numero_banos integer,
  tiene_garaje boolean,
  foto_principal_url text,
  estado text,
  created_at timestamp with time zone,
  updated_at timestamp with time zone,
  nombre_anfitrion text,
  foto_anfitrion text,
  calificacion_promedio double precision,
  numero_resenas bigint,
  calificacion_anfitrion double precision
)
LANGUAGE sql
STABLE
AS $$
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
    AVG(r.calificacion)::double precision as calificacion_promedio,
    COUNT(r.id) as numero_resenas,
    (
      SELECT AVG(r2.calificacion)::double precision
      FROM resenas r2
      JOIN propiedades p2 ON r2.propiedad_id = p2.id
      WHERE p2.anfitrion_id = p.anfitrion_id
    ) as calificacion_anfitrion
  FROM propiedades p
  LEFT JOIN users_profiles up ON p.anfitrion_id = up.id
  LEFT JOIN resenas r ON p.id = r.propiedad_id
  WHERE p.estado = 'activo'
  GROUP BY p.id, up.nombre, up.foto_perfil_url
  ORDER BY p.created_at DESC;
$$;
