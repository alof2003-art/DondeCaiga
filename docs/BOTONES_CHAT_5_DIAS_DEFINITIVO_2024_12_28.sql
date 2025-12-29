-- =====================================================
-- BOTONES DE CHAT CON LÓGICA DE 5 DÍAS - DEFINITIVO
-- Fecha: 28 de Diciembre 2024
-- =====================================================
-- SOLO agrega la función que falta para ocultar chat después de 5 días
-- NO toca nada que ya esté implementado (códigos, reseñas, etc.)

-- =====================================================
-- VERIFICAR QUE TODO LO NECESARIO YA EXISTE
-- =====================================================

-- 1. Verificar que códigos de verificación ya existen
SELECT 
    'CÓDIGOS DE VERIFICACIÓN' as verificacion,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'reservas' 
            AND column_name = 'codigo_verificacion'
        ) THEN '✅ Campo codigo_verificacion existe'
        ELSE '❌ Campo codigo_verificacion NO existe'
    END as estado_campo,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'generar_codigo_verificacion'
        ) THEN '✅ Función generar_codigo_verificacion existe'
        ELSE '❌ Función generar_codigo_verificacion NO existe'
    END as estado_funcion;

-- 2. Verificar que funciones de reseñas ya existen
SELECT 
    'FUNCIONES DE RESEÑAS' as verificacion,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'can_review_property'
        ) THEN '✅ Función can_review_property existe'
        ELSE '❌ Función can_review_property NO existe'
    END as estado_property,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'can_review_traveler'
        ) THEN '✅ Función can_review_traveler existe'
        ELSE '❌ Función can_review_traveler NO existe'
    END as estado_traveler;

-- =====================================================
-- FUNCIÓN NUEVA: LÓGICA DE 5 DÍAS PARA CHAT
-- =====================================================

-- Esta es la ÚNICA función nueva que necesitas
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

-- =====================================================
-- COMENTARIO Y VERIFICACIÓN
-- =====================================================

COMMENT ON FUNCTION should_show_chat_button(UUID, UUID) IS 'Verifica si mostrar botón de chat: siempre para vigentes, solo 5 días para pasadas';

-- Verificar que la función se creó correctamente
SELECT 
    'FUNCIÓN NUEVA CREADA' as resultado,
    routine_name,
    'Función para ocultar chat después de 5 días' as descripcion
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name = 'should_show_chat_button';

-- =====================================================
-- PRUEBA RÁPIDA DE LA FUNCIÓN
-- =====================================================

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
        RAISE NOTICE 'ℹ️ No hay datos de prueba disponibles';
    END IF;
END $$;

-- =====================================================
-- ESTADÍSTICAS DE RESERVAS POR TIEMPO
-- =====================================================

SELECT 
    'ESTADÍSTICAS DE RESERVAS' as info,
    COUNT(*) as total_reservas,
    COUNT(CASE WHEN fecha_fin >= NOW() THEN 1 END) as vigentes,
    COUNT(CASE WHEN fecha_fin < NOW() AND fecha_fin >= NOW() - INTERVAL '5 days' THEN 1 END) as pasadas_recientes_chat_disponible,
    COUNT(CASE WHEN fecha_fin < NOW() - INTERVAL '5 days' THEN 1 END) as pasadas_antiguas_sin_chat
FROM reservas;

-- =====================================================
-- RESULTADO FINAL
-- =====================================================

SELECT '🎉 LÓGICA DE 5 DÍAS PARA CHAT IMPLEMENTADA' as resultado_final;

-- =====================================================
-- RESUMEN DE LO QUE HACE ESTE SCRIPT
-- =====================================================
/*
✅ VERIFICACIONES:
- Confirma que códigos de verificación ya existen
- Confirma que funciones de reseñas ya existen
- No duplica nada que ya esté implementado

✅ FUNCIÓN NUEVA:
- should_show_chat_button(): Única función nueva necesaria
- Lógica: Vigentes = siempre chat, Pasadas = solo 5 días

✅ LÓGICA IMPLEMENTADA:
- Reservas vigentes (fecha_fin >= NOW()) → Chat siempre disponible
- Reservas pasadas (< 5 días) → Chat disponible
- Reservas pasadas (≥ 5 días) → Chat NO disponible

✅ NO SE TOCA:
- Sistema de códigos de verificación (ya existe)
- Funciones de reseñas (ya existen)
- Sistema de notificaciones push (ya configurado)
- Triggers existentes
- Políticas RLS

✅ RESULTADO:
- En Flutter ya tienes la lógica implementada
- Solo faltaba esta función SQL
- Ahora el botón de chat se oculta después de 5 días
- Aparece mensaje "Chat no disponible" para reservas antiguas
*/