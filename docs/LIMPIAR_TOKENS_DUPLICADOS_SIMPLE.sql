-- ========================================
-- LIMPIAR TOKENS DUPLICADOS SIMPLE
-- ========================================

-- PASO 1: VER EL PROBLEMA ACTUAL
SELECT 
    'PROBLEMA DETECTADO' as status,
    fcm_token,
    COUNT(*) as usuarios_con_mismo_token,
    STRING_AGG(email || ' (actualizado: ' || updated_at::text || ')', ', ') as detalles
FROM users_profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != ''
GROUP BY fcm_token
HAVING COUNT(*) > 1;

-- PASO 2: LIMPIAR TOKENS DUPLICADOS MANUALMENTE
-- Para el token duplicado específico, mantener solo el más reciente

-- Identificar el token duplicado
WITH token_duplicado AS (
    SELECT 'fPNX8GuHQhuChf-q0O3CYQ:APA91bHl16pNrCls6tGDBOXjseFuIH013rFzxLlXAPNgQTtPaFKAgGAKR5TJF2s-_JFJAUdllmuv_g7eMCvoTgWLs6XG_cd_-b9pvKEUjBsxFV2GPZzuip0' as token
),
usuarios_con_token AS (
    SELECT 
        up.id,
        up.email,
        up.updated_at,
        ROW_NUMBER() OVER (ORDER BY up.updated_at DESC) as rn
    FROM users_profiles up, token_duplicado td
    WHERE up.fcm_token = td.token
)
-- Limpiar token de usuarios más antiguos (mantener solo el más reciente)
UPDATE users_profiles 
SET fcm_token = NULL, updated_at = NOW()
WHERE id IN (
    SELECT id FROM usuarios_con_token WHERE rn > 1
);

-- PASO 3: VERIFICAR RESULTADO
SELECT 
    'DESPUÉS DE LIMPIEZA' as status,
    COUNT(DISTINCT fcm_token) as tokens_unicos,
    COUNT(*) as usuarios_con_token,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT fcm_token) THEN '✅ SIN DUPLICADOS'
        ELSE '❌ AÚN HAY DUPLICADOS'
    END as resultado
FROM users_profiles 
WHERE fcm_token IS NOT NULL AND fcm_token != '';

-- PASO 4: VER USUARIOS AFECTADOS
SELECT 
    'USUARIOS QUE DEBEN REABRIR LA APP' as info,
    email,
    nombre,
    CASE 
        WHEN fcm_token IS NULL THEN '❌ SIN TOKEN - Debe reabrir la app'
        ELSE '✅ CON TOKEN'
    END as estado
FROM users_profiles 
WHERE email IN ('alof2003@gmail.com', 'votaro9925@discounp.com', 'mpattydaquilema@gmail.com')
ORDER BY email;

-- PASO 5: FUNCIÓN SIMPLE PARA LIMPIAR FUTUROS DUPLICADOS
CREATE OR REPLACE FUNCTION limpiar_token_duplicado_simple(token_duplicado TEXT)
RETURNS TEXT AS $$
DECLARE
    usuarios_afectados INTEGER;
BEGIN
    -- Limpiar token de todos los usuarios excepto el más reciente
    WITH usuarios_ordenados AS (
        SELECT 
            id,
            ROW_NUMBER() OVER (ORDER BY updated_at DESC) as rn
        FROM users_profiles 
        WHERE fcm_token = token_duplicado
    )
    UPDATE users_profiles 
    SET fcm_token = NULL, updated_at = NOW()
    WHERE id IN (
        SELECT id FROM usuarios_ordenados WHERE rn > 1
    );
    
    GET DIAGNOSTICS usuarios_afectados = ROW_COUNT;
    
    RETURN '✅ Limpiados ' || usuarios_afectados || ' tokens duplicados para: ' || LEFT(token_duplicado, 30) || '...';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 6: CREAR FUNCIÓN PARA FORZAR NUEVO TOKEN A USUARIO ESPECÍFICO
CREATE OR REPLACE FUNCTION forzar_nuevo_token(user_email TEXT)
RETURNS TEXT AS $$
DECLARE
    target_user_id UUID;
BEGIN
    SELECT id INTO target_user_id
    FROM users_profiles 
    WHERE email = user_email;
    
    IF target_user_id IS NULL THEN
        RETURN '❌ Usuario no encontrado: ' || user_email;
    END IF;
    
    UPDATE users_profiles 
    SET fcm_token = NULL, updated_at = NOW()
    WHERE id = target_user_id;
    
    RETURN '✅ Token limpiado para ' || user_email || '. Debe cerrar y reabrir la app completamente.';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- PASO 7: MENSAJE FINAL
SELECT 
    '🎯 LIMPIEZA COMPLETADA' as resultado,
    'Los usuarios sin token deben cerrar y reabrir la app completamente' as instruccion;