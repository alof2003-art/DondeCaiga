-- =====================================================
-- SISTEMA DE NOTIFICACIONES COMPLETO
-- =====================================================

-- Crear tabla de notificaciones
CREATE TABLE IF NOT EXISTS notificaciones (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tipo VARCHAR(50) NOT NULL,
    titulo VARCHAR(255) NOT NULL,
    mensaje TEXT NOT NULL,
    datos JSONB,
    imagen_url TEXT,
    leida BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_actualizacion TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario_id ON notificaciones(usuario_id);
CREATE INDEX IF NOT EXISTS idx_notificaciones_tipo ON notificaciones(tipo);
CREATE INDEX IF NOT EXISTS idx_notificaciones_leida ON notificaciones(leida);
CREATE INDEX IF NOT EXISTS idx_notificaciones_fecha_creacion ON notificaciones(fecha_creacion DESC);
CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario_leida ON notificaciones(usuario_id, leida);

-- Trigger para actualizar fecha_actualizacion
CREATE OR REPLACE FUNCTION update_notificaciones_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_notificaciones_updated_at
    BEFORE UPDATE ON notificaciones
    FOR EACH ROW
    EXECUTE FUNCTION update_notificaciones_updated_at();

-- =====================================================
-- POLÍTICAS RLS (Row Level Security)
-- =====================================================

-- Habilitar RLS
ALTER TABLE notificaciones ENABLE ROW LEVEL SECURITY;

-- Política para que los usuarios solo vean sus propias notificaciones
CREATE POLICY "Los usuarios solo pueden ver sus propias notificaciones"
ON notificaciones FOR SELECT
USING (auth.uid() = usuario_id);

-- Política para que los usuarios solo puedan actualizar sus propias notificaciones
CREATE POLICY "Los usuarios solo pueden actualizar sus propias notificaciones"
ON notificaciones FOR UPDATE
USING (auth.uid() = usuario_id);

-- Política para que los usuarios solo puedan eliminar sus propias notificaciones
CREATE POLICY "Los usuarios solo pueden eliminar sus propias notificaciones"
ON notificaciones FOR DELETE
USING (auth.uid() = usuario_id);

-- Política para que el sistema pueda insertar notificaciones (usando service_role)
CREATE POLICY "El sistema puede insertar notificaciones"
ON notificaciones FOR INSERT
WITH CHECK (true);

-- =====================================================
-- FUNCIONES PARA CREAR NOTIFICACIONES
-- =====================================================

-- Función para crear notificación de solicitud de reserva
CREATE OR REPLACE FUNCTION crear_notificacion_solicitud_reserva(
    p_anfitrion_id UUID,
    p_viajero_nombre TEXT,
    p_propiedad_nombre TEXT,
    p_reserva_id UUID
)
RETURNS UUID AS $$
DECLARE
    notificacion_id UUID;
BEGIN
    INSERT INTO notificaciones (
        usuario_id,
        tipo,
        titulo,
        mensaje,
        datos
    ) VALUES (
        p_anfitrion_id,
        'solicitudReserva',
        'Nueva solicitud de reserva',
        p_viajero_nombre || ' quiere reservar tu propiedad "' || p_propiedad_nombre || '"',
        jsonb_build_object(
            'reserva_id', p_reserva_id,
            'viajero_nombre', p_viajero_nombre,
            'propiedad_nombre', p_propiedad_nombre
        )
    ) RETURNING id INTO notificacion_id;
    
    RETURN notificacion_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para crear notificación de reserva aceptada/rechazada
CREATE OR REPLACE FUNCTION crear_notificacion_decision_reserva(
    p_viajero_id UUID,
    p_aceptada BOOLEAN,
    p_propiedad_nombre TEXT,
    p_reserva_id UUID,
    p_comentario TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    notificacion_id UUID;
    titulo_notif TEXT;
    mensaje_notif TEXT;
    tipo_notif TEXT;
BEGIN
    IF p_aceptada THEN
        titulo_notif := 'Reserva aceptada';
        mensaje_notif := 'Tu reserva para "' || p_propiedad_nombre || '" ha sido aceptada';
        tipo_notif := 'reservaAceptada';
    ELSE
        titulo_notif := 'Reserva rechazada';
        mensaje_notif := 'Tu reserva para "' || p_propiedad_nombre || '" ha sido rechazada';
        tipo_notif := 'reservaRechazada';
    END IF;
    
    INSERT INTO notificaciones (
        usuario_id,
        tipo,
        titulo,
        mensaje,
        datos
    ) VALUES (
        p_viajero_id,
        tipo_notif,
        titulo_notif,
        mensaje_notif,
        jsonb_build_object(
            'reserva_id', p_reserva_id,
            'propiedad_nombre', p_propiedad_nombre,
            'aceptada', p_aceptada,
            'comentario', p_comentario
        )
    ) RETURNING id INTO notificacion_id;
    
    RETURN notificacion_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para crear notificación de nueva reseña
CREATE OR REPLACE FUNCTION crear_notificacion_nueva_resena(
    p_usuario_id UUID,
    p_autor_nombre TEXT,
    p_calificacion INTEGER,
    p_es_resena_propiedad BOOLEAN DEFAULT TRUE,
    p_propiedad_nombre TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    notificacion_id UUID;
    mensaje_notif TEXT;
BEGIN
    IF p_es_resena_propiedad THEN
        mensaje_notif := p_autor_nombre || ' te ha dejado una reseña de ' || p_calificacion || ' estrellas en "' || p_propiedad_nombre || '"';
    ELSE
        mensaje_notif := p_autor_nombre || ' te ha dejado una reseña de ' || p_calificacion || ' estrellas como viajero';
    END IF;
    
    INSERT INTO notificaciones (
        usuario_id,
        tipo,
        titulo,
        mensaje,
        datos
    ) VALUES (
        p_usuario_id,
        'nuevaResena',
        'Nueva reseña recibida',
        mensaje_notif,
        jsonb_build_object(
            'autor_nombre', p_autor_nombre,
            'calificacion', p_calificacion,
            'es_resena_propiedad', p_es_resena_propiedad,
            'propiedad_nombre', p_propiedad_nombre
        )
    ) RETURNING id INTO notificacion_id;
    
    RETURN notificacion_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para crear notificación de decisión de anfitrión
CREATE OR REPLACE FUNCTION crear_notificacion_decision_anfitrion(
    p_usuario_id UUID,
    p_aceptado BOOLEAN,
    p_comentario_admin TEXT
)
RETURNS UUID AS $$
DECLARE
    notificacion_id UUID;
    titulo_notif TEXT;
    mensaje_notif TEXT;
    tipo_notif TEXT;
BEGIN
    IF p_aceptado THEN
        titulo_notif := '¡Felicidades! Eres anfitrión';
        mensaje_notif := 'Tu solicitud para ser anfitrión ha sido aprobada. Ya puedes publicar propiedades.';
        tipo_notif := 'anfitrionAceptado';
    ELSE
        titulo_notif := 'Solicitud de anfitrión rechazada';
        mensaje_notif := 'Tu solicitud para ser anfitrión ha sido rechazada. Revisa los comentarios del administrador.';
        tipo_notif := 'anfitrionRechazado';
    END IF;
    
    INSERT INTO notificaciones (
        usuario_id,
        tipo,
        titulo,
        mensaje,
        datos
    ) VALUES (
        p_usuario_id,
        tipo_notif,
        titulo_notif,
        mensaje_notif,
        jsonb_build_object(
            'aceptado', p_aceptado,
            'comentario_admin', p_comentario_admin
        )
    ) RETURNING id INTO notificacion_id;
    
    RETURN notificacion_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para crear notificación de nuevo mensaje
CREATE OR REPLACE FUNCTION crear_notificacion_nuevo_mensaje(
    p_receptor_id UUID,
    p_emisor_nombre TEXT,
    p_chat_id UUID,
    p_mensaje_preview TEXT
)
RETURNS UUID AS $$
DECLARE
    notificacion_id UUID;
BEGIN
    INSERT INTO notificaciones (
        usuario_id,
        tipo,
        titulo,
        mensaje,
        datos
    ) VALUES (
        p_receptor_id,
        'nuevoMensaje',
        'Nuevo mensaje de ' || p_emisor_nombre,
        CASE 
            WHEN LENGTH(p_mensaje_preview) > 100 THEN 
                SUBSTRING(p_mensaje_preview FROM 1 FOR 100) || '...'
            ELSE 
                p_mensaje_preview
        END,
        jsonb_build_object(
            'chat_id', p_chat_id,
            'emisor_nombre', p_emisor_nombre
        )
    ) RETURNING id INTO notificacion_id;
    
    RETURN notificacion_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para crear notificación de llegada de huésped
CREATE OR REPLACE FUNCTION crear_notificacion_llegada_huesped(
    p_anfitrion_id UUID,
    p_huesped_nombre TEXT,
    p_propiedad_nombre TEXT,
    p_reserva_id UUID
)
RETURNS UUID AS $$
DECLARE
    notificacion_id UUID;
BEGIN
    INSERT INTO notificaciones (
        usuario_id,
        tipo,
        titulo,
        mensaje,
        datos
    ) VALUES (
        p_anfitrion_id,
        'llegadaHuesped',
        'Huésped ha llegado',
        p_huesped_nombre || ' ha llegado a tu propiedad "' || p_propiedad_nombre || '"',
        jsonb_build_object(
            'reserva_id', p_reserva_id,
            'huesped_nombre', p_huesped_nombre,
            'propiedad_nombre', p_propiedad_nombre
        )
    ) RETURNING id INTO notificacion_id;
    
    RETURN notificacion_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para crear notificación de fin de estadía
CREATE OR REPLACE FUNCTION crear_notificacion_fin_estadia(
    p_anfitrion_id UUID,
    p_huesped_nombre TEXT,
    p_propiedad_nombre TEXT,
    p_reserva_id UUID
)
RETURNS UUID AS $$
DECLARE
    notificacion_id UUID;
BEGIN
    INSERT INTO notificaciones (
        usuario_id,
        tipo,
        titulo,
        mensaje,
        datos
    ) VALUES (
        p_anfitrion_id,
        'finEstadia',
        'Estadía finalizada',
        'La estadía de ' || p_huesped_nombre || ' en "' || p_propiedad_nombre || '" ha terminado',
        jsonb_build_object(
            'reserva_id', p_reserva_id,
            'huesped_nombre', p_huesped_nombre,
            'propiedad_nombre', p_propiedad_nombre
        )
    ) RETURNING id INTO notificacion_id;
    
    RETURN notificacion_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- TRIGGERS AUTOMÁTICOS
-- =====================================================

-- Trigger para crear notificación cuando se crea una reserva
CREATE OR REPLACE FUNCTION trigger_notificacion_nueva_reserva()
RETURNS TRIGGER AS $$
DECLARE
    anfitrion_id UUID;
    viajero_nombre TEXT;
    propiedad_nombre TEXT;
BEGIN
    -- Obtener datos del anfitrión y la propiedad
    SELECT p.usuario_id, pr.nombre, u.nombre_completo
    INTO anfitrion_id, propiedad_nombre, viajero_nombre
    FROM propiedades p
    JOIN profiles pr ON pr.id = NEW.viajero_id
    WHERE p.id = NEW.propiedad_id;
    
    -- Crear notificación para el anfitrión
    PERFORM crear_notificacion_solicitud_reserva(
        anfitrion_id,
        viajero_nombre,
        propiedad_nombre,
        NEW.id
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a la tabla reservas
DROP TRIGGER IF EXISTS trigger_nueva_reserva_notificacion ON reservas;
CREATE TRIGGER trigger_nueva_reserva_notificacion
    AFTER INSERT ON reservas
    FOR EACH ROW
    EXECUTE FUNCTION trigger_notificacion_nueva_reserva();

-- Trigger para crear notificación cuando se actualiza el estado de una reserva
CREATE OR REPLACE FUNCTION trigger_notificacion_estado_reserva()
RETURNS TRIGGER AS $$
DECLARE
    propiedad_nombre TEXT;
BEGIN
    -- Solo procesar si cambió el estado
    IF OLD.estado != NEW.estado AND NEW.estado IN ('aceptada', 'rechazada') THEN
        -- Obtener nombre de la propiedad
        SELECT nombre INTO propiedad_nombre
        FROM propiedades
        WHERE id = NEW.propiedad_id;
        
        -- Crear notificación para el viajero
        PERFORM crear_notificacion_decision_reserva(
            NEW.viajero_id,
            NEW.estado = 'aceptada',
            propiedad_nombre,
            NEW.id,
            NEW.comentario_rechazo
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a la tabla reservas
DROP TRIGGER IF EXISTS trigger_estado_reserva_notificacion ON reservas;
CREATE TRIGGER trigger_estado_reserva_notificacion
    AFTER UPDATE ON reservas
    FOR EACH ROW
    EXECUTE FUNCTION trigger_notificacion_estado_reserva();

-- =====================================================
-- FUNCIONES DE UTILIDAD
-- =====================================================

-- Función para marcar todas las notificaciones como leídas
CREATE OR REPLACE FUNCTION marcar_todas_notificaciones_leidas(p_usuario_id UUID)
RETURNS INTEGER AS $$
DECLARE
    count_updated INTEGER;
BEGIN
    UPDATE notificaciones 
    SET leida = TRUE, fecha_actualizacion = NOW()
    WHERE usuario_id = p_usuario_id AND leida = FALSE;
    
    GET DIAGNOSTICS count_updated = ROW_COUNT;
    RETURN count_updated;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para limpiar notificaciones antiguas (más de 30 días)
CREATE OR REPLACE FUNCTION limpiar_notificaciones_antiguas()
RETURNS INTEGER AS $$
DECLARE
    count_deleted INTEGER;
BEGIN
    DELETE FROM notificaciones 
    WHERE fecha_creacion < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS count_deleted = ROW_COUNT;
    RETURN count_deleted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- DATOS DE PRUEBA (OPCIONAL)
-- =====================================================

-- Insertar algunas notificaciones de prueba
-- (Descomenta si quieres datos de prueba)

/*
-- Obtener un usuario de prueba
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        -- Notificación de bienvenida
        INSERT INTO notificaciones (
            usuario_id,
            tipo,
            titulo,
            mensaje,
            datos
        ) VALUES (
            test_user_id,
            'general',
            '¡Bienvenido a Donde Caiga!',
            'Gracias por unirte a nuestra comunidad. Explora propiedades increíbles y vive experiencias únicas.',
            jsonb_build_object('es_bienvenida', true)
        );
        
        -- Notificación de ejemplo
        INSERT INTO notificaciones (
            usuario_id,
            tipo,
            titulo,
            mensaje,
            datos,
            leida
        ) VALUES (
            test_user_id,
            'nuevaResena',
            'Nueva reseña recibida',
            'Juan Pérez te ha dejado una reseña de 5 estrellas',
            jsonb_build_object('calificacion', 5, 'autor', 'Juan Pérez'),
            false
        );
    END IF;
END $$;
*/

-- =====================================================
-- COMENTARIOS FINALES
-- =====================================================

-- Este script crea un sistema completo de notificaciones que incluye:
-- 1. Tabla de notificaciones con todos los campos necesarios
-- 2. Índices optimizados para consultas rápidas
-- 3. Políticas RLS para seguridad
-- 4. Funciones para crear diferentes tipos de notificaciones
-- 5. Triggers automáticos para eventos del sistema
-- 6. Funciones de utilidad para mantenimiento

-- Para usar este sistema:
-- 1. Ejecuta este script en tu base de datos Supabase
-- 2. Configura las notificaciones push en tu app Flutter
-- 3. Usa las funciones proporcionadas para crear notificaciones
-- 4. El sistema manejará automáticamente las notificaciones de reservas

COMMENT ON TABLE notificaciones IS 'Tabla para almacenar todas las notificaciones del sistema';
COMMENT ON COLUMN notificaciones.tipo IS 'Tipo de notificación: solicitudReserva, reservaAceptada, nuevaResena, etc.';
COMMENT ON COLUMN notificaciones.datos IS 'Datos adicionales en formato JSON para cada tipo de notificación';