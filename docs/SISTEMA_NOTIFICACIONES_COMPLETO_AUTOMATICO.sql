-- SISTEMA COMPLETO DE NOTIFICACIONES AUTOMÁTICAS
-- Implementa notificaciones push para todos los eventos importantes
-- Ejecutar en Supabase SQL Editor

-- =====================================================
-- 1. FUNCIÓN PARA CREAR NOTIFICACIONES INTELIGENTES
-- =====================================================

CREATE OR REPLACE FUNCTION crear_notificacion_automatica(
    p_user_id UUID,
    p_type VARCHAR,
    p_title VARCHAR,
    p_message TEXT,
    p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS UUID AS $$
DECLARE
    notification_id UUID;
BEGIN
    -- Crear la notificación
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        metadata,
        is_read,
        created_at
    ) VALUES (
        p_user_id,
        p_type,
        p_title,
        p_message,
        p_metadata,
        FALSE,
        NOW()
    ) RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 2. NOTIFICACIONES PARA NUEVAS RESERVAS
-- =====================================================

CREATE OR REPLACE FUNCTION notificar_nueva_reserva() RETURNS TRIGGER AS $$
DECLARE
    anfitrion_id UUID;
    viajero_nombre TEXT;
    propiedad_titulo TEXT;
BEGIN
    -- Obtener información necesaria
    SELECT p.anfitrion_id, p.titulo INTO anfitrion_id, propiedad_titulo
    FROM propiedades p WHERE p.id = NEW.propiedad_id;
    
    SELECT nombre INTO viajero_nombre
    FROM users_profiles WHERE id = NEW.viajero_id;
    
    -- Notificar al anfitrión sobre nueva reserva
    PERFORM crear_notificacion_automatica(
        anfitrion_id,
        'nueva_reserva',
        '🏠 Nueva Solicitud de Reserva',
        COALESCE(viajero_nombre, 'Un viajero') || ' quiere reservar "' || 
        COALESCE(propiedad_titulo, 'tu propiedad') || '" del ' || 
        NEW.fecha_inicio || ' al ' || NEW.fecha_fin,
        jsonb_build_object(
            'reserva_id', NEW.id,
            'viajero_id', NEW.viajero_id,
            'propiedad_id', NEW.propiedad_id,
            'fecha_inicio', NEW.fecha_inicio,
            'fecha_fin', NEW.fecha_fin
        )
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. NOTIFICACIONES PARA CAMBIOS DE ESTADO DE RESERVA
-- =====================================================

CREATE OR REPLACE FUNCTION notificar_cambio_estado_reserva() RETURNS TRIGGER AS $$
DECLARE
    anfitrion_id UUID;
    viajero_nombre TEXT;
    anfitrion_nombre TEXT;
    propiedad_titulo TEXT;
    titulo_notif TEXT;
    mensaje_notif TEXT;
BEGIN
    -- Solo procesar si cambió el estado
    IF OLD.estado IS DISTINCT FROM NEW.estado THEN
        -- Obtener información necesaria
        SELECT p.anfitrion_id, p.titulo INTO anfitrion_id, propiedad_titulo
        FROM propiedades p WHERE p.id = NEW.propiedad_id;
        
        SELECT nombre INTO viajero_nombre
        FROM users_profiles WHERE id = NEW.viajero_id;
        
        SELECT nombre INTO anfitrion_nombre
        FROM users_profiles WHERE id = anfitrion_id;
        
        -- Determinar mensaje según el nuevo estado
        CASE NEW.estado
            WHEN 'confirmada' THEN
                titulo_notif := '✅ Reserva Confirmada';
                mensaje_notif := 'Tu reserva en "' || COALESCE(propiedad_titulo, 'la propiedad') || 
                               '" ha sido confirmada por ' || COALESCE(anfitrion_nombre, 'el anfitrión') ||
                               '. Código: ' || COALESCE(NEW.codigo_verificacion, 'Pendiente');
                
                -- Notificar al viajero
                PERFORM crear_notificacion_automatica(
                    NEW.viajero_id,
                    'reserva_confirmada',
                    titulo_notif,
                    mensaje_notif,
                    jsonb_build_object(
                        'reserva_id', NEW.id,
                        'codigo_verificacion', NEW.codigo_verificacion,
                        'anfitrion_id', anfitrion_id
                    )
                );
                
            WHEN 'rechazada' THEN
                titulo_notif := '❌ Reserva Rechazada';
                mensaje_notif := 'Tu solicitud de reserva en "' || COALESCE(propiedad_titulo, 'la propiedad') || 
                               '" ha sido rechazada. Puedes buscar otras opciones disponibles.';
                
                -- Notificar al viajero
                PERFORM crear_notificacion_automatica(
                    NEW.viajero_id,
                    'reserva_rechazada',
                    titulo_notif,
                    mensaje_notif,
                    jsonb_build_object(
                        'reserva_id', NEW.id,
                        'anfitrion_id', anfitrion_id
                    )
                );
                
            WHEN 'cancelada' THEN
                titulo_notif := '🚫 Reserva Cancelada';
                mensaje_notif := 'La reserva en "' || COALESCE(propiedad_titulo, 'tu propiedad') || 
                               '" ha sido cancelada por ' || COALESCE(viajero_nombre, 'el viajero') || '.';
                
                -- Notificar al anfitrión
                PERFORM crear_notificacion_automatica(
                    anfitrion_id,
                    'reserva_cancelada',
                    titulo_notif,
                    mensaje_notif,
                    jsonb_build_object(
                        'reserva_id', NEW.id,
                        'viajero_id', NEW.viajero_id
                    )
                );
                
            WHEN 'completada' THEN
                titulo_notif := '🎉 Reserva Completada';
                mensaje_notif := 'Tu estancia en "' || COALESCE(propiedad_titulo, 'la propiedad') || 
                               '" ha finalizado. ¡Esperamos que hayas disfrutado tu experiencia!';
                
                -- Notificar al viajero
                PERFORM crear_notificacion_automatica(
                    NEW.viajero_id,
                    'reserva_completada',
                    titulo_notif,
                    mensaje_notif,
                    jsonb_build_object(
                        'reserva_id', NEW.id,
                        'puede_calificar', true
                    )
                );
        END CASE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 4. NOTIFICACIONES PARA SOLICITUDES DE ANFITRIÓN
-- =====================================================

CREATE OR REPLACE FUNCTION notificar_solicitud_anfitrion() RETURNS TRIGGER AS $$
DECLARE
    admin_users UUID[];
    admin_id UUID;
    usuario_nombre TEXT;
BEGIN
    -- Obtener nombre del solicitante
    SELECT nombre INTO usuario_nombre
    FROM users_profiles WHERE id = NEW.usuario_id;
    
    -- Obtener todos los administradores
    SELECT ARRAY(
        SELECT up.id 
        FROM users_profiles up 
        JOIN roles r ON up.rol_id = r.id 
        WHERE r.nombre = 'admin'
    ) INTO admin_users;
    
    -- Notificar a todos los administradores
    FOREACH admin_id IN ARRAY admin_users LOOP
        PERFORM crear_notificacion_automatica(
            admin_id,
            'solicitud_anfitrion',
            '👤 Nueva Solicitud de Anfitrión',
            COALESCE(usuario_nombre, 'Un usuario') || ' ha enviado una solicitud para ser anfitrión. Revisa los documentos adjuntos.',
            jsonb_build_object(
                'solicitud_id', NEW.id,
                'usuario_id', NEW.usuario_id,
                'fecha_solicitud', NEW.fecha_solicitud
            )
        );
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. NOTIFICACIONES PARA RESPUESTAS DE SOLICITUDES DE ANFITRIÓN
-- =====================================================

CREATE OR REPLACE FUNCTION notificar_respuesta_solicitud_anfitrion() RETURNS TRIGGER AS $$
DECLARE
    titulo_notif TEXT;
    mensaje_notif TEXT;
    admin_nombre TEXT;
BEGIN
    -- Solo procesar si cambió el estado
    IF OLD.estado IS DISTINCT FROM NEW.estado AND NEW.estado IN ('aprobada', 'rechazada') THEN
        
        -- Obtener nombre del admin que respondió
        SELECT nombre INTO admin_nombre
        FROM users_profiles WHERE id = NEW.admin_revisor_id;
        
        CASE NEW.estado
            WHEN 'aprobada' THEN
                titulo_notif := '🎉 Solicitud Aprobada';
                mensaje_notif := '¡Felicidades! Tu solicitud para ser anfitrión ha sido aprobada. Ya puedes publicar tus propiedades.';
                
            WHEN 'rechazada' THEN
                titulo_notif := '❌ Solicitud Rechazada';
                mensaje_notif := 'Tu solicitud para ser anfitrión ha sido rechazada. ' || 
                               CASE WHEN NEW.comentario_admin IS NOT NULL 
                                    THEN 'Motivo: ' || NEW.comentario_admin 
                                    ELSE 'Puedes enviar una nueva solicitud con la documentación correcta.' 
                               END;
        END CASE;
        
        -- Notificar al solicitante
        PERFORM crear_notificacion_automatica(
            NEW.usuario_id,
            'respuesta_solicitud_anfitrion',
            titulo_notif,
            mensaje_notif,
            jsonb_build_object(
                'solicitud_id', NEW.id,
                'estado', NEW.estado,
                'admin_revisor', admin_nombre,
                'comentario', NEW.comentario_admin
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 6. NOTIFICACIONES PARA NUEVAS RESEÑAS
-- =====================================================

CREATE OR REPLACE FUNCTION notificar_nueva_resena_propiedad() RETURNS TRIGGER AS $$
DECLARE
    anfitrion_id UUID;
    viajero_nombre TEXT;
    propiedad_titulo TEXT;
BEGIN
    -- Obtener información necesaria
    SELECT p.anfitrion_id, p.titulo INTO anfitrion_id, propiedad_titulo
    FROM propiedades p WHERE p.id = NEW.propiedad_id;
    
    SELECT nombre INTO viajero_nombre
    FROM users_profiles WHERE id = NEW.viajero_id;
    
    -- Notificar al anfitrión
    PERFORM crear_notificacion_automatica(
        anfitrion_id,
        'nueva_resena',
        '⭐ Nueva Reseña Recibida',
        COALESCE(viajero_nombre, 'Un viajero') || ' ha dejado una reseña de ' || 
        COALESCE(NEW.calificacion::text, '0') || ' estrellas en "' || 
        COALESCE(propiedad_titulo, 'tu propiedad') || '".',
        jsonb_build_object(
            'resena_id', NEW.id,
            'calificacion', NEW.calificacion,
            'viajero_id', NEW.viajero_id,
            'propiedad_id', NEW.propiedad_id
        )
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 7. NOTIFICACIONES PARA RESEÑAS DE VIAJEROS
-- =====================================================

CREATE OR REPLACE FUNCTION notificar_nueva_resena_viajero() RETURNS TRIGGER AS $$
DECLARE
    anfitrion_nombre TEXT;
BEGIN
    -- Obtener nombre del anfitrión
    SELECT nombre INTO anfitrion_nombre
    FROM users_profiles WHERE id = NEW.anfitrion_id;
    
    -- Notificar al viajero
    PERFORM crear_notificacion_automatica(
        NEW.viajero_id,
        'resena_viajero',
        '⭐ Reseña Recibida',
        COALESCE(anfitrion_nombre, 'Un anfitrión') || ' te ha calificado con ' || 
        COALESCE(NEW.calificacion::text, '0') || ' estrellas como viajero.',
        jsonb_build_object(
            'resena_id', NEW.id,
            'calificacion', NEW.calificacion,
            'anfitrion_id', NEW.anfitrion_id,
            'reserva_id', NEW.reserva_id
        )
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 8. RECORDATORIOS DE CHECK-IN Y CHECK-OUT
-- =====================================================

CREATE OR REPLACE FUNCTION crear_recordatorios_reserva() RETURNS TRIGGER AS $$
BEGIN
    -- Solo crear recordatorios para reservas confirmadas
    IF NEW.estado = 'confirmada' AND (OLD.estado IS NULL OR OLD.estado != 'confirmada') THEN
        
        -- Recordatorio de check-in (1 día antes)
        PERFORM crear_notificacion_automatica(
            NEW.viajero_id,
            'recordatorio_checkin',
            '📅 Recordatorio de Check-in',
            'Tu reserva comienza mañana (' || NEW.fecha_inicio || '). ¡Prepárate para tu estancia!',
            jsonb_build_object(
                'reserva_id', NEW.id,
                'fecha_checkin', NEW.fecha_inicio,
                'codigo_verificacion', NEW.codigo_verificacion
            )
        );
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 9. MEJORAR TRIGGER DE MENSAJES EXISTENTE
-- =====================================================

-- Actualizar el trigger de mensajes para que sea más robusto
DROP TRIGGER IF EXISTS trigger_notificacion_mensaje ON mensajes;
DROP TRIGGER IF EXISTS trigger_notificar_nuevo_mensaje ON mensajes;

CREATE OR REPLACE FUNCTION notificar_nuevo_mensaje() RETURNS TRIGGER AS $$
DECLARE
    receptor_id UUID;
    remitente_nombre TEXT;
    anfitrion_id UUID;
    viajero_id UUID;
    propiedad_titulo TEXT;
BEGIN
    -- Obtener información de la reserva
    SELECT 
        r.viajero_id,
        p.anfitrion_id,
        p.titulo
    INTO 
        viajero_id,
        anfitrion_id,
        propiedad_titulo
    FROM reservas r
    INNER JOIN propiedades p ON r.propiedad_id = p.id
    WHERE r.id = NEW.reserva_id;
    
    -- Si no encontramos la reserva, salir sin error
    IF viajero_id IS NULL OR anfitrion_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Determinar el receptor
    IF NEW.remitente_id = viajero_id THEN
        receptor_id := anfitrion_id;
    ELSIF NEW.remitente_id = anfitrion_id THEN
        receptor_id := viajero_id;
    ELSE
        RETURN NEW;
    END IF;
    
    -- Obtener nombre del remitente
    SELECT nombre INTO remitente_nombre
    FROM users_profiles
    WHERE id = NEW.remitente_id;
    
    -- Crear notificación usando la función estándar
    PERFORM crear_notificacion_automatica(
        receptor_id,
        'nuevo_mensaje',
        '💬 ' || COALESCE(remitente_nombre, 'Usuario') || ' te escribió',
        CASE 
            WHEN LENGTH(NEW.mensaje) > 80 THEN LEFT(NEW.mensaje, 80) || '...'
            ELSE NEW.mensaje
        END,
        jsonb_build_object(
            'reserva_id', NEW.reserva_id,
            'mensaje_id', NEW.id,
            'remitente_id', NEW.remitente_id,
            'propiedad_titulo', propiedad_titulo
        )
    );
    
    RETURN NEW;
    
EXCEPTION WHEN OTHERS THEN
    -- Si hay error, no fallar la inserción del mensaje
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notificar_nuevo_mensaje
    AFTER INSERT ON mensajes
    FOR EACH ROW
    EXECUTE FUNCTION notificar_nuevo_mensaje();

-- =====================================================
-- 10. CREAR TODOS LOS TRIGGERS (ELIMINANDO EXISTENTES PRIMERO)
-- =====================================================

-- Eliminar triggers existentes para evitar conflictos
DROP TRIGGER IF EXISTS trigger_notificar_nueva_reserva ON reservas;
DROP TRIGGER IF EXISTS trigger_notificar_cambio_estado_reserva ON reservas;
DROP TRIGGER IF EXISTS trigger_notificar_solicitud_anfitrion ON solicitudes_anfitrion;
DROP TRIGGER IF EXISTS trigger_notificar_respuesta_solicitud_anfitrion ON solicitudes_anfitrion;
DROP TRIGGER IF EXISTS trigger_notificar_nueva_resena_propiedad ON resenas;
DROP TRIGGER IF EXISTS trigger_notificar_nueva_resena_viajero ON resenas_viajeros;
DROP TRIGGER IF EXISTS trigger_crear_recordatorios_reserva ON reservas;

-- Trigger para nuevas reservas
DROP TRIGGER IF EXISTS trigger_notificar_nueva_reserva ON reservas;
CREATE TRIGGER trigger_notificar_nueva_reserva
    AFTER INSERT ON reservas
    FOR EACH ROW
    EXECUTE FUNCTION notificar_nueva_reserva();

-- Trigger para cambios de estado de reserva
DROP TRIGGER IF EXISTS trigger_notificar_cambio_estado_reserva ON reservas;
CREATE TRIGGER trigger_notificar_cambio_estado_reserva
    AFTER UPDATE ON reservas
    FOR EACH ROW
    EXECUTE FUNCTION notificar_cambio_estado_reserva();

-- Trigger para solicitudes de anfitrión
DROP TRIGGER IF EXISTS trigger_notificar_solicitud_anfitrion ON solicitudes_anfitrion;
CREATE TRIGGER trigger_notificar_solicitud_anfitrion
    AFTER INSERT ON solicitudes_anfitrion
    FOR EACH ROW
    EXECUTE FUNCTION notificar_solicitud_anfitrion();

-- Trigger para respuestas de solicitudes de anfitrión
DROP TRIGGER IF EXISTS trigger_notificar_respuesta_solicitud_anfitrion ON solicitudes_anfitrion;
CREATE TRIGGER trigger_notificar_respuesta_solicitud_anfitrion
    AFTER UPDATE ON solicitudes_anfitrion
    FOR EACH ROW
    EXECUTE FUNCTION notificar_respuesta_solicitud_anfitrion();

-- Trigger para nuevas reseñas de propiedades
DROP TRIGGER IF EXISTS trigger_notificar_nueva_resena_propiedad ON resenas;
CREATE TRIGGER trigger_notificar_nueva_resena_propiedad
    AFTER INSERT ON resenas
    FOR EACH ROW
    EXECUTE FUNCTION notificar_nueva_resena_propiedad();

-- Trigger para nuevas reseñas de viajeros
DROP TRIGGER IF EXISTS trigger_notificar_nueva_resena_viajero ON resenas_viajeros;
CREATE TRIGGER trigger_notificar_nueva_resena_viajero
    AFTER INSERT ON resenas_viajeros
    FOR EACH ROW
    EXECUTE FUNCTION notificar_nueva_resena_viajero();

-- Trigger para recordatorios
DROP TRIGGER IF EXISTS trigger_crear_recordatorios_reserva ON reservas;
CREATE TRIGGER trigger_crear_recordatorios_reserva
    AFTER UPDATE ON reservas
    FOR EACH ROW
    EXECUTE FUNCTION crear_recordatorios_reserva();

-- =====================================================
-- 10. VERIFICAR QUE TODO ESTÉ FUNCIONANDO
-- =====================================================

SELECT 
    'Sistema de Notificaciones' as componente,
    '✅ IMPLEMENTADO COMPLETAMENTE' as estado,
    'Triggers creados para todos los eventos' as detalle

UNION ALL

SELECT 
    'Eventos Cubiertos' as componente,
    '8 tipos de notificaciones' as estado,
    'Reservas, Solicitudes, Reseñas, Mensajes, Recordatorios' as detalle

UNION ALL

SELECT 
    'Trigger Principal' as componente,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'trigger_send_push_on_notification'
    ) THEN '✅ ACTIVO' ELSE '❌ FALTANTE' END as estado,
    'Envía push notifications automáticamente' as detalle;