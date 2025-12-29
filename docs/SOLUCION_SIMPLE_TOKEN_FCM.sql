-- =====================================================
-- SOLUCIÓN SIMPLE TOKEN FCM
-- =====================================================

-- PASO 1: Limpiar token truncado
UPDATE public.users_profiles 
SET fcm_token = NULL 
WHERE email = 'alof2003@gmail.com';

-- PASO 2: Limpiar cola con tokens inválidos
DELETE FROM public.push_notification_queue;

-- PASO 3: Verificar limpieza
SELECT 
    'LIMPIEZA COMPLETA' as status,
    CASE 
        WHEN fcm_token IS NULL THEN '✅ Token eliminado'
        ELSE '❌ Token aún existe'
    END as token_status,
    (SELECT COUNT(*) FROM push_notification_queue) as cola_limpia
FROM public.users_profiles 
WHERE email = 'alof2003@gmail.com';

SELECT '🔄 AHORA REINICIA LA APP - Firebase generará un token completo y válido' as instruccion;