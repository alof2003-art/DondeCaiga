-- =====================================================
-- CREAR NOTIFICACIÓN DE PRUEBA AHORA
-- =====================================================

-- 1. Crear una notificación de prueba usando la función
SELECT crear_notificacion_prueba_final(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    '🎉 Notificación Nueva',
    'Esta notificación se creó justo ahora para probar el sistema'
) as nueva_notificacion_id;

-- 2. Crear otra notificación directamente
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    metadata,
    is_read,
    created_at
) VALUES (
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    '🔔 Sistema Funcionando',
    'Las notificaciones están llegando correctamente a tu app',
    'general',
    '{"origen": "prueba_manual", "timestamp": "' || NOW() || '"}'::jsonb,
    FALSE,
    NOW()
);

-- 3. Verificar que se crearon
SELECT 
    'NOTIFICACIONES CREADAS' as status,
    COUNT(*) as total_notificaciones,
    MAX(created_at) as ultima_creada
FROM notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 4. Mostrar las últimas 5 notificaciones
SELECT 
    id,
    title,
    message,
    type,
    is_read,
    created_at,
    metadata
FROM notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
ORDER BY created_at DESC 
LIMIT 5;

-- 5. Mensaje de confirmación
SELECT '✅ NOTIFICACIONES DE PRUEBA CREADAS - REVISA TU APP' as resultado;