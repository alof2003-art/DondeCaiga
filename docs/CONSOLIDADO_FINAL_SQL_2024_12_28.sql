-- =====================================================
-- CONSOLIDADO FINAL SQL - DONDE CAIGA
-- Fecha: 28 de Diciembre 2024
-- =====================================================
-- Este archivo consolida SOLO lo que realmente falta
-- basándose en la revisión exhaustiva de TODOS los archivos

-- =====================================================
-- VERIFICACIÓN DE LO QUE YA EXISTE
-- =====================================================

SELECT 'VERIFICANDO ESTADO ACTUAL DEL SISTEMA' as info;

-- 1. Verificar códigos de verificación (YA IMPLEMENTADO)
SELECT 
    'CÓDIGOS DE VERIFICACIÓN' as sistema,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'reservas' AND column_name = 'codigo_verificacion'
        ) THEN '✅ Campo existe'
        ELSE '❌ Campo NO existe'
    END as campo_estado,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'generar_codigo_verificacion'
        ) THEN '✅ Función existe'
        ELSE '❌ Función NO existe'
    END as funcion_estado,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE trigger_name = 'trigger_asignar_codigo_verificacion'
        ) THEN '✅ Trigger existe'
        ELSE '❌ Trigger NO existe'
    END as trigger_estado;

-- 2. Verificar funciones de reseñas (YA IMPLEMENTADAS)
SELECT 
    'FUNCIONES DE RESEÑAS' as sistema,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'can_review_property'
        ) THEN '✅ can_review_property existe'
        ELSE '❌ can_review_property NO existe'
    END as property_estado,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'can_review_traveler'
        ) THEN '✅ can_review_traveler existe'
        ELSE '❌ can_review_traveler NO existe'
    END as traveler_estado;

-- 3. Verificar sistema de notificaciones (YA IMPLEMENTADO)
SELECT 
    'SISTEMA DE NOTIFICACIONES' as sistema,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'notifications'
        ) THEN '✅ Tabla notifications existe'
        ELSE '❌ Tabla notifications NO existe'
    END as tabla_estado,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'users_profiles' AND column_name = 'fcm_token'
        ) THEN '✅ FCM token existe'
        ELSE '❌ FCM token NO existe'
    END as fcm_estado;

-- 4. Verificar sistema de chat (YA IMPLEMENTADO)
SELECT 
    'SISTEMA DE CHAT' as sistema,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'mensajes'
        ) THEN '✅ Tabla mensajes existe'
        ELSE '❌ Tabla mensajes NO existe'
    END as tabla_estado,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name LIKE '%mensaje%'
        ) THEN '✅ Funciones de chat existen'
        ELSE '❌ Funciones de chat NO existen'
    END as funciones_estado;

-- =====================================================
-- LO ÚNICO QUE REALMENTE FALTA: FUNCIÓN DE 5 DÍAS
-- =====================================================

-- Verificar si ya existe la función de 5 días
SELECT 
    'FUNCIÓN DE 5 DÍAS PARA CHAT' as verificacion,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'should_show_chat_button'
        ) THEN '✅ Ya existe - NO necesita crearse'
        ELSE '❌ NO existe - NECESITA crearse'
    END as estado;

-- Solo crear si NO existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'should_show_chat_button'
    ) THEN
        -- Crear la función de 5 días
        EXECUTE '
        CREATE OR REPLACE FUNCTION should_show_chat_button(
            reserva_uuid UUID,
            user_uuid UUID
        )
        RETURNS BOOLEAN AS $func$
        DECLARE
            reserva_record RECORD;
            dias_transcurridos INTEGER;
        BEGIN
            -- Obtener información de la reserva
            SELECT 
                r.id,
                r.fecha_fin,
                r.estado,
                r.viajero_id,
                p.anfitrion_id
            INTO reserva_record
            FROM reservas r
            INNER JOIN propiedades p ON r.propiedad_id = p.id
            WHERE r.id = reserva_uuid
            AND (r.viajero_id = user_uuid OR p.anfitrion_id = user_uuid);
            
            -- Si no se encuentra la reserva o el usuario no es parte de ella
            IF NOT FOUND THEN
                RETURN FALSE;
            END IF;
            
            -- Si la reserva está vigente (no ha terminado), siempre mostrar chat
            IF reserva_record.fecha_fin >= NOW() THEN
                RETURN TRUE;
            END IF;
            
            -- Para reservas pasadas, calcular días transcurridos
            dias_transcurridos := EXTRACT(DAY FROM NOW() - reserva_record.fecha_fin);
            
            -- Mostrar chat solo si han pasado menos de 5 días
            RETURN dias_transcurridos < 5;
        END;
        $func$ LANGUAGE plpgsql SECURITY DEFINER;
        ';
        
        RAISE NOTICE '✅ Función should_show_chat_button creada exitosamente';
    ELSE
        RAISE NOTICE 'ℹ️ Función should_show_chat_button ya existe, no se creó';
    END IF;
