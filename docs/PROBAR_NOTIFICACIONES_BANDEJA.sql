-- =====================================================
-- PROBAR NOTIFICACIONES EN BANDEJA DEL SISTEMA
-- =====================================================

-- 1. VERIFICAR QUE TODO ESTÉ CONFIGURADO
SELECT 
    'VERIFICACIÓN PREVIA' as info,
    CASE 
        WHEN get_app_config('supabase_url') IS NOT NULL 
             AND get_app_config('supabase_anon_key') IS NOT NULL 
        THEN '✅ Configuración OK'
        ELSE '❌ Configuración faltante'
    END as config_status,
    CASE 
        WHEN EXISTS(
            SELECT 1 FROM public.users_profiles 
            WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid 
            AND fcm_token IS NOT NULL
        ) THEN '✅ FCM Token OK'
        ELSE '❌ FCM Token faltante'
    END as token_status;

-- 2. CREAR NOTIFICACIÓN DE PRUEBA PARA BANDEJA DEL SISTEMA
-- Esta notificación debería aparecer en la bandeja cuando la app esté cerrada
INSERT INTO public.notifications (user_id, type, title, message, is_read) 
VALUES (
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid, 
    'general', 
    'Prueba Bandeja Sistema 📱', 
    'Esta notificación debe aparecer en la bandeja del celular cuando la app esté cerrada', 
    FALSE
);

-- 3. VERIFICAR QUE SE PROCESÓ
SELECT 
    'NOTIFICACIÓN ENVIADA' as info,
    COUNT(*) as total_notificaciones,
    MAX(created_at) as ultima_notificacion
FROM public.notifications 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
AND created_at > NOW() - INTERVAL '1 minute';

-- 4. VERIFICAR COLA DE PUSH NOTIFICATIONS
SELECT 
    'COLA PUSH NOTIFICATIONS' as info,
    status,
    COUNT(*) as cantidad,
    MAX(created_at) as ultimo_envio
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid
AND created_at > NOW() - INTERVAL '5 minutes'
GROUP BY status
ORDER BY ultimo_envio DESC;

-- 5. FUNCIÓN PARA ENVIAR MÚLTIPLES NOTIFICACIONES DE PRUEBA
CREATE OR REPLACE FUNCTION enviar_notificaciones_prueba_bandeja()
RETURNS TEXT AS $$
BEGIN
    -- Notificación 1: Prueba básica
    INSERT INTO public.notifications (user_id, type, title, message, is_read) 
    VALUES (
        '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid, 
        'general', 
        'Notificación 1 🔔', 
        'Primera prueba - Cierra la app y revisa la bandeja', 
        FALSE
    );
    
    -- Esperar 2 segundos
    PERFORM pg_sleep(2);
    
    -- Notificación 2: Prueba con emoji
    INSERT INTO public.notifications (user_id, type, title, message, is_read) 
    VALUES (
        '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid, 
        'reserva_confirmada', 
        'Reserva Confirmada ✅', 
        'Tu reserva ha sido confirmada exitosamente', 
        FALSE
    );
    
    -- Esperar 2 segundos
    PERFORM pg_sleep(2);
    
    -- Notificación 3: Prueba de mensaje
    INSERT INTO public.notifications (user_id, type, title, message, is_read) 
    VALUES (
        '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid, 
        'nuevo_mensaje', 
        'Nuevo Mensaje 💬', 
        'Tienes un nuevo mensaje de tu anfitrión', 
        FALSE
    );
    
    RETURN '✅ 3 notificaciones enviadas - Cierra la app y revisa tu bandeja del sistema';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- INSTRUCCIONES PARA PROBAR:
-- =====================================================
-- 1. Ejecuta este SQL completo
-- 2. CIERRA LA APP COMPLETAMENTE (no solo minimizar)
-- 3. Espera 10-15 segundos
-- 4. Revisa la bandeja de notificaciones de tu celular
-- 5. Deberías ver las notificaciones ahí
-- 6. Si no aparecen, ejecuta: SELECT enviar_notificaciones_prueba_bandeja();
-- =====================================================

SELECT '🚀 NOTIFICACIÓN DE PRUEBA ENVIADA' as resultado;
SELECT '📱 CIERRA LA APP Y REVISA LA BANDEJA DEL SISTEMA' as instruccion;