-- =====================================================
-- PRUEBA ESPECÍFICA: GABRIEL → MYRIAN
-- =====================================================
-- Este script prueba específicamente el caso que mencionaste:
-- Gabriel (alof2003@gmail.com) envía mensaje a Myrian

-- 1. VERIFICAR QUE LOS USUARIOS EXISTEN
SELECT 
    'USUARIOS ENCONTRADOS' as info,
    id,
    email,
    nombre
FROM users_profiles 
WHERE email IN ('alof2003@gmail.com', 'myrian@gmail.com')
ORDER BY email;

-- 2. BUSCAR RESERVA ENTRE GABRIEL Y MYRIAN
WITH gabriel_user AS (
    SELECT id as gabriel_id FROM users_profiles WHERE email = 'alof2003@gmail.com'
),
myrian_user AS (
    SELECT id as myrian_id FROM users_profiles WHERE email = 'myrian@gmail.com'
)
SELECT 
    'RESERVAS ENTRE GABRIEL Y MYRIAN' as info,
    r.id as reserva_id,
    r.estado,
    r.created_at,
    CASE 
        WHEN r.viajero_id = g.gabriel_id THEN 'Gabriel es viajero, Myrian es anfitriona'
        WHEN p.anfitrion_id = g.gabriel_id THEN 'Gabriel es anfitrión, Myrian es viajera'
        ELSE 'Relación no clara'
    END as relacion
FROM reservas r
INNER JOIN propiedades p ON r.propiedad_id = p.id
CROSS JOIN gabriel_user g
CROSS JOIN myrian_user m
WHERE (r.viajero_id = g.gabriel_id AND p.anfitrion_id = m.myrian_id)
   OR (r.viajero_id = m.myrian_id AND p.anfitrion_id = g.gabriel_id)
ORDER BY r.created_at DESC;

-- 3. CREAR RESERVA DE PRUEBA SI NO EXISTE
DO $
DECLARE
    gabriel_id UUID;
    myrian_id UUID;
    test_propiedad_id UUID;
    test_reserva_id UUID;
    reserva_existente UUID;
BEGIN
    -- Obtener IDs de Gabriel y Myrian
    SELECT id INTO gabriel_id FROM users_profiles WHERE email = 'alof2003@gmail.com';
    SELECT id INTO myrian_id FROM users_profiles WHERE email = 'myrian@gmail.com';
    
    IF gabriel_id IS NULL THEN
        RAISE NOTICE '❌ No se encontró usuario Gabriel (alof2003@gmail.com)';
        RETURN;
    END IF;
    
    IF myrian_id IS NULL THEN
        RAISE NOTICE '❌ No se encontró usuario Myrian (myrian@gmail.com)';
        RETURN;
    END IF;
    
    -- Verificar si ya existe una reserva entre ellos
    SELECT r.id INTO reserva_existente
    FROM reservas r
    INNER JOIN propiedades p ON r.propiedad_id = p.id
    WHERE (r.viajero_id = gabriel_id AND p.anfitrion_id = myrian_id)
       OR (r.viajero_id = myrian_id AND p.anfitrion_id = gabriel_id)
    LIMIT 1;
    
    IF reserva_existente IS NOT NULL THEN
        RAISE NOTICE '✅ Ya existe reserva entre Gabriel y Myrian: %', reserva_existente;
        RETURN;
    END IF;
    
    -- Buscar una propiedad de Myrian o crear una de prueba
    SELECT id INTO test_propiedad_id 
    FROM propiedades 
    WHERE anfitrion_id = myrian_id 
    LIMIT 1;
    
    IF test_propiedad_id IS NULL THEN
        -- Crear propiedad de prueba para Myrian
        INSERT INTO propiedades (
            anfitrion_id,
            titulo,
            descripcion,
            direccion,
            ciudad,
            pais,
            capacidad_personas,
            numero_habitaciones,
            numero_banos,
            estado
        ) VALUES (
            myrian_id,
            'Casa de Prueba - Myrian',
            'Propiedad de prueba para testing de notificaciones',
            'Calle de Prueba 123',
            'Ciudad de Prueba',
            'País de Prueba',
            4,
            2,
            1,
            'activo'
        ) RETURNING id INTO test_propiedad_id;
        
        RAISE NOTICE '✅ Propiedad de prueba creada para Myrian: %', test_propiedad_id;
    END IF;
    
    -- Crear reserva de prueba (Gabriel como viajero, Myrian como anfitriona)
    INSERT INTO reservas (
        propiedad_id,
        viajero_id,
        fecha_inicio,
        fecha_fin,
        estado
    ) VALUES (
        test_propiedad_id,
        gabriel_id,
        CURRENT_DATE + INTERVAL '7 days',
        CURRENT_DATE + INTERVAL '14 days',
        'confirmada'
    ) RETURNING id INTO test_reserva_id;
    
    RAISE NOTICE '✅ Reserva de prueba creada: Gabriel (viajero) → Myrian (anfitriona): %', test_reserva_id;
