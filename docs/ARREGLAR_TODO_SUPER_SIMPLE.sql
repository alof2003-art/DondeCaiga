-- =====================================================
-- ARREGLAR TODO SÚPER SIMPLE - SIN ERRORES
-- =====================================================

-- 1. DESHABILITAR RLS EN TODAS LAS TABLAS
ALTER TABLE public.users_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.mensajes DISABLE ROW LEVEL SECURITY;

-- 2. ELIMINAR FUNCIÓN EXISTENTE SI CAUSA PROBLEMAS
DROP FUNCTION IF EXISTS update_fcm_token(UUID, TEXT);

-- 3. LIMPIAR TOKENS FCM INVÁLIDOS
UPDATE public.users_profiles 
SET fcm_token = NULL 
WHERE fcm_token IS NOT NULL 
AND LENGTH(fcm_token) < 50;

-- 4. CREAR NOTIFICACIONES DE PRUEBA SIMPLES
DELETE FROM public.notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3' 
AND message LIKE '%prueba%';

INSERT INTO public.notifications (
    user_id,
    type,
    title,
    message,
    is_read,
    created_at
) VALUES 
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    'general',
    'Prueba 1',
    'Primera notificación de prueba',
    false,
    NOW()
),
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    'nuevo_mensaje',
    'Prueba 2',
    'Segunda notificación de prueba',
    false,
    NOW() - INTERVAL '1 hour'
),
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    'reserva_aceptada',
    'Prueba 3',
    'Tercera notificación de prueba',
    false,
    NOW() - INTERVAL '2 hours'
);

-- 5. ASEGURAR NOTIFICATION_SETTINGS
INSERT INTO public.notification_settings (
    user_id, 
    push_notifications_enabled, 
    email_notifications_enabled,
    in_app_notifications_enabled
)
SELECT 
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    true,
    true,
    true
WHERE NOT EXISTS (
    SELECT 1 FROM public.notification_settings 
    WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'
);

-- 6. VERIFICAR RESULTADOS
SELECT 
    'NOTIFICACIONES CREADAS' as resultado,
    COUNT(*) as total
FROM public.notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3';

SELECT 
    'ÚLTIMAS NOTIFICACIONES' as info,
    title,
    message,
    created_at
FROM public.notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'
ORDER BY created_at DESC
LIMIT 5;