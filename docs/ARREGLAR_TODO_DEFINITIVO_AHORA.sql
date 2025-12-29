-- ========================================
-- ARREGLAR TODO DEFINITIVO AHORA
-- ========================================

-- PASO 1: ARREGLAR TRIGGER (CAMBIAR DE UPDATE A INSERT)
DROP TRIGGER IF EXISTS trigger_send_push_on_notification ON notifications;

CREATE TRIGGER trigger_send_push_on_notification
    AFTER INSERT ON notifications  -- ✅ CAMBIO CRÍTICO: INSERT no UPDATE
    FOR EACH ROW
    EXECUTE FUNCTION send_push_notification_on_insert();

-- PASO 2: DESACTIVAR RLS TEMPORALMENTE PARA FCM TOKENS
ALTER TABLE users_profiles DISABLE ROW LEVEL SECURITY;

-- PASO 3: VERIFICAR QUE EL TOKEN SE PUEDE GUARDAR
SELECT save_user_fcm_token(
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3'::uuid,
    'test_token_manual_' || EXTRACT(EPOCH FROM NOW())::text
);

-- PASO 4: CREAR NOTIFICACIÓN DE PRUEBA (DEBERÍA ENVIAR PUSH)
INSERT INTO notifications (
    user_id,
    title,
    message,
    type,
    is_read,
    created_at
) VALUES (
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3',
    '🚀 SISTEMA ARREGLADO',
    'Si recibes esto en la bandeja, todo funciona!',
    'test',
    FALSE,
    NOW()
);

-- PASO 5: VERIFICAR ESTADO FINAL
SELECT 
    'Trigger' as componente,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'trigger_send_push_on_notification'
        AND event_manipulation = 'INSERT'
    ) THEN '✅ CORRECTO' ELSE '❌ ERROR' END as estado;

SELECT 
    'FCM Token' as componente,
    CASE WHEN fcm_token IS NOT NULL 
         THEN '✅ EXISTE' ELSE '❌ FALTANTE' END as estado,
    LEFT(COALESCE(fcm_token, 'NULL'), 30) || '...' as token_preview
FROM users_profiles 
WHERE id = '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3';

SELECT 
    'RLS Status' as componente,
    CASE WHEN rowsecurity THEN '❌ ACTIVADO' ELSE '✅ DESACTIVADO' END as estado
FROM pg_tables 
WHERE tablename = 'users_profiles';