END;
$;

-- 4. FUNCIÓN PARA SIMULAR MENSAJE DE GABRIEL A MYRIAN
CREATE OR REPLACE FUNCTION simular_mensaje_gabriel_a_myrian(
    p_mensaje TEXT DEFAULT 'Hola Myrian, ¿cómo estás? Este es un mensaje de prueba para verificar las notificaciones.'
)
RETURNS TEXT AS $
DECLARE
    gabriel_id UUID;
    myrian_id UUID;
    reserva_id UUID;
    mensaje_id UUID;
    notificaciones_antes INTEGER;
    notificaciones_despues INTEGER;
    nueva_notificacion RECORD;
BEGIN
    -- Obtener IDs
    SELECT id INTO gabriel_id FROM users_profiles WHERE email = 'alof2003@gmail.com';
    SELECT id INTO myrian_id FROM users_profiles WHERE email = 'myrian@gmail.com';
    
    IF gabriel_id IS NULL OR myrian_id IS NULL THEN
        RETURN '❌ No se encontraron los usuarios Gabriel o Myrian';
    END IF;
    
    -- Buscar reserva entre ellos
    SELECT r.id INTO reserva_id
    FROM reservas r
    INNER JOIN propiedades p ON r.propiedad_id = p.id
    WHERE (r.viajero_id = gabriel_id AND p.anfitrion_id = myrian_id)
       OR (r.viajero_id = myrian_id AND p.anfitrion_id = gabriel_id)
    ORDER BY r.created_at DESC
    LIMIT 1;
    
    IF reserva_id IS NULL THEN
        RETURN '❌ No se encontró reserva entre Gabriel y Myrian';
    END IF;
    
    -- Contar notificaciones antes
    SELECT COUNT(*) INTO notificaciones_antes 
    FROM notifications 
    WHERE user_id = myrian_id;
    
    -- Insertar mensaje de Gabriel
    INSERT INTO mensajes (
        reserva_id,
        remitente_id,
        mensaje,
        leido,
        created_at
    ) VALUES (
        reserva_id,
        gabriel_id,
        p_mensaje,
        false,
        NOW()
    ) RETURNING id INTO mensaje_id;
    
    -- Esperar un momento para que se ejecute el trigger
    PERFORM pg_sleep(0.1);
    
    -- Contar notificaciones después
    SELECT COUNT(*) INTO notificaciones_despues 
    FROM notifications 
    WHERE user_id = myrian_id;
    
    -- Obtener la notificación creada
    SELECT 
        n.id,
        n.title,
        n.message,
        n.type,
        n.created_at
    INTO nueva_notificacion
    FROM notifications n
    WHERE n.user_id = myrian_id
    ORDER BY n.created_at DESC
    LIMIT 1;
    
    IF notificaciones_despues > notificaciones_antes THEN
        RETURN '✅ ÉXITO: Gabriel envió mensaje a Myrian y se creó notificación automáticamente!' || E'\n' ||
               'Mensaje ID: ' || mensaje_id || E'\n' ||
               'Notificación: "' || nueva_notificacion.title || '"' || E'\n' ||
               'Contenido: "' || nueva_notificacion.message || '"' || E'\n' ||
               'Notificaciones antes: ' || notificaciones_antes || ', después: ' || notificaciones_despues;
    ELSE
        RETURN '❌ PROBLEMA: Mensaje enviado pero NO se creó notificación automáticamente' || E'\n' ||
               'Mensaje ID: ' || mensaje_id || E'\n' ||
               'Notificaciones antes: ' || notificaciones_antes || ', después: ' || notificaciones_despues;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RETURN '❌ ERROR: ' || SQLERRM;
