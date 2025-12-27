-- =====================================================
-- DIAGNÓSTICO COMPLETO: RESEÑAS Y CHAT
-- =====================================================

-- 1. VERIFICAR ESTRUCTURA DE TABLAS DE RESEÑAS
SELECT 
    'ESTRUCTURA TABLA RESENAS' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'resenas' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. VERIFICAR ESTRUCTURA DE TABLA RESENAS_VIAJEROS
SELECT 
    'ESTRUCTURA TABLA RESENAS_VIAJEROS' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'resenas_viajeros' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. VERIFICAR ESTRUCTURA DE TABLA MENSAJES
SELECT 
    'ESTRUCTURA TABLA MENSAJES' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'mensajes' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. VERIFICAR DATOS DE PRUEBA EN RESEÑAS
SELECT 
    'DATOS RESEÑAS' as info,
    COUNT(*) as total_resenas,
    COUNT(CASE WHEN calificacion IS NULL THEN 1 END) as sin_calificacion,
    COUNT(CASE WHEN aspectos IS NULL THEN 1 END) as sin_aspectos,
    MIN(created_at) as primera_resena,
    MAX(created_at) as ultima_resena
FROM public.resenas;

-- 5. VERIFICAR DATOS DE PRUEBA EN MENSAJES
SELECT 
    'DATOS MENSAJES' as info,
    COUNT(*) as total_mensajes,
    MIN(created_at) as primer_mensaje,
    MAX(created_at) as ultimo_mensaje,
    -- Verificar zona horaria
    MIN(created_at AT TIME ZONE 'UTC') as primer_mensaje_utc,
    MAX(created_at AT TIME ZONE 'UTC') as ultimo_mensaje_utc
FROM public.mensajes;

-- 6. VERIFICAR POLÍTICAS RLS
SELECT 
    'POLÍTICAS RLS' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('resenas', 'resenas_viajeros', 'mensajes')
ORDER BY tablename, policyname;

-- 7. FUNCIÓN PARA PROBAR INSERCIÓN DE RESEÑA
CREATE OR REPLACE FUNCTION test_insertar_resena()
RETURNS TEXT AS $$
DECLARE
    test_user_id UUID;
    test_propiedad_id UUID;
    result TEXT;
BEGIN
    -- Obtener un usuario de prueba
    SELECT id INTO test_user_id 
    FROM public.users_profiles 
    LIMIT 1;
    
    -- Obtener una propiedad de prueba
    SELECT id INTO test_propiedad_id 
    FROM public.propiedades 
    LIMIT 1;
    
    IF test_user_id IS NULL OR test_propiedad_id IS NULL THEN
        RETURN '❌ No hay datos de prueba (usuarios o propiedades)';
    END IF;
    
    BEGIN
        -- Intentar insertar reseña de prueba
        INSERT INTO public.resenas (
            propiedad_id, 
            viajero_id, 
            calificacion, 
            comentario,
            aspectos
        ) VALUES (
            test_propiedad_id,
            test_user_id,
            4.5,
            'Reseña de prueba para diagnóstico',
            '{"limpieza": 5, "comodidad": 4, "ubicacion": 5}'::jsonb
        );
        
        RETURN '✅ Reseña de prueba insertada correctamente';
        
    EXCEPTION WHEN OTHERS THEN
        RETURN '❌ Error al insertar reseña: ' || SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- 8. FUNCIÓN PARA PROBAR INSERCIÓN DE MENSAJE
CREATE OR REPLACE FUNCTION test_insertar_mensaje()
RETURNS TEXT AS $$
DECLARE
    test_user_id UUID;
    test_reserva_id UUID;
    result TEXT;
BEGIN
    -- Obtener un usuario de prueba
    SELECT id INTO test_user_id 
    FROM public.users_profiles 
    LIMIT 1;
    
    -- Obtener una reserva de prueba
    SELECT id INTO test_reserva_id 
    FROM public.reservas 
    LIMIT 1;
    
    IF test_user_id IS NULL OR test_reserva_id IS NULL THEN
        RETURN '❌ No hay datos de prueba (usuarios o reservas)';
    END IF;
    
    BEGIN
        -- Intentar insertar mensaje de prueba
        INSERT INTO public.mensajes (
            reserva_id,
            remitente_id,
            mensaje,
            created_at
        ) VALUES (
            test_reserva_id,
            test_user_id,
            'Mensaje de prueba para diagnóstico - ' || NOW()::text,
            NOW()
        );
        
        RETURN '✅ Mensaje de prueba insertado correctamente';
        
    EXCEPTION WHEN OTHERS THEN
        RETURN '❌ Error al insertar mensaje: ' || SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- 9. FUNCIÓN PARA VERIFICAR ZONA HORARIA
CREATE OR REPLACE FUNCTION verificar_zona_horaria()
RETURNS TABLE(
    descripcion TEXT,
    valor TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'Zona horaria del servidor'::TEXT,
        current_setting('timezone')::TEXT
    
    UNION ALL
    
    SELECT 
        'Hora actual UTC'::TEXT,
        NOW() AT TIME ZONE 'UTC'::TEXT
    
    UNION ALL
    
    SELECT 
        'Hora actual local'::TEXT,
        NOW()::TEXT
    
    UNION ALL
    
    SELECT 
        'Diferencia horaria'::TEXT,
        EXTRACT(TIMEZONE FROM NOW())::TEXT || ' segundos';
END;
$$ LANGUAGE plpgsql;

-- 10. EJECUTAR PRUEBAS
SELECT test_insertar_resena();
SELECT test_insertar_mensaje();
SELECT verificar_zona_horaria();

-- 11. MOSTRAR ÚLTIMOS REGISTROS PARA VERIFICAR
SELECT 
    'ÚLTIMAS RESEÑAS' as info,
    r.id,
    r.calificacion,
    r.comentario,
    r.created_at,
    up.email as viajero_email
FROM public.resenas r
JOIN public.users_profiles up ON r.viajero_id = up.id
ORDER BY r.created_at DESC
LIMIT 3;

SELECT 
    'ÚLTIMOS MENSAJES' as info,
    m.id,
    m.mensaje,
    m.created_at,
    m.created_at AT TIME ZONE 'UTC' as created_at_utc,
    up.email as remitente_email
FROM public.mensajes m
JOIN public.users_profiles up ON m.remitente_id = up.id
ORDER BY m.created_at DESC
LIMIT 3;

SELECT '🔍 DIAGNÓSTICO COMPLETADO - REVISA LOS RESULTADOS ARRIBA' as resultado;