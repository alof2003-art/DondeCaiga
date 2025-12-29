-- =====================================================
-- ARREGLAR NOTIFICACIONES SIMPLE - SIN ERRORES SQL
-- =====================================================

-- 1. VERIFICAR TABLAS EXISTENTES
SELECT 'VERIFICANDO TABLAS' as info, table_name
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('notifications', 'notification_settings', 'users_profiles', 'mensajes')
ORDER BY table_name;

-- 2. DESHABILITAR RLS TEMPORALMENTE
ALTER TABLE public.users_profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.mensajes DISABLE ROW LEVEL SECURITY;

-- 3. ELIMINAR POLÍTICAS EXISTENTES
DROP POLICY IF EXISTS "Allow all operations on users_profiles" ON public.users_profiles;
DROP POLICY IF EXISTS "Allow all operations on notifications" ON public.notifications;
DROP POLICY IF EXISTS "Allow all operations on notification_settings" ON public.notification_settings;
DROP POLICY IF EXISTS "Users can view messages" ON public.mensajes;
DROP POLICY IF EXISTS "Users can create messages" ON public.mensajes;
DROP POLICY IF EXISTS "Simple policy for mensajes" ON public.mensajes;

-- 4. CREAR POLÍTICAS SÚPER PERMISIVAS
CREATE POLICY "Allow all operations on users_profiles" 
ON public.users_profiles 
FOR ALL 
USING (true) 
WITH CHECK (true);

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

-- 5. REACTIVAR RLS
ALTER TABLE public.users_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings ENABLE ROW LEVEL SECURITY;

-- 6. ASEGURAR NOTIFICATION_SETTINGS PARA TODOS LOS USUARIOS
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

-- 7. CREAR NOTIFICACIONES DE PRUEBA PARA VERIFICAR LA CAMPANA
INSERT INTO public.notifications (
    user_id,
    type,
    title,
    message,
    metadata,
    is_read,
    created_at
) VALUES 
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    'general',
    'Prueba de Notificación 1',
    'Esta es una notificación de prueba para verificar que aparece en la campana',
    '{"test": true, "source": "sql_manual"}',
    false,
    NOW()
),
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    'nuevo_mensaje',
    'Mensaje de Prueba',
    'Tienes un nuevo mensaje en el chat',
    '{"test": true, "source": "sql_manual", "chat_id": "test"}',
    false,
    NOW() - INTERVAL '1 hour'
),
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    'reserva_aceptada',
    'Reserva Aceptada',
    'Tu reserva ha sido aceptada por el anfitrión',
    '{"test": true, "source": "sql_manual", "reserva_id": "test"}',
    false,
    NOW() - INTERVAL '2 hours'
);

-- 8. VERIFICAR QUE SE CREARON LAS NOTIFICACIONES
SELECT 
    'NOTIFICACIONES CREADAS' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN is_read = false THEN 1 END) as no_leidas
FROM public.notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3';

-- 9. MOSTRAR LAS NOTIFICACIONES CREADAS
SELECT 
    'ÚLTIMAS NOTIFICACIONES' as info,
    type,
    title,
    message,
    is_read,
    created_at
FROM public.notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'
ORDER BY created_at DESC
LIMIT 5;

-- 10. VERIFICAR CONFIGURACIÓN DE NOTIFICATION_SETTINGS
SELECT 
    'CONFIGURACIÓN NOTIFICACIONES' as info,
    user_id,
    push_notifications_enabled,
    email_notifications_enabled,
    in_app_notifications_enabled
FROM public.notification_settings 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3';

SELECT '✅ NOTIFICACIONES DE PRUEBA CREADAS - REVISA LA CAMPANA EN LA APP' as resultado;