END $$;

-- Agregar comentario a la función
COMMENT ON FUNCTION should_show_chat_button(UUID, UUID) IS 'Verifica si mostrar botón de chat: siempre para vigentes, solo 5 días para pasadas';

-- =====================================================
-- VERIFICACIÓN FINAL
-- =====================================================

-- Mostrar estadísticas de reservas por tiempo
SELECT 
    'ESTADÍSTICAS DE RESERVAS POR TIEMPO' as info,
    COUNT(*) as total_reservas,
    COUNT(CASE WHEN fecha_fin >= NOW() THEN 1 END) as vigentes_chat_siempre,
    COUNT(CASE WHEN fecha_fin < NOW() AND fecha_fin >= NOW() - INTERVAL '5 days' THEN 1 END) as pasadas_recientes_chat_5_dias,
    COUNT(CASE WHEN fecha_fin < NOW() - INTERVAL '5 days' THEN 1 END) as pasadas_antiguas_sin_chat
FROM reservas;

-- Verificar que todas las funciones necesarias existen
SELECT 
    'FUNCIONES NECESARIAS PARA BOTONES' as verificacion,
    COUNT(CASE WHEN routine_name = 'can_review_property' THEN 1 END) as can_review_property,
    COUNT(CASE WHEN routine_name = 'can_review_traveler' THEN 1 END) as can_review_traveler,
    COUNT(CASE WHEN routine_name = 'should_show_chat_button' THEN 1 END) as should_show_chat_button,
    COUNT(CASE WHEN routine_name = 'generar_codigo_verificacion' THEN 1 END) as generar_codigo
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('can_review_property', 'can_review_traveler', 'should_show_chat_button', 'generar_codigo_verificacion');

-- Prueba rápida de la función (si existe)
DO $$
DECLARE
    test_result BOOLEAN;
    test_user_id UUID;
    test_reserva_id UUID;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'should_show_chat_button') THEN
        -- Obtener datos de prueba
        SELECT id INTO test_user_id FROM users_profiles LIMIT 1;
        SELECT id INTO test_reserva_id FROM reservas WHERE viajero_id = test_user_id LIMIT 1;
        
        IF test_user_id IS NOT NULL AND test_reserva_id IS NOT NULL THEN
            SELECT should_show_chat_button(test_reserva_id, test_user_id) INTO test_result;
            RAISE NOTICE '✅ Función should_show_chat_button probada: %', test_result;
        ELSE
            RAISE NOTICE 'ℹ️ No hay datos de prueba disponibles';
        END IF;
    ELSE
        RAISE NOTICE '❌ Función should_show_chat_button no existe';
    END IF;
END $$;

-- =====================================================
-- RESULTADO FINAL
-- =====================================================

SELECT '🎉 CONSOLIDACIÓN COMPLETADA - SOLO SE AGREGÓ LO NECESARIO' as resultado_final;

-- =====================================================
-- RESUMEN DE LO QUE HACE ESTE SCRIPT
-- =====================================================
/*
✅ VERIFICACIONES REALIZADAS:
- Códigos de verificación (YA IMPLEMENTADOS)
- Funciones de reseñas (YA IMPLEMENTADAS)
- Sistema de notificaciones (YA IMPLEMENTADO)
- Sistema de chat (YA IMPLEMENTADO)

✅ LO ÚNICO AGREGADO:
- should_show_chat_button(): Función para lógica de 5 días
- Solo se crea si NO existe previamente

✅ LÓGICA DE 5 DÍAS:
- Reservas vigentes → Chat siempre disponible
- Reservas pasadas < 5 días → Chat disponible
- Reservas pasadas ≥ 5 días → Chat NO disponible

✅ NO SE DUPLICA NADA:
- No toca códigos de verificación existentes
- No toca funciones de reseñas existentes
- No toca sistema de notificaciones
- No toca triggers existentes

✅ RESULTADO:
- Flutter ya tiene la lógica implementada
- Solo faltaba esta función SQL
- Ahora el botón de chat se oculta después de 5 días
- Aparece mensaje "Chat no disponible" para reservas antiguas
*/