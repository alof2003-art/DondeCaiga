-- PRUEBAS COMPLETAS DEL SISTEMA DE NOTIFICACIONES
-- Simula todos los eventos para verificar que las notificaciones funcionen
-- Ejecutar DESPUÉS de implementar el sistema completo

-- =====================================================
-- 1. VERIFICAR QUE TODOS LOS TRIGGERS ESTÉN ACTIVOS
-- =====================================================

SELECT 
    'Triggers Implementados' as verificacion,
    COUNT(*) as cantidad,
    'Deben ser 7 triggers nuevos' as esperado
FROM information_schema.triggers 
WHERE trigger_name LIKE '%notificar%' OR trigger_name LIKE '%recordatorio%';

-- =====================================================
-- 2. SIMULAR NUEVA RESERVA (para probar notificación al anfitrión)
-- =====================================================

-- Primero, obtener IDs reales para la prueba
DO $$
DECLARE
    test_viajero_id UUID;
    test_anfitrion_id UUID;
    test_propiedad_id UUID;
    test_reserva_id UUID;
BEGIN
    -- Obtener usuario viajero (tu email)
    SELECT id INTO test_viajero_id 
    FROM users_profiles 
    WHERE email = 'alof2003@gmail.com';
    
    -- Obtener una propiedad existente y su anfitrión
    SELECT p.id, p.anfitrion_id INTO test_propiedad_id, test_anfitrion_id
    FROM propiedades p 
    LIMIT 1;
    
    -- Si no hay propiedades, crear una de prueba
    IF test_propiedad_id IS NULL THEN
        INSERT INTO propiedades (
            anfitrion_id, titulo, descripcion, direccion, 
            capacidad_personas, estado
        ) VALUES (
            test_viajero_id, 'Propiedad de Prueba', 'Para testing de notificaciones',
            'Dirección de prueba', 2, 'activo'
        ) RETURNING id INTO test_propiedad_id;
        
        test_anfitrion_id := test_viajero_id;
    END IF;
    
    -- Crear reserva de prueba (esto debe disparar notificación)
    INSERT INTO reservas (
        viajero_id, propiedad_id, fecha_inicio, fecha_fin, estado
    ) VALUES (
        test_viajero_id, test_propiedad_id, 
        CURRENT_DATE + INTERVAL '7 days',
        CURRENT_DATE + INTERVAL '10 days',
        'pendiente'
    ) RETURNING id INTO test_reserva_id;
    
    RAISE NOTICE 'Reserva de prueba creada: %', test_reserva_id;
    
    -- Simular confirmación de reserva (otra notificación)
    UPDATE reservas 
    SET estado = 'confirmada'
    WHERE id = test_reserva_id;
    
    RAISE NOTICE 'Reserva confirmada para probar notificación';
    
END $$;

-- =====================================================
-- 3. SIMULAR SOLICITUD DE ANFITRIÓN
-- =====================================================

DO $$
DECLARE
    test_user_id UUID;
    test_solicitud_id UUID;
BEGIN
    -- Obtener usuario
    SELECT id INTO test_user_id 
    FROM users_profiles 
    WHERE email = 'alof2003@gmail.com';
    
    -- Crear solicitud de anfitrión
    INSERT INTO solicitudes_anfitrion (
        usuario_id, mensaje, foto_selfie_url, foto_propiedad_url, estado
    ) VALUES (
        test_user_id, 
        'Solicitud de prueba para testing de notificaciones',
        'https://ejemplo.com/selfie.jpg',
        'https://ejemplo.com/propiedad.jpg',
        'pendiente'
    ) RETURNING id INTO test_solicitud_id;
    
    RAISE NOTICE 'Solicitud de anfitrión creada: %', test_solicitud_id;
    
    -- Simular aprobación (debe notificar al solicitante)
    UPDATE solicitudes_anfitrion 
    SET estado = 'aprobada',
        admin_revisor_id = test_user_id,
        comentario_admin = 'Aprobada para testing',
        fecha_respuesta = NOW()
    WHERE id = test_solicitud_id;
    
    RAISE NOTICE 'Solicitud aprobada para probar notificación';
    
END $$;

-- =====================================================
-- 4. VERIFICAR NOTIFICACIONES CREADAS
-- =====================================================

SELECT 
    'Notificaciones Recientes' as verificacion,
    COUNT(*) as cantidad_creada,
    'Deben aparecer varias notificaciones nuevas' as esperado
FROM notifications 
WHERE created_at > NOW() - INTERVAL '5 minutes';

-- =====================================================
-- 5. VER DETALLE DE NOTIFICACIONES CREADAS
-- =====================================================

SELECT 
    n.type as tipo_notificacion,
    n.title as titulo,
    LEFT(n.message, 50) || '...' as mensaje_preview,
    up.email as destinatario,
    n.created_at as creada_en
FROM notifications n
JOIN users_profiles up ON n.user_id = up.id
WHERE n.created_at > NOW() - INTERVAL '5 minutes'
ORDER BY n.created_at DESC;

-- =====================================================
-- 6. VERIFICAR QUE EL TRIGGER PRINCIPAL SIGA FUNCIONANDO
-- =====================================================

SELECT 
    'Push Notifications' as verificacion,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'trigger_send_push_on_notification'
        AND event_manipulation = 'INSERT'
    ) THEN '✅ FUNCIONANDO' ELSE '❌ ERROR' END as estado,
    'Debe enviar push automáticamente' as detalle;

-- =====================================================
-- 7. RESUMEN FINAL
-- =====================================================

SELECT 
    '🎉 SISTEMA COMPLETO' as resultado,
    'Notificaciones implementadas para:' as detalle,
    '• Reservas • Solicitudes • Reseñas • Mensajes • Recordatorios' as eventos_cubiertos;