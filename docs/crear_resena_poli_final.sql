-- Script FINAL para crear reseña de la propiedad "poli"
-- Usuario: jicima2772@gamintor.com (ID: 11cf640d-ed57-4997-8306-b13e1d643a38)
-- Reserva: c1ae7387-f082-4628-8781-9e2fff06bc90

-- PASO 1: Verificar que no existe ya una reseña
SELECT COUNT(*) as resenas_existentes 
FROM resenas 
WHERE viajero_id = '11cf640d-ed57-4997-8306-b13e1d643a38' 
AND propiedad_id = '2b86e6a1-50ab-4a43-afdf-a4863783bcb3';

-- PASO 2: Insertar la reseña con aspectos (NUEVO SISTEMA)
INSERT INTO public.resenas (
    propiedad_id,
    viajero_id,
    reserva_id,
    calificacion,
    comentario,
    aspectos
) VALUES (
    '2b86e6a1-50ab-4a43-afdf-a4863783bcb3', -- ID propiedad "poli"
    '11cf640d-ed57-4997-8306-b13e1d643a38', -- ID usuario jicima2772@gamintor.com
    'c1ae7387-f082-4628-8781-9e2fff06bc90', -- ID reserva confirmada
    4.2, -- Calificación que será recalculada automáticamente por el trigger
    'Excelente experiencia en esta propiedad! La ubicación es muy conveniente y la limpieza impecable. El anfitrión fue muy atento durante toda la estadía. La relación calidad-precio es buena, aunque podría mejorar un poco. Definitivamente la recomiendo para futuras estadías.',
    '{
        "limpieza": 5,
        "ubicacion": 4,
        "comodidad": 4,
        "comunicacion_anfitrion": 5,
        "relacion_calidad_precio": 3
    }'::jsonb
);

-- PASO 3: Verificar que se insertó correctamente
SELECT 
    r.id,
    r.calificacion,
    r.comentario,
    r.aspectos,
    r.created_at,
    u.email as email_viajero,
    p.titulo as titulo_propiedad
FROM resenas r
JOIN auth.users u ON r.viajero_id = u.id
JOIN propiedades p ON r.propiedad_id = p.id
WHERE r.viajero_id = '11cf640d-ed57-4997-8306-b13e1d643a38'
AND r.propiedad_id = '2b86e6a1-50ab-4a43-afdf-a4863783bcb3'
ORDER BY r.created_at DESC
LIMIT 1;

-- PASO 4: Verificar el cálculo automático de calificación
-- (Si ya ejecutaste los scripts de migración, la calificación debería ser 4.2)
SELECT 
    calificacion as calificacion_almacenada,
    aspectos,
    (
        (aspectos->>'limpieza')::int + 
        (aspectos->>'ubicacion')::int + 
        (aspectos->>'comodidad')::int + 
        (aspectos->>'comunicacion_anfitrion')::int + 
        (aspectos->>'relacion_calidad_precio')::int
    )::decimal / 5 as calificacion_calculada
FROM resenas 
WHERE viajero_id = '11cf640d-ed57-4997-8306-b13e1d643a38'
AND propiedad_id = '2b86e6a1-50ab-4a43-afdf-a4863783bcb3';

-- COMENTARIOS:
-- Aspectos de la reseña:
-- - Limpieza: 5/5 (Excelente)
-- - Ubicación: 4/5 (Muy buena)
-- - Comodidad: 4/5 (Muy buena)
-- - Comunicación anfitrión: 5/5 (Excelente)
-- - Relación calidad-precio: 3/5 (Buena)
-- 
-- Promedio: (5+4+4+5+3)/5 = 4.2 estrellas
-- 
-- Esta reseña permitirá probar:
-- ✅ Sistema de aspectos individuales
-- ✅ Calificaciones decimales (4.2)
-- ✅ Cálculo automático de promedio
-- ✅ Visualización en la app
-- ✅ Estadísticas con barras de p