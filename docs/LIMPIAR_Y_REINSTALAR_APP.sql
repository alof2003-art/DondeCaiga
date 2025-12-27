-- =====================================================
-- LIMPIAR Y REINSTALAR APP - ARREGLAR PROBLEMA DE NOTIFICACIONES
-- =====================================================

-- 1. LIMPIAR TODOS LOS TOKENS FCM EXISTENTES
UPDATE public.users_profiles 
SET fcm_token = NULL 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 2. LIMPIAR DEVICE TOKENS
DELETE FROM public.device_tokens 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 3. LIMPIAR COLA DE PUSH NOTIFICATIONS
DELETE FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 4. VERIFICAR LIMPIEZA
SELECT 
    'LIMPIEZA COMPLETADA' as info,
    'FCM Token' as componente,
    CASE 
        WHEN fcm_token IS NULL THEN '✅ LIMPIO'
        ELSE '❌ AÚN EXISTE'
    END as estado
FROM public.users_profiles 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid

UNION ALL

SELECT 
    'LIMPIEZA COMPLETADA' as info,
    'Device Tokens' as componente,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ LIMPIO'
        ELSE '❌ AÚN EXISTEN: ' || COUNT(*)::text
    END as estado
FROM public.device_tokens 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid

UNION ALL

SELECT 
    'LIMPIEZA COMPLETADA' as info,
    'Push Queue' as componente,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ LIMPIO'
        ELSE '❌ AÚN EXISTEN: ' || COUNT(*)::text
    END as estado
FROM public.push_notification_queue 
WHERE user_id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid;

-- 5. FUNCIÓN PARA VERIFICAR DESPUÉS DE REINSTALAR
CREATE OR REPLACE FUNCTION verificar_app_reinstalada()
RETURNS TABLE(
    componente TEXT,
    estado TEXT,
    detalles TEXT
) AS $$
BEGIN
    RETURN QUERY
    -- Verificar FCM token
    SELECT 
        'FCM Token'::TEXT,
        CASE 
            WHEN EXISTS(
                SELECT 1 FROM public.users_profiles 
                WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid 
                AND fcm_token IS NOT NULL
            ) THEN '✅ GENERADO'
            ELSE '❌ FALTANTE - Abre la app'
        END::TEXT,
        COALESCE(
            (SELECT LEFT(fcm_token, 30) || '...' 
             FROM public.users_profiles 
             WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid),
            'NULL - La app debe generar uno nuevo'
        )::TEXT
    
    UNION ALL
    
    -- Verificar configuración
    SELECT 
        'Configuración'::TEXT,
        CASE 
            WHEN get_app_config('supabase_url') IS NOT NULL 
                 AND get_app_config('supabase_anon_key') IS NOT NULL 
            THEN '✅ CONFIGURADO'
            ELSE '❌ FALTANTE'
        END::TEXT,
        'URL y anon key para Edge Function'::TEXT;
END;
$$ LANGUAGE plpgsql;

SELECT '🧹 LIMPIEZA COMPLETADA - AHORA REINSTALA LA APP' as resultado;
SELECT '📱 PASOS: 1) Desinstala la app del celular, 2) Reinstala con flutter install, 3) Abre la app' as instrucciones;