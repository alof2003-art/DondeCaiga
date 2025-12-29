-- =====================================================
-- CREAR NOTIFICACIONES PARA TODOS LOS USUARIOS
-- =====================================================

-- 1. VERIFICAR TODOS LOS USUARIOS
SELECT 
    'USUARIOS REGISTRADOS' as info,
    COUNT(*) as total_usuarios
FROM public.users_profiles;

-- 2. MOSTRAR TODOS LOS USUARIOS
SELECT 
    'LISTA DE USUARIOS' as info,
    id,
    email,
    nombre,
    created_at
FROM public.users_profiles
ORDER BY created_at DESC;

-- 3. DESHABILITAR RLS EN NOTIFICATIONS
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings DISABLE ROW LEVEL SECURITY;

-- 4. CREAR NOTIFICATION_SETTINGS PARA TODOS LOS USUARIOS
INSERT INTO public.notification_settings (
    user_id, 
    push_notifications_enabled, 
    email_notifications_enabled,
    in_app_notifications_enabled,
    marketing_notifications_enabled
)
SELECT 
    id,
    true,
    true,
    true,
    false
FROM public.users_profiles 
WHERE id NOT IN (
    SELECT user_id 
    FROM public.notification_settings 
    WHERE user_id IS NOT NULL
)
ON CONFLICT (user_id) DO UPDATE SET
    push_notifications_enabled = true,
    email_notifications_enabled = true,
    in_app_notifications_enabled = true,
    updated_at = NOW();

-- 5. CREAR NOTIFICACIONES DE PRUEBA PARA CADA USUARIO
INSERT INTO public.notifications (
    user_id,
    type,
    title,
    message,
    is_read,
    created_at
)
SELECT 
    up.id,
    'general',
    'Bienvenido a las Notificaciones',
    'Hola ' || COALESCE(up.nombre, up.email) || ', tu sistema de notificaciones está funcionando correctamente.',
    false,
    NOW()
FROM public.users_profiles up
WHERE NOT EXISTS (
    SELECT 1 FROM public.notifications n 
    WHERE n.user_id = up.id 
    AND n.title = 'Bienvenido a las Notificaciones'
);

-- 6. CREAR NOTIFICACIÓN DE MENSAJE PARA CADA USUARIO
INSERT INTO public.notifications (
    user_id,
    type,
    title,
    message,
    is_read,
    created_at
)
SELECT 
    up.id,
    'nuevo_mensaje',
    'Nuevo Mensaje de Prueba',
    'Tienes un nuevo mensaje en el chat - Prueba del sistema',
    false,
    NOW() - INTERVAL '1 hour'
FROM public.users_profiles up
WHERE NOT EXISTS (
    SELECT 1 FROM public.notifications n 
    WHERE n.user_id = up.id 
    AND n.title = 'Nuevo Mensaje de Prueba'
);

-- 7. CREAR NOTIFICACIÓN DE RESERVA PARA CADA USUARIO
INSERT INTO public.notifications (
    user_id,
    type,
    title,
    message,
    is_read,
    created_at
)
SELECT 
    up.id,
    'reserva_aceptada',
    'Reserva Confirmada',
    'Tu reserva ha sido confirmada - Sistema de notificaciones activo',
    false,
    NOW() - INTERVAL '2 hours'
FROM public.users_profiles up
WHERE NOT EXISTS (
    SELECT 1 FROM public.notifications n 
    WHERE n.user_id = up.id 
    AND n.title = 'Reserva Confirmada'
);

-- 8. CREAR POLÍTICAS PERMISIVAS
CREATE POLICY "Allow all operations on notifications" 
ON public.notifications 
FOR ALL 
USING (true) 
WITH CHECK (true);

CREATE POLICY "Allow all operations on notification_settings" 
ON public.notification_settings 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- 9. REACTIVAR RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

-- 10. VERIFICAR NOTIFICACIONES CREADAS POR USUARIO
SELECT 
    'NOTIFICACIONES POR USUARIO' as info,
    up.email,
    up.nombre,
    COUNT(n.id) as total_notificaciones,
    COUNT(CASE WHEN n.is_read = false THEN 1 END) as no_leidas
FROM public.users_profiles up
LEFT JOIN public.notifications n ON up.id = n.user_id
GROUP BY up.id, up.email, up.nombre
ORDER BY up.email;

-- 11. MOSTRAR ÚLTIMAS NOTIFICACIONES DE CADA USUARIO
SELECT 
    'ÚLTIMAS NOTIFICACIONES' as info,
    up.email as usuario,
    n.type,
    n.title,
    n.message,
    n.is_read,
    n.created_at
FROM public.notifications n
JOIN public.users_profiles up ON n.user_id = up.id
ORDER BY up.email, n.created_at DESC;

-- 12. ESTADÍSTICAS FINALES
SELECT 
    'ESTADÍSTICAS FINALES' as info,
    (SELECT COUNT(*) FROM public.users_profiles) as total_usuarios,
    (SELECT COUNT(*) FROM public.notifications) as total_notificaciones,
    (SELECT COUNT(*) FROM public.notification_settings) as usuarios_con_settings,
    (SELECT COUNT(*) FROM public.notifications WHERE is_read = false) as notificaciones_no_leidas
;

SELECT '🎉 NOTIFICACIONES CREADAS PARA TODOS LOS USUARIOS' as resultado;
SELECT 'Cada usuario tiene sus propias notificaciones de prueba' as info;