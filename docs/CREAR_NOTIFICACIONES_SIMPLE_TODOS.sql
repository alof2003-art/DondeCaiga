-- =====================================================
-- CREAR NOTIFICACIONES SIMPLE PARA TODOS - SIN ERRORES
-- =====================================================

-- 1. VERIFICAR USUARIOS EXISTENTES
SELECT 
    'USUARIOS REGISTRADOS' as info,
    COUNT(*) as total_usuarios
FROM public.users_profiles;

-- 2. MOSTRAR USUARIOS
SELECT 
    'LISTA DE USUARIOS' as info,
    id,
    email,
    nombre
FROM public.users_profiles
ORDER BY email;

-- 3. DESHABILITAR RLS TEMPORALMENTE
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings DISABLE ROW LEVEL SECURITY;

-- 4. ELIMINAR POLÍTICAS EXISTENTES PARA EVITAR CONFLICTOS
DROP POLICY IF EXISTS "Allow all operations on notifications" ON public.notifications;
DROP POLICY IF EXISTS "Allow all operations on notification_settings" ON public.notification_settings;

-- 5. CREAR NOTIFICATION_SETTINGS PARA TODOS LOS USUARIOS
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

-- 6. LIMPIAR NOTIFICACIONES DE PRUEBA ANTERIORES
DELETE FROM public.notifications 
WHERE message LIKE '%prueba%' OR message LIKE '%Prueba%' OR message LIKE '%test%';

-- 7. CREAR UNA NOTIFICACIÓN PARA CADA USUARIO
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
    'Sistema de Notificaciones Activo',
    'Hola ' || COALESCE(up.nombre, up.email) || ', tu sistema de notificaciones funciona correctamente.',
    false,
    NOW()
FROM public.users_profiles up;

-- 8. CREAR SEGUNDA NOTIFICACIÓN PARA CADA USUARIO
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
    'Notificación de Mensaje',
    'Ejemplo de notificación de mensaje para ' || COALESCE(up.nombre, up.email),
    false,
    NOW() - INTERVAL '1 hour'
FROM public.users_profiles up;

-- 9. CREAR TERCERA NOTIFICACIÓN PARA CADA USUARIO
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
    'Notificación de Reserva',
    'Ejemplo de notificación de reserva para ' || COALESCE(up.nombre, up.email),
    false,
    NOW() - INTERVAL '2 hours'
FROM public.users_profiles up;

-- 10. CREAR POLÍTICAS NUEVAS
CREATE POLICY "notifications_policy_all" 
ON public.notifications 
FOR ALL 
USING (true) 
WITH CHECK (true);

CREATE POLICY "notification_settings_policy_all" 
ON public.notification_settings 
FOR ALL 
USING (true) 
WITH CHECK (true);

-- 11. REACTIVAR RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

-- 12. VERIFICAR RESULTADOS
SELECT 
    'NOTIFICACIONES POR USUARIO' as info,
    up.email,
    COUNT(n.id) as total_notificaciones,
    COUNT(CASE WHEN n.is_read = false THEN 1 END) as no_leidas
FROM public.users_profiles up
LEFT JOIN public.notifications n ON up.id = n.user_id
GROUP BY up.id, up.email
ORDER BY up.email;

-- 13. MOSTRAR ALGUNAS NOTIFICACIONES CREADAS
SELECT 
    'NOTIFICACIONES CREADAS' as info,
    up.email as usuario,
    n.title,
    n.type,
    n.created_at
FROM public.notifications n
JOIN public.users_profiles up ON n.user_id = up.id
ORDER BY up.email, n.created_at DESC
LIMIT 10;

-- 14. ESTADÍSTICAS FINALES
SELECT 
    'ESTADÍSTICAS' as info,
    (SELECT COUNT(*) FROM public.users_profiles) as total_usuarios,
    (SELECT COUNT(*) FROM public.notifications) as total_notificaciones,
    (SELECT COUNT(*) FROM public.notification_settings) as usuarios_con_settings;

SELECT '✅ NOTIFICACIONES CREADAS PARA TODOS LOS USUARIOS' as resultado;