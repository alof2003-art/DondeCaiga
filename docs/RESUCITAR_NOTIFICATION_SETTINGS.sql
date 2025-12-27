-- =====================================================
-- RESUCITAR NOTIFICATION_SETTINGS Y ARREGLAR TRIGGERS
-- =====================================================

-- 1. CREAR LA TABLA NOTIFICATION_SETTINGS QUE BORRAMOS POR ERROR
CREATE TABLE IF NOT EXISTS public.notification_settings (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL UNIQUE,
    email_notifications_enabled boolean DEFAULT true,
    push_notifications_enabled boolean DEFAULT true,
    in_app_notifications_enabled boolean DEFAULT true,
    marketing_notifications_enabled boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT notification_settings_pkey PRIMARY KEY (id),
    CONSTRAINT notification_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users_profiles(id) ON DELETE CASCADE
);

-- 2. CREAR ÍNDICE PARA OPTIMIZAR CONSULTAS
CREATE INDEX IF NOT EXISTS idx_notification_settings_user_id ON public.notification_settings(user_id);

-- 3. HABILITAR RLS
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

-- 4. CREAR POLÍTICA RLS
DROP POLICY IF EXISTS "Users can manage their notification settings" ON public.notification_settings;
CREATE POLICY "Users can manage their notification settings" ON public.notification_settings 
    FOR ALL USING (user_id = auth.uid());

-- 5. CREAR TRIGGER PARA UPDATED_AT
DROP TRIGGER IF EXISTS update_notification_settings_updated_at ON public.notification_settings;
CREATE TRIGGER update_notification_settings_updated_at 
    BEFORE UPDATE ON public.notification_settings 
    FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- 6. INSERTAR CONFIGURACIÓN POR DEFECTO PARA TU USUARIO
INSERT INTO public.notification_settings (user_id)
VALUES ('0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid)
ON CONFLICT (user_id) DO NOTHING;

-- 7. VERIFICAR QUE SE CREÓ CORRECTAMENTE
SELECT 
    'NOTIFICATION_SETTINGS RESUCITADA' as status,
    user_id,
    email_notifications_enabled,
    push_notifications_enabled,
    in_app_notifications_enabled,
    created_at
FROM public.notification_settings 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 8. AHORA SÍ, CREAR LAS NOTIFICACIONES BONITAS
DELETE FROM notifications WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

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

-- 9. VERIFICAR RESULTADOS FINALES
SELECT 
    'NOTIFICACIONES CREADAS EXITOSAMENTE' as status,
    COUNT(*) as total_notificaciones,
    COUNT(CASE WHEN is_read = false THEN 1 END) as no_leidas
FROM notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 10. MOSTRAR LAS NOTIFICACIONES
SELECT 
    title,
    message,
    type,
    is_read,
    created_at
FROM notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
ORDER BY created_at DESC;

-- 11. MENSAJE FINAL
SELECT '✅ NOTIFICATION_SETTINGS RESUCITADA Y NOTIFICACIONES CREADAS - REINICIA LA APP' as resultado;