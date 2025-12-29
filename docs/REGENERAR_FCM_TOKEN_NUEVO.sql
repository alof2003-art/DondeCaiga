-- =====================================================
-- REGENERAR FCM TOKEN NUEVO
-- =====================================================
-- El token FCM está desactualizado después de reinstalar la app

-- PASO 1: Limpiar token viejo
UPDATE public.users_profiles 
SET fcm_token = NULL 
WHERE email = 'alof2003@gmail.com';

-- PASO 2: Limpiar cola de notificaciones con token inválido
DELETE FROM public.push_notification_queue 
WHERE status IN ('pending', 'failed');

-- PASO 3: Verificar limpieza
SELECT 
    'TOKEN LIMPIADO' as status,
    CASE 
        WHEN fcm_token IS NULL THEN '✅ Token eliminado - La app generará uno nuevo'
        ELSE '❌ Token aún existe: ' || LEFT(fcm_token, 30) || '...'
    END as resultado
FROM public.users_profiles 
WHERE email = 'alof2003@gmail.com';

-- PASO 4: Verificar cola limpia
SELECT 
    'COLA LIMPIA' as status,
    COUNT(*) as notificaciones_pendientes
FROM public.push_notification_queue 
WHERE status = 'pending';

SELECT '🔄 REINICIA LA APP AHORA - Firebase generará un token nuevo y válido' as instruccion;