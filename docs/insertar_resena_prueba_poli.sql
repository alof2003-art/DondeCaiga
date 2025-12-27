-- Script para insertar reseña de prueba para la propiedad "poli"
-- Usuario: jicima2772@gamintor.com
-- Propiedad: poli (ID: 2b86e6a1-50ab-4a43-afdf-a4863783bcb3)

-- Primero necesitamos obtener el ID del usuario jicima2772@gamintor.com
-- y crear una reserva si no existe

-- 1. Obtener el ID del usuario (ejecutar primero para ver el resultado)
SELECT id, email FROM auth.users WHERE email = 'jicima2772@gamintor.com';

-- 2. Crear una reserva de prueba (necesaria para poder hacer reseña)
-- Reemplaza 'USER_ID_AQUI' con el ID que obtengas del paso 1
INSERT INTO public.reservas (
    id,
    viajero_id,
    propiedad_id,
    anfitrion_id,
    fecha_inicio,
    fecha_fin,
    precio_total,
    estado,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    'USER_ID_AQUI', -- Reemplazar con el ID real del usuario
    '2b86e6a1-50ab-4a43-afdf-a4863783bcb3', -- ID de la propiedad "poli"
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3', -- ID del anfitrión
    '2024-12-01', -- Fecha de inicio (pasada)
    '2024-12-03', -- Fecha de fin (pasada)
    50.00,
    'completada', -- Estado completada para poder reseñar
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '2 days'
) ON CONFLICT (id) DO NOTHING;

-- 3. Insertar la reseña con aspectos (NUEVO SISTEMA)
-- Reemplaza 'USER_ID_AQUI' y 'RESERVA_ID_AQUI' con los IDs reales
INSERT INTO public.resenas (
    id,
    propiedad_id,
    viajero_id,
    reserva_id,
    calificacion,
    comentario,
    aspectos,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    '2b86e6a1-50ab-4a43-afdf-a4863783bcb3', -- ID propiedad "poli"
    'USER_ID_AQUI', -- Reemplazar con ID del usuario
    'RESERVA_ID_AQUI', -- Reemplazar con ID de la reserva creada arriba
    4.2, -- Calificación calculada automáticamente por aspectos
    'Excelente propiedad, muy cómoda y bien ubicada. El anfitrión fue muy atento y la comunicación fue perfecta. Definitivamente recomendada!',
    '{
        "limpieza": 5,
        "ubicacion": 4,
        "comodidad": 4,
        "comunicacion_anfitrion": 5,
        "relacion_calidad_precio": 3
    }'::jsonb,
    NOW() - INTERVAL '1 day',
    NOW() - INTERVAL '1 day'
);

-- SCRIPT ALTERNATIVO MÁS SIMPLE (si ya tienes una reserva):
-- Solo ejecuta esto si ya existe una reserva para este usuario y propiedad

/*
-- Obtener reserva existente
SELECT r.id, r.viajero_id, r.propiedad_id, r.estado 
FROM reservas r 
JOIN auth.users u ON r.viajero_id = u.id 
WHERE u.email = 'jicima2772@gamintor.com' 
AND r.propiedad_id = '2b86e6a1-50ab-4a43-afdf-a4863783bcb3';

-- Insertar reseña directamente (reemplaza los IDs)
INSERT INTO public.resenas (
    propiedad_id,
    viajero_id,
    reserva_id,
    calificacion,
    comentario,
    aspectos
) VALUES (
    '2b86e6a1-50ab-4a43-afdf-a4863783bcb3',
    'USER_ID_DEL_RESULTADO_ANTERIOR',
    'RESERVA_ID_DEL_RESULTADO_ANTERIOR',
    4.2,
    'Muy buena experiencia en esta propiedad!',
    '{
        "limpieza": 5,
        "ubicacion": 4,
        "comodidad": 4,
        "comunicacion_anfitrion": 5,
        "relacion_calidad_precio": 3
    }'::jsonb
);
*/

-- Verificar que se insertó correctamente
SELECT 
    r.*,
    u.email as email_viajero,
    p.titulo as titulo_propiedad
FROM resenas r
JOIN auth.users u ON r.viajero_id = u.id
JOIN propiedades p ON r.propiedad_id = p.id
WHERE p.titulo = 'poli'
ORDER BY r.created_at DESC;