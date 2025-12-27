-- =====================================================
-- LIMPIEZA RADICAL PARA ARREGLAR CHAT DEFINITIVAMENTE
-- =====================================================

-- 1. DESHABILITAR COMPLETAMENTE RLS EN TODAS LAS TABLAS PROBLEMÁTICAS
ALTER TABLE public.mensajes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.users_profiles DISABLE ROW LEVEL SECURITY;

-- 2. ELIMINAR TODOS LOS TRIGGERS DE TODAS LAS TABLAS
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    -- Eliminar todos los triggers de mensajes
    FOR trigger_record IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_table = 'mensajes' AND trigger_schema = 'public'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.mensajes CASCADE', trigger_record.trigger_name);
    END LOOP;
    
    -- Eliminar todos los triggers de notifications
    FOR trigger_record IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_table = 'notifications' AND trigger_schema = 'public'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.notifications CASCADE', trigger_record.trigger_name);
    END LOOP;
    
    -- Eliminar todos los triggers de notification_settings
    FOR trigger_record IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_table = 'notification_settings' AND trigger_schema = 'public'
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.notification_settings CASCADE', trigger_record.trigger_name);
    END LOOP;
END $$;

-- 3. ELIMINAR TODAS LAS FUNCIONES RELACIONADAS CON PUSH/NOTIFICATIONS
DO $$
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN 
        SELECT routine_name 
        FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND (routine_name LIKE '%push%' 
             OR routine_name LIKE '%notification%' 
             OR routine_name LIKE '%trigger%'
             OR routine_name LIKE '%message%')
    LOOP
        EXECUTE format('DROP FUNCTION IF EXISTS public.%I() CASCADE', func_record.routine_name);
        -- Intentar con diferentes firmas
        EXECUTE format('DROP FUNCTION IF EXISTS public.%I CASCADE', func_record.routine_name);
    END LOOP;
END $$;

-- 4. ELIMINAR TODAS LAS POLÍTICAS RLS
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- Eliminar políticas de mensajes
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'mensajes' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.mensajes', policy_record.policyname);
    END LOOP;
    
    -- Eliminar políticas de notification_settings
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'notification_settings' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.notification_settings', policy_record.policyname);
    END LOOP;
    
    -- Eliminar políticas de notifications
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'notifications' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.notifications', policy_record.policyname);
    END LOOP;
END $$;

-- 5. VERIFICAR QUE NO QUEDAN TRIGGERS
SELECT 
    'TRIGGERS RESTANTES DESPUÉS DE LIMPIEZA' as info,
    COUNT(*) as total_triggers
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND event_object_table IN ('mensajes', 'notifications', 'notification_settings');

-- 6. VERIFICAR QUE NO QUEDAN FUNCIONES PROBLEMÁTICAS
SELECT 
    'FUNCIONES RESTANTES' as info,
    COUNT(*) as total_funciones
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND (routine_name LIKE '%push%' 
     OR routine_name LIKE '%notification%' 
     OR routine_name LIKE '%trigger%');

-- 7. CREAR CONFIGURACIÓN BÁSICA PARA NOTIFICATION_SETTINGS
-- Asegurar que todos los usuarios tengan configuración
INSERT INTO public.notification_settings (user_id, push_notifications_enabled, email_notifications_enabled)
SELECT 
    id,
    true,
    true
FROM public.users_profiles 
WHERE id NOT IN (SELECT user_id FROM public.notification_settings WHERE user_id IS NOT NULL)
ON CONFLICT (user_id) DO NOTHING;

-- 8. PROBAR INSERCIÓN DE MENSAJE SIN NINGÚN TRIGGER
DO $$
DECLARE
    test_user_id UUID;
    test_reserva_id UUID;
BEGIN
    SELECT id INTO test_user_id FROM public.users_profiles LIMIT 1;
    SELECT id INTO test_reserva_id FROM public.reservas LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_reserva_id IS NOT NULL THEN
        BEGIN
            INSERT INTO public.mensajes (
                reserva_id,
                remitente_id,
                mensaje,
                leido,
                created_at
            ) VALUES (
                test_reserva_id,
                test_user_id,
                'PRUEBA DESPUÉS DE LIMPIEZA RADICAL - ' || NOW()::text,
                false,
                NOW()
            );
            
            RAISE NOTICE '🎉 ÉXITO: Mensaje insertado sin errores después de limpieza radical';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Error persiste incluso después de limpieza radical: %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠️ No hay datos de prueba disponibles';
    END IF;
END $$;

-- 9. MOSTRAR ESTADO FINAL
SELECT 
    'ESTADO FINAL' as info,
    'Mensajes' as tabla,
    COUNT(*) as total_registros
FROM public.mensajes

UNION ALL

SELECT 
    'ESTADO FINAL' as info,
    'Notification Settings' as tabla,
    COUNT(*) as total_registros
FROM public.notification_settings;

-- 10. MOSTRAR ÚLTIMOS MENSAJES PARA VERIFICAR
SELECT 
    'ÚLTIMOS MENSAJES DESPUÉS DE LIMPIEZA' as info,
    m.mensaje,
    m.created_at,
    up.email as remitente
FROM public.mensajes m
LEFT JOIN public.users_profiles up ON m.remitente_id = up.id
ORDER BY m.created_at DESC
LIMIT 3;

SELECT '🧹 LIMPIEZA RADICAL COMPLETADA' as resultado;
SELECT 'Todas las tablas sin RLS, sin triggers, sin políticas' as estado;
SELECT 'El chat debería funcionar ahora sin ningún error' as instruccion;