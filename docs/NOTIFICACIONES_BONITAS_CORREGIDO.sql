-- =====================================================
-- CREAR NOTIFICACIONES BONITAS Y ATRACTIVAS - CORREGIDO
-- =====================================================

-- 1. Limpiar notificaciones existentes
DELETE FROM notifications WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 2. Crear notificaciones atractivas y realistas
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    metadata,
    is_read,
    created_at
) VALUES 
-- Notificación de bienvenida
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    '¡Bienvenido a Donde Caiga! 🎉',
    'Tu cuenta está lista. Explora propiedades increíbles y vive experiencias únicas.',
    'general',
    '{"tipo_bienvenida": true, "icono": "🏠"}'::jsonb,
    FALSE,
    NOW()
),

-- Nueva reserva
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'Nueva solicitud de reserva 🏡',
    'María González quiere reservar tu propiedad "Casa Vista al Mar" del 15 al 20 de enero.',
    'solicitudReserva',
    '{"viajero": "María González", "propiedad": "Casa Vista al Mar", "fechas": "15-20 enero"}'::jsonb,
    FALSE,
    NOW() - INTERVAL '30 minutes'
),

-- Reserva aceptada
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    '¡Reserva confirmada! ✅',
    'Tu reserva en "Apartamento Centro" ha sido aceptada. ¡Prepárate para una experiencia increíble!',
    'reservaAceptada',
    '{"propiedad": "Apartamento Centro", "anfitrion": "Carlos Ruiz"}'::jsonb,
    FALSE,
    NOW() - INTERVAL '2 hours'
),

-- Nueva reseña
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'Nueva reseña recibida ⭐',
    'Ana López te dejó una reseña de 5 estrellas: "Excelente anfitrión, muy recomendado"',
    'nuevaResena',
    '{"autor": "Ana López", "calificacion": 5, "comentario": "Excelente anfitrión"}'::jsonb,
    FALSE,
    NOW() - INTERVAL '4 hours'
),

-- Nuevo mensaje
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'Nuevo mensaje 💬',
    'Pedro Martín: "Hola, tengo una pregunta sobre el check-in..."',
    'nuevoMensaje',
    '{"remitente": "Pedro Martín", "preview": "Hola, tengo una pregunta sobre el check-in..."}'::jsonb,
    FALSE,
    NOW() - INTERVAL '6 hours'
),

-- Recordatorio
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'Recordatorio de check-in ⏰',
    'Tu huésped llegará mañana a las 3:00 PM. ¡No olvides preparar la propiedad!',
    'recordatorioCheckin',
    '{"huesped": "Laura Fernández", "hora": "15:00", "fecha": "mañana"}'::jsonb,
    TRUE,
    NOW() - INTERVAL '1 day'
),

-- Sistema funcionando
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'Sistema de notificaciones activo 🔔',
    'Las notificaciones push están configuradas correctamente. Recibirás alertas en tiempo real.',
    'general',
    '{"sistema": "notificaciones", "estado": "activo"}'::jsonb,
    TRUE,
    NOW() - INTERVAL '2 days'
);

-- 3. Verificar que se crearon correctamente
SELECT 
    'NOTIFICACIONES BONITAS CREADAS' as status,
    COUNT(*) as total_notificaciones,
    COUNT(CASE WHEN is_read = false THEN 1 END) as no_leidas
FROM notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 4. Mostrar las notificaciones creadas
SELECT 
    title,
    message,
    type,
    is_read,
    created_at
FROM notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
ORDER BY created_at DESC;

-- 5. Mensaje final
SELECT '✅ NOTIFICACIONES BONITAS CREADAS - REINICIA LA APP' as resultado;