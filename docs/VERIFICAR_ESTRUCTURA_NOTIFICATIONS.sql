-- =====================================================
-- VERIFICAR ESTRUCTURA DE LA TABLA NOTIFICATIONS
-- =====================================================

-- 1. VER QUÉ COLUMNAS TIENE LA TABLA NOTIFICATIONS
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'notifications' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. VER ALGUNAS FILAS DE EJEMPLO
SELECT * FROM notifications LIMIT 3;

-- 3. CONTAR CUÁNTAS NOTIFICACIONES HAY
SELECT COUNT(*) as total_notifications FROM notifications;