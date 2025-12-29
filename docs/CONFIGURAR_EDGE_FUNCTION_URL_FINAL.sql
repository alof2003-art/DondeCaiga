-- =====================================================
-- CONFIGURAR EDGE FUNCTION URL PARA NOTIFICACIONES PUSH
-- =====================================================
-- Ejecutar en Supabase SQL Editor

-- 1. Configurar la URL de tu proyecto Supabase
INSERT INTO public.app_config (key, value) 
VALUES ('supabase_url', 'https://donde-caiga-notifications.supabase.co')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 2. Configurar tu anon key (reemplaza con tu key real)
INSERT INTO public.app_config (key, value) 
VALUES ('supabase_anon_key', 'TU_ANON_KEY_AQUI')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- 3. Verificar configuración
SELECT * FROM public.app_config WHERE key IN ('supabase_url', 'supabase_anon_key');

-- 4. Probar que la configuración funciona
SELECT test_supabase_config();

-- =====================================================
-- RESULTADO ESPERADO:
-- ✅ supabase_url configurado
-- ✅ supabase_anon_key configurado
-- =====================================================