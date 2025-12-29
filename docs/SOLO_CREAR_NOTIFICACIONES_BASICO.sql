-- =====================================================
-- SOLO CREAR NOTIFICACIONES BÁSICO - SIN POLÍTICAS
-- =====================================================

-- 1. VER USUARIOS EXISTENTES
SELECT email, id FROM public.users_profiles ORDER BY email;

-- 2. DESHABILITAR RLS COMPLETAMENTE
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;

-- 3. LIMPIAR NOTIFICACIONES ANTERIORES
DELETE FROM public.notifications WHERE message LIKE '%prueba%';

-- 4. CREAR NOTIFICACIONES PARA CADA USUARIO - MÉTODO MANUAL
-- (Reemplaza los IDs con los IDs reales de tus usuarios)

-- Para el primer usuario (reemplaza con ID real)
INSERT INTO public.notifications (user_id, type, title, message, is_read, created_at)
VALUES 
('0dc7b2bc-04c7-430e-8725-19f6cdb55ee3', 'general', 'Notificación 1', 'Primera notificación de prueba', false, NOW()),
('0dc7b2bc-04c7-430e-8725-19f6cdb55ee3', 'nuevo_mensaje', 'Notificación 2', 'Segunda notificación de prueba', false, NOW() - INTERVAL '1 hour'),
('0dc7b2bc-04c7-430e-8725-19f6cdb55ee3', 'reserva_aceptada', 'Notificación 3', 'Tercera notificación de prueba', false, NOW() - INTERVAL '2 hours');

-- 5. SI TIENES MÁS USUARIOS, AGREGA MÁS INSERTS AQUÍ
-- Ejemplo para un segundo usuario (reemplaza 'SEGUNDO_USER_ID' con el ID real):
-- INSERT INTO public.notifications (user_id, type, title, message, is_read, created_at)
-- VALUES 
-- ('SEGUNDO_USER_ID', 'general', 'Notificación Usuario 2', 'Notificación para segundo usuario', false, NOW());

-- 6. VERIFICAR QUE SE CREARON
SELECT 
    'NOTIFICACIONES CREADAS' as info,
    COUNT(*) as total
FROM public.notifications;

-- 7. VER NOTIFICACIONES POR USUARIO
SELECT 
    up.email,
    COUNT(n.id) as notificaciones
FROM public.users_profiles up
LEFT JOIN public.notifications n ON up.id = n.user_id
GROUP BY up.email, up.id
ORDER BY up.email;

SELECT '✅ NOTIFICACIONES BÁSICAS CREADAS' as resultado;