END;
$ LANGUAGE plpgsql;

-- 5. EJECUTAR LA PRUEBA
SELECT simular_mensaje_gabriel_a_myrian();

-- 6. VERIFICAR NOTIFICACIONES DE MYRIAN
SELECT 
    'NOTIFICACIONES DE MYRIAN' as info,
    n.id,
    n.type,
    n.title,
    n.message,
    n.is_read,
    n.created_at
FROM notifications n
INNER JOIN users_profiles up ON n.user_id = up.id
WHERE up.email = 'myrian@gmail.com'
ORDER BY n.created_at DESC
LIMIT 5;

-- 7. VERIFICAR MENSAJES ENTRE GABRIEL Y MYRIAN
SELECT 
    'MENSAJES GABRIEL ↔ MYRIAN' as info,
    m.id,
    up_remitente.email as remitente,
    m.mensaje,
    m.leido,
    m.created_at
FROM mensajes m
INNER JOIN users_profiles up_remitente ON m.remitente_id = up_remitente.id
INNER JOIN reservas r ON m.reserva_id = r.id
INNER JOIN propiedades p ON r.propiedad_id = p.id
WHERE up_remitente.email IN ('alof2003@gmail.com', 'myrian@gmail.com')
ORDER BY m.created_at DESC
LIMIT 10;

-- 8. FUNCIÓN PARA SIMULAR RESPUESTA DE MYRIAN
CREATE OR REPLACE FUNCTION simular_respuesta_myrian_a_gabriel(
    p_mensaje TEXT DEFAULT 'Hola Gabriel, todo bien por aquí. Gracias por tu mensaje!'
)
RETURNS TEXT AS $
DECLARE
    gabriel_id UUID;
    myrian_id UUID;
    reserva_id UUID;
    mensaje_id UUID;
    notificaciones_antes INTEGER;
    notificaciones_despues INTEGER;
BEGIN
    -- Obtener IDs
    SELECT id INTO gabriel_id FROM users_profiles WHERE email = 'alof2003@gmail.com';
    SELECT id INTO myrian_id FROM users_profiles WHERE email = 'myrian@gmail.com';
    
    -- Buscar reserva
    SELECT r.id INTO reserva_id
    FROM reservas r
    INNER JOIN propiedades p ON r.propiedad_id = p.id
    WHERE (r.viajero_id = gabriel_id AND p.anfitrion_id = myrian_id)
       OR (r.viajero_id = myrian_id AND p.anfitrion_id = gabriel_id)
    ORDER BY r.created_at DESC
    LIMIT 1;
    
    -- Contar notificaciones de Gabriel antes
    SELECT COUNT(*) INTO notificaciones_antes 
    FROM notifications 
    WHERE user_id = gabriel_id;
    
    -- Insertar respuesta de Myrian
    INSERT INTO mensajes (
        reserva_id,
        remitente_id,
        mensaje,
        leido,
        created_at
    ) VALUES (
        reserva_id,
        myrian_id,
        p_mensaje,
        false,
        NOW()
    ) RETURNING id INTO mensaje_id;
    
    -- Esperar y contar después
    PERFORM pg_sleep(0.1);
    SELECT COUNT(*) INTO notificaciones_despues 
    FROM notifications 
    WHERE user_id = gabriel_id;
    
    IF notificaciones_despues > notificaciones_antes THEN
        RETURN '✅ ÉXITO: Myrian respondió a Gabriel y se creó notificación automáticamente!';
    ELSE
        RETURN '❌ PROBLEMA: Respuesta enviada pero NO se creó notificación automáticamente';
    END IF;
END;
$ LANGUAGE plpgsql;

SELECT '🎯 PRUEBA ESPECÍFICA GABRIEL → MYRIAN COMPLETADA' as resultado;
SELECT '💬 Para probar respuesta de Myrian, ejecuta: SELECT simular_respuesta_myrian_a_gabriel();' as siguiente_paso;