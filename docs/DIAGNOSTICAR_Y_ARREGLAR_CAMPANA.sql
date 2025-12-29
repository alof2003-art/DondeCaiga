-- =====================================================
-- DIAGNOSTICAR Y ARREGLAR CAMPANA DE NOTIFICACIONES
-- =====================================================

-- 1. VERIFICAR QUE EXISTEN NOTIFICACIONES PARA TU USUARIO
SELECT 
    'NOTIFICACIONES EXISTENTES PARA TU USUARIO' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN is_read = false THEN 1 END) as no_leidas,
    COUNT(CASE WHEN is_read = true THEN 1 END) as leidas
FROM public.notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3';

-- 2. MOSTRAR TODAS LAS NOTIFICACIONES DE TU USUARIO
SELECT 
    'TODAS TUS NOTIFICACIONES' as info,
    id,
    type,
    title,
    message,
    is_read,
    created_at
FROM public.notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'
ORDER BY created_at DESC;

-- 3. VERIFICAR ESTRUCTURA DE LA TABLA NOTIFICATIONS
SELECT 
    'ESTRUCTURA TABLA NOTIFICATIONS' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'notifications' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. VERIFICAR POLÍTICAS RLS EN NOTIFICATIONS
SELECT 
    'POLÍTICAS RLS NOTIFICATIONS' as info,
    policyname,
    cmd as operacion,
    qual as condicion
FROM pg_policies 
WHERE tablename = 'notifications'
ORDER BY policyname;

-- 5. CREAR NOTIFICACIONES DE PRUEBA VARIADAS
INSERT INTO public.notifications (
    user_id,
    type,
    title,
    message,
    metadata,
    is_read,
    created_at
) VALUES 
-- Notificación muy reciente
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    'general',
    '🔔 Notificación de Prueba AHORA',
    'Esta notificación se creó justo ahora para probar la campana',
    '{"test": true, "timestamp": "' || NOW()::text || '"}',
    false,
    NOW()
),
-- Notificación de mensaje
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    'nuevo_mensaje',
    '💬 Nuevo Mensaje',
    'Tienes un nuevo mensaje en el chat',
    '{"test": true, "chat_id": "test_chat"}',
    false,
    NOW() - INTERVAL '5 minutes'
),
-- Notificación de reserva
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    'reserva_aceptada',
    '✅ Reserva Confirmada',
    'Tu reserva ha sido confirmada por el anfitrión',
    '{"test": true, "reserva_id": "test_reserva"}',
    false,
    NOW() - INTERVAL '1 hour'
),
-- Notificación leída (para probar filtros)
(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    'general',
    '📖 Notificación Leída',
    'Esta notificación ya fue leída',
    '{"test": true, "status": "read"}',
    true,
    NOW() - INTERVAL '2 hours'
);

-- 6. VERIFICAR QUE SE CREARON LAS NOTIFICACIONES
SELECT 
    'NOTIFICACIONES DESPUÉS DE INSERTAR' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN is_read = false THEN 1 END) as no_leidas,
    MAX(created_at) as ultima_creada
FROM public.notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3';

-- 7. MOSTRAR LAS ÚLTIMAS 10 NOTIFICACIONES
SELECT 
    'ÚLTIMAS 10 NOTIFICACIONES' as info,
    type,
    title,
    message,
    is_read,
    created_at,
    CASE 
        WHEN created_at > NOW() - INTERVAL '1 hour' THEN '🔥 MUY RECIENTE'
        WHEN created_at > NOW() - INTERVAL '1 day' THEN '⏰ RECIENTE'
        ELSE '📅 ANTIGUA'
    END as antiguedad
FROM public.notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'
ORDER BY created_at DESC
LIMIT 10;

-- 8. VERIFICAR PERMISOS DE LECTURA
SELECT 
    'PRUEBA DE LECTURA DIRECTA' as info,
    COUNT(*) as puede_leer
FROM public.notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3';

-- 9. CREAR FUNCIÓN PARA PROBAR DESDE LA APP
CREATE OR REPLACE FUNCTION crear_notificacion_prueba_campana()
RETURNS TEXT AS $$
BEGIN
    INSERT INTO public.notifications (
        user_id,
        type,
        title,
        message,
        metadata,
        is_read,
        created_at
    ) VALUES (
        '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
        'general',
        '🧪 Prueba desde Función',
        'Notificación creada desde función SQL - ' || NOW()::text,
        '{"test": true, "source": "function", "timestamp": "' || NOW()::text || '"}',
        false,
        NOW()
    );
    
    RETURN '✅ Notificación de prueba creada exitosamente';
END;
$$ LANGUAGE plpgsql;

-- 10. EJECUTAR LA FUNCIÓN DE PRUEBA
SELECT crear_notificacion_prueba_campana() as resultado;

-- 11. ESTADÍSTICAS FINALES
SELECT 
    'ESTADÍSTICAS FINALES' as info,
    COUNT(*) as total_notificaciones,
    COUNT(CASE WHEN is_read = false THEN 1 END) as no_leidas,
    COUNT(CASE WHEN created_at > NOW() - INTERVAL '1 hour' THEN 1 END) as ultima_hora,
    MAX(created_at) as mas_reciente
FROM public.notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3';

SELECT '🎯 DIAGNÓSTICO COMPLETO - AHORA REVISA LA CAMPANA EN LA APP' as resultado;
SELECT 'Si no aparecen notificaciones, el problema está en el código Flutter' as info;
SELECT 'Ejecuta: SELECT * FROM notifications WHERE user_id = ''0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'' ORDER BY created_at DESC;' as query_manual;