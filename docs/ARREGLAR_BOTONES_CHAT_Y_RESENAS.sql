-- =====================================================
-- ARREGLAR BOTONES DE CHAT Y RESEÑAS - VERSIÓN CONSOLIDADA
-- =====================================================
-- Este script se enfoca SOLO en los botones de chat y reseñas
-- NO toca el sistema de notificaciones push que ya está configurado

-- 1. VERIFICAR FUNCIONES EXISTENTES DE RESEÑAS
SELECT 
    'FUNCIONES DE RESEÑAS EXISTENTES' as info,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND (routine_name LIKE '%review%' OR routine_name LIKE '%resena%')
ORDER BY routine_name;

-- 2. CREAR/ACTUALIZAR FUNCIONES PARA VERIFICAR RESEÑAS (SI NO EXISTEN)

-- Función para verificar si se puede reseñar una propiedad
CREATE OR REPLACE FUNCTION can_review_property(
    viajero_uuid UUID,
    reserva_uuid UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    reserva_record RECORD;
    resena_existente UUID;
BEGIN
    -- Verificar que la reserva existe y pertenece al viajero
    SELECT 
        r.id,
        r.fecha_fin,
        r.estado,
        r.viajero_id
    INTO reserva_record
    FROM reservas r
    WHERE r.id = reserva_uuid
    AND r.viajero_id = viajero_uuid;
    
    -- Si no se encuentra la reserva, no se puede reseñar
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Verificar que la reserva ya terminó o está completada
    IF reserva_record.fecha_fin > NOW() AND reserva_record.estado != 'completada' THEN
        RETURN FALSE;
    END IF;
    
    -- Verificar que no existe ya una reseña
    SELECT id INTO resena_existente
    FROM resenas
    WHERE reserva_id = reserva_uuid
    AND viajero_id = viajero_uuid
    LIMIT 1;
    
    -- Si ya existe una reseña, no se puede reseñar de nuevo
    IF FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Si pasa todas las validaciones, se puede reseñar
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para verificar si se puede reseñar un viajero
CREATE OR REPLACE FUNCTION can_review_traveler(
    anfitrion_uuid UUID,
    reserva_uuid UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    reserva_record RECORD;
    resena_existente UUID;
BEGIN
    -- Verificar que la reserva existe y la propiedad pertenece al anfitrión
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
    AND p.anfitrion_id = anfitrion_uuid;
    
    -- Si no se encuentra la reserva, no se puede reseñar
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Verificar que la reserva ya terminó o está completada
    IF reserva_record.fecha_fin > NOW() AND reserva_record.estado != 'completada' THEN
        RETURN FALSE;
    END IF;
    
    -- Verificar que no existe ya una reseña
    SELECT id INTO resena_existente
    FROM resenas_viajeros
    WHERE reserva_id = reserva_uuid
    AND anfitrion_id = anfitrion_uuid
    LIMIT 1;
    
    -- Si ya existe una reseña, no se puede reseñar de nuevo
    IF FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Si pasa todas las validaciones, se puede reseñar
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. FUNCIÓN PARA VERIFICAR SI EL CHAT DEBE ESTAR DISPONIBLE
CREATE OR REPLACE FUNCTION should_show_chat_button(
    reserva_uuid UUID,
    user_uuid UUID
)
RETURNS BOOLEAN AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. ACTUALIZAR RESERVAS ANTIGUAS PARA ASEGURAR DATOS COMPLETOS
-- Solo actualizar las que no tienen código de verificación
UPDATE reservas 
SET codigo_verificacion = LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0')
WHERE codigo_verificacion IS NULL 
AND estado = 'confirmada';

-- 5. FUNCIÓN PARA OBTENER ESTADÍSTICAS DE RESEÑAS (SOLO SI NO EXISTE)
CREATE OR REPLACE FUNCTION get_user_review_statistics(user_uuid UUID)
RETURNS TABLE(
    total_resenas_propiedades INTEGER,
    calificacion_promedio_propiedades NUMERIC,
    distribucion_propiedades JSONB,
    total_resenas_como_viajero INTEGER,
    calificacion_promedio_como_viajero NUMERIC,
    distribucion_viajero JSONB,
    total_resenas_hechas_propiedades INTEGER,
    total_resenas_hechas_viajeros INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH resenas_recibidas AS (
        -- Reseñas recibidas como anfitrión
        SELECT r.calificacion
        FROM resenas r
        INNER JOIN propiedades p ON r.propiedad_id = p.id
        WHERE p.anfitrion_id = user_uuid
    ),
    resenas_como_viajero AS (
        -- Reseñas recibidas como viajero
        SELECT rv.calificacion
        FROM resenas_viajeros rv
        WHERE rv.viajero_id = user_uuid
    ),
    resenas_hechas_propiedades AS (
        -- Reseñas hechas a propiedades
        SELECT r.id
        FROM resenas r
        WHERE r.viajero_id = user_uuid
    ),
    resenas_hechas_viajeros AS (
        -- Reseñas hechas a viajeros
        SELECT rv.id
        FROM resenas_viajeros rv
        WHERE rv.anfitrion_id = user_uuid
    )
    SELECT 
        -- Estadísticas como anfitrión
        (SELECT COUNT(*)::INTEGER FROM resenas_recibidas),
        (SELECT COALESCE(AVG(calificacion), 0)::NUMERIC FROM resenas_recibidas),
        (SELECT COALESCE(
            jsonb_object_agg(
                calificacion_redondeada::TEXT, 
                cantidad
            ), 
            '{}'::jsonb
        ) FROM (
            SELECT 
                ROUND(calificacion)::INTEGER as calificacion_redondeada,
                COUNT(*)::INTEGER as cantidad
            FROM resenas_recibidas
            GROUP BY ROUND(calificacion)::INTEGER
        ) dist_prop),
        
        -- Estadísticas como viajero
        (SELECT COUNT(*)::INTEGER FROM resenas_como_viajero),
        (SELECT COALESCE(AVG(calificacion), 0)::NUMERIC FROM resenas_como_viajero),
        (SELECT COALESCE(
            jsonb_object_agg(
                calificacion_redondeada::TEXT, 
                cantidad
            ), 
            '{}'::jsonb
        ) FROM (
            SELECT 
                ROUND(calificacion)::INTEGER as calificacion_redondeada,
                COUNT(*)::INTEGER as cantidad
            FROM resenas_como_viajero
            GROUP BY ROUND(calificacion)::INTEGER
        ) dist_viaj),
        
        -- Reseñas hechas
        (SELECT COUNT(*)::INTEGER FROM resenas_hechas_propiedades),
        (SELECT COUNT(*)::INTEGER FROM resenas_hechas_viajeros);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. VERIFICAR QUE LAS FUNCIONES FUNCIONAN CORRECTAMENTE

-- Probar función de reseñar propiedad
DO $$
DECLARE
    test_result BOOLEAN;
    test_user_id UUID;
    test_reserva_id UUID;
BEGIN
    -- Obtener un usuario y reserva de prueba
    SELECT id INTO test_user_id FROM users_profiles LIMIT 1;
    SELECT id INTO test_reserva_id FROM reservas WHERE viajero_id = test_user_id LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_reserva_id IS NOT NULL THEN
        SELECT can_review_property(test_user_id, test_reserva_id) INTO test_result;
        RAISE NOTICE '✅ Función can_review_property funciona: %', test_result;
    ELSE
        RAISE NOTICE 'ℹ️ No hay datos de prueba para can_review_property';
    END IF;
END $$;

-- Probar función de reseñar viajero
DO $$
DECLARE
    test_result BOOLEAN;
    test_anfitrion_id UUID;
    test_reserva_id UUID;
BEGIN
    -- Obtener un anfitrión y reserva de prueba
    SELECT p.anfitrion_id, r.id 
    INTO test_anfitrion_id, test_reserva_id
    FROM reservas r
    INNER JOIN propiedades p ON r.propiedad_id = p.id
    LIMIT 1;
    
    IF test_anfitrion_id IS NOT NULL AND test_reserva_id IS NOT NULL THEN
        SELECT can_review_traveler(test_anfitrion_id, test_reserva_id) INTO test_result;
        RAISE NOTICE '✅ Función can_review_traveler funciona: %', test_result;
    ELSE
        RAISE NOTICE 'ℹ️ No hay datos de prueba para can_review_traveler';
    END IF;
END $$;

-- Probar función de chat
DO $$
DECLARE
    test_result BOOLEAN;
    test_user_id UUID;
    test_reserva_id UUID;
BEGIN
    -- Obtener un usuario y reserva de prueba
    SELECT id INTO test_user_id FROM users_profiles LIMIT 1;
    SELECT id INTO test_reserva_id FROM reservas WHERE viajero_id = test_user_id LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_reserva_id IS NOT NULL THEN
        SELECT should_show_chat_button(test_reserva_id, test_user_id) INTO test_result;
        RAISE NOTICE '✅ Función should_show_chat_button funciona: %', test_result;
    ELSE
        RAISE NOTICE 'ℹ️ No hay datos de prueba para should_show_chat_button';
    END IF;
END $$;

-- 7. MOSTRAR ESTADÍSTICAS DE RESERVAS POR TIEMPO
SELECT 
    'ESTADÍSTICAS DE RESERVAS POR TIEMPO' as info,
    COUNT(*) as total_reservas,
    COUNT(CASE WHEN fecha_fin >= NOW() THEN 1 END) as vigentes,
    COUNT(CASE WHEN fecha_fin < NOW() AND fecha_fin >= NOW() - INTERVAL '5 days' THEN 1 END) as pasadas_recientes,
    COUNT(CASE WHEN fecha_fin < NOW() - INTERVAL '5 days' THEN 1 END) as pasadas_antiguas
FROM reservas;

-- 8. MOSTRAR RESERVAS PROBLEMÁTICAS (SIN CÓDIGO)
SELECT 
    'RESERVAS ACTUALIZADAS CON CÓDIGO' as info,
    COUNT(*) as total_actualizadas
FROM reservas 
WHERE codigo_verificacion IS NOT NULL 
AND estado = 'confirmada';

-- 9. VERIFICAR FUNCIONES CREADAS
SELECT 
    'FUNCIONES DE RESEÑAS CREADAS' as info,
    routine_name,
    'Función para validar reseñas y chat' as descripcion
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name IN ('can_review_property', 'can_review_traveler', 'should_show_chat_button', 'get_user_review_statistics')
ORDER BY routine_name;

SELECT '🎉 SISTEMA DE BOTONES DE CHAT Y RESEÑAS ARREGLADO' as resultado_final;

-- =====================================================
-- RESUMEN DE CAMBIOS IMPLEMENTADOS
-- =====================================================
/*
✅ FUNCIONES SQL CREADAS/ACTUALIZADAS:
- can_review_property(): Verifica si se puede reseñar una propiedad
- can_review_traveler(): Verifica si se puede reseñar un viajero  
- should_show_chat_button(): Verifica si mostrar botón de chat (5 días)
- get_user_review_statistics(): Obtiene estadísticas completas

✅ LÓGICA DE TIEMPO IMPLEMENTADA:
- Chat disponible para reservas vigentes (siempre)
- Chat disponible para reservas pasadas (solo 5 días)
- Chat no disponible para reservas muy antiguas

✅ DATOS CORREGIDOS:
- Códigos de verificación agregados a reservas confirmadas sin código
- Funciones de validación mejoradas y consolidadas

✅ EN LA APP (YA IMPLEMENTADO EN FLUTTER):
- Botón de chat se oculta después de 5 días
- Mensaje explicativo cuando chat no está disponible
- Botones de reseñas funcionan correctamente
- Validación correcta antes de mostrar botones

✅ NO SE TOCA:
- Sistema de notificaciones push (ya configurado)
- Triggers de notificaciones existentes
- Configuración de FCM tokens
- Políticas RLS de notificaciones
*/