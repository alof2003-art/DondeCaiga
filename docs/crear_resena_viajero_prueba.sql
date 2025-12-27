-- Script para crear una reseña de viajero de prueba
-- Para que Gabriel (alof2003@gmail.com) tenga calificaciones como viajero

-- 1. Verificar el ID de Gabriel
SELECT id, email FROM auth.users WHERE email = 'alof2003@gmail.com';

-- 2. Buscar una reserva donde Gabriel sea el viajero
SELECT 
    r.id as reserva_id,
    r.viajero_id,
    r.anfitrion_id,
    r.estado,
    r.fecha_fin,
    p.titulo as propiedad
FROM reservas r
JOIN propiedades p ON r.propiedad_id = p.id
JOIN auth.users u ON r.viajero_id = u.id
WHERE u.email = 'alof2003@gmail.com'
AND r.estado IN ('completada', 'confirmada')
ORDER BY r.created_at DESC
LIMIT 5;

-- 3. Insertar reseña de viajero (reemplaza los IDs según los resultados anteriores)
-- NOTA: Necesitas reemplazar GABRIEL_ID, ANFITRION_ID y RESERVA_ID con los valores reales

INSERT INTO public.resenas_viajeros (
    viajero_id,
    anfitrion_id,
    reserva_id,
    calificacion,
    comentario,
    aspectos
) VALUES (
    'GABRIEL_ID_AQUI', -- ID de Gabriel (alof2003@gmail.com)
    'ANFITRION_ID_AQUI', -- ID del anfitrión de la reserva
    'RESERVA_ID_AQUI', -- ID de una reserva donde Gabriel fue viajero
    3.6, -- Calificación que será recalculada automáticamente
    'Gabriel fue un excelente huésped. Muy respetuoso con las normas de la casa y mantuvo todo limpio. La comunicación fue fluida durante toda su estadía. Definitivamente lo recomiendo como viajero.',
    '{
        "limpieza": 4,
        "comunicacion": 4,
        "respeto_normas": 3,
        "cuidado_propiedad": 4,
        "puntualidad": 3
    }'::jsonb
);

-- 4. Verificar que se insertó correctamente
SELECT 
    rv.*,
    u_viajero.email as email_viajero,
    u_anfitrion.email as email_anfitrion
FROM resenas_viajeros rv
JOIN auth.users u_viajero ON rv.viajero_id = u_viajero.id
JOIN auth.users u_anfitrion ON rv.anfitrion_id = u_anfitrion.id
WHERE u_viajero.email = 'alof2003@gmail.com'
ORDER BY rv.created_at DESC
LIMIT 1;

-- ALTERNATIVA: Si no hay reservas, crear una reserva de prueba primero
/*
-- Crear reserva de prueba (solo si no existe)
INSERT INTO public.reservas (
    viajero_id,
    propiedad_id,
    anfitrion_id,
    fecha_inicio,
    fecha_fin,
    precio_total,
    estado
) VALUES (
    'GABRIEL_ID_AQUI', -- ID de Gabriel
    '2b86e6a1-50ab-4a43-afdf-a4863783bcb3', -- ID de la propiedad "poli"
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3', -- ID del anfitrión de "poli"
    '2024-11-15', -- Fecha pasada
    '2024-11-17', -- Fecha pasada
    75.00,
    'completada'
) ON CONFLICT DO NOTHING;
*/

-- ASPECTOS DE LA RESEÑA DE VIAJERO:
-- - limpieza: 4/5 (Muy buena)
-- - comunicacion: 4/5 (Muy buena) 
-- - respeto_normas: 3/5 (Buena)
-- - cuidado_propiedad: 4/5 (Muy buena)
-- - puntualidad: 3/5 (Buena)
-- 
-- Promedio: (4+4+3+4+3)/5 = 3.6 estrellas
-- 
-- Esto permitirá que Gabriel tenga:
-- ✅ Calificación como anfitrión: 4.2 (de la propiedad "poli")
-- ✅ Calificación como viajero: 3.6 (nueva reseña)
-- ✅ Ambas aparecerán en su perfil: 🏠 ⭐ 4.2 (1) | 🧳 ⭐ 3.6 (1)