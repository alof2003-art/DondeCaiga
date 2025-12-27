-- =====================================================
-- VERIFICACIÓN REAL DE PROBLEMAS - DIAGNÓSTICO ESPECÍFICO
-- =====================================================

-- 1. VERIFICAR SI REALMENTE HAY PROBLEMAS CON RESEÑAS
SELECT 
    'VERIFICACIÓN RESEÑAS' as info,
    COUNT(*) as total_resenas,
    COUNT(CASE WHEN calificacion IS NULL THEN 1 END) as sin_calificacion,
    COUNT(CASE WHEN aspectos IS NULL THEN 1 END) as sin_aspectos,
    AVG(calificacion) as promedio_general
FROM public.resenas;

-- 2. PROBAR INSERCIÓN DE RESEÑA REAL
DO $$
DECLARE
    test_user_id UUID;
    test_propiedad_id UUID;
BEGIN
    -- Obtener IDs reales
    SELECT id INTO test_user_id FROM public.users_profiles LIMIT 1;
    SELECT id INTO test_propiedad_id FROM public.propiedades LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_propiedad_id IS NOT NULL THEN
        BEGIN
            INSERT INTO public.resenas (
                propiedad_id, 
                viajero_id, 
                calificacion, 
                comentario
            ) VALUES (
                test_propiedad_id,
                test_user_id,
                4.5,
                'Prueba de inserción - ' || NOW()::text
            );
            
            RAISE NOTICE 'RESEÑAS: ✅ Inserción exitosa';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'RESEÑAS: ❌ Error: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'RESEÑAS: ⚠️ No hay datos de prueba';
    END IF;
END $$;

-- 3. VERIFICAR SI REALMENTE HAY PROBLEMAS CON MENSAJES
SELECT 
    'VERIFICACIÓN MENSAJES' as info,
    COUNT(*) as total_mensajes,
    MIN(created_at) as primer_mensaje,
    MAX(created_at) as ultimo_mensaje,
    -- Verificar diferencia horaria
    EXTRACT(TIMEZONE FROM NOW()) / 3600 as diferencia_horas_utc
FROM public.mensajes;

-- 4. PROBAR INSERCIÓN DE MENSAJE REAL
DO $$
DECLARE
    test_user_id UUID;
    test_reserva_id UUID;
BEGIN
    -- Obtener IDs reales
    SELECT id INTO test_user_id FROM public.users_profiles LIMIT 1;
    SELECT id INTO test_reserva_id FROM public.reservas LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_reserva_id IS NOT NULL THEN
        BEGIN
            INSERT INTO public.mensajes (
                reserva_id,
                remitente_id,
                mensaje,
                created_at
            ) VALUES (
                test_reserva_id,
                test_user_id,
                'Prueba de inserción - ' || NOW()::text,
                NOW()
            );
            
            RAISE NOTICE 'MENSAJES: ✅ Inserción exitosa';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'MENSAJES: ❌ Error: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE 'MENSAJES: ⚠️ No hay datos de prueba';
    END IF;
END $$;

-- 5. VERIFICAR ZONA HORARIA ACTUAL
SELECT 
    'ZONA HORARIA' as info,
    current_setting('timezone') as zona_configurada,
    NOW() as hora_actual,
    NOW() AT TIME ZONE 'UTC' as hora_utc,
    EXTRACT(TIMEZONE FROM NOW()) / 3600 as diferencia_horas;

-- 6. VERIFICAR POLÍTICAS RLS PROBLEMÁTICAS
SELECT 
    'POLÍTICAS RLS' as info,
    tablename,
    policyname,
    cmd as operacion,
    CASE 
        WHEN qual IS NOT NULL THEN 'Restrictiva'
        ELSE 'Permisiva'
    END as tipo_politica
FROM pg_policies 
WHERE tablename IN ('resenas', 'resenas_viajeros', 'mensajes')
ORDER BY tablename;

-- 7. VERIFICAR ESTRUCTURA DE ASPECTOS
SELECT 
    'ESTRUCTURA ASPECTOS' as info,
    aspectos,
    COUNT(*) as cantidad
FROM public.resenas 
WHERE aspectos IS NOT NULL
GROUP BY aspectos
LIMIT 5;

-- 8. MOSTRAR ÚLTIMOS REGISTROS PARA VERIFICAR FUNCIONAMIENTO
SELECT 
    'ÚLTIMAS RESEÑAS' as tipo,
    r.id,
    r.calificacion,
    r.comentario,
    r.created_at,
    up.email as viajero
FROM public.resenas r
LEFT JOIN public.users_profiles up ON r.viajero_id = up.id
ORDER BY r.created_at DESC
LIMIT 3;

SELECT 
    'ÚLTIMOS MENSAJES' as tipo,
    m.id,
    m.mensaje,
    m.created_at,
    up.email as remitente
FROM public.mensajes m
LEFT JOIN public.users_profiles up ON m.remitente_id = up.id
ORDER BY m.created_at DESC
LIMIT 3;

-- 9. RESUMEN DE ESTADO
SELECT 
    CASE 
        WHEN EXISTS(SELECT 1 FROM public.resenas) THEN '✅ Hay reseñas'
        ELSE '❌ No hay reseñas'
    END as estado_resenas,
    CASE 
        WHEN EXISTS(SELECT 1 FROM public.mensajes) THEN '✅ Hay mensajes'
        ELSE '❌ No hay mensajes'
    END as estado_mensajes,
    CASE 
        WHEN current_setting('timezone') = 'UTC' THEN '⚠️ Zona horaria UTC (puede causar problemas)'
        ELSE '✅ Zona horaria configurada: ' || current_setting('timezone')
    END as estado_zona_horaria;

SELECT '🔍 VERIFICACIÓN COMPLETADA - REVISA LOS RESULTADOS' as resultado;