-- =====================================================
-- SCRIPT PARA PROBAR EL SISTEMA DE LOGS DETALLADOS
-- Ejecutar después de implementar el sistema de debugging
-- =====================================================

-- PASO 1: Verificar que las funciones existen
SELECT 
    'VERIFICACIÓN DE FUNCIONES' as paso,
    proname as funcion_nombre,
    CASE 
        WHEN proname IN (
            'actualizar_token_fcm_con_logs',
            'limpiar_token_logout_con_logs', 
            'ver_logs_fcm_debug',
            'estadisticas_tokens_fcm',
            'monitoreo_tiempo_real_tokens',
            'log_fcm_debug'
        ) THEN '✅ EXISTE'
        ELSE '❌ FALTA'
    END as estado
FROM pg_proc 
WHERE proname LIKE '%fcm%' OR proname LIKE '%debug%'
ORDER BY proname;

-- PASO 2: Verificar que la tabla de logs existe
SELECT 
    'VERIFICACIÓN TABLA LOGS' as paso,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'debug_fcm_logs')
        THEN '✅ Tabla debug_fcm_logs existe'
        ELSE '❌ Tabla debug_fcm_logs NO existe'
    END as estado;

-- PASO 3: Ver estadísticas actuales
SELECT '📈 ESTADÍSTICAS ACTUALES' as paso;
SELECT * FROM estadisticas_tokens_fcm();

-- PASO 4: Ver estado actual de tokens
SELECT '👥 ESTADO ACTUAL USUARIOS' as paso;
SELECT * FROM monitoreo_tiempo_real_tokens();

-- PASO 5: Probar función de logs (simulación)
SELECT '🧪 PRUEBA DE LOGGING' as paso;
SELECT log_fcm_debug(
    '58e28dd4-b952-4176-9753-21edd24bccae'::uuid,
    'mpattydaquilema@gmail.com',
    'test_function',
    'token_prueba_' || EXTRACT(EPOCH FROM NOW())::text,
    true,
    'Prueba de función de logging',
    '{"test": true}'::jsonb
);

-- PASO 6: Ver logs recientes
SELECT '📋 LOGS RECIENTES' as paso;
SELECT * FROM ver_logs_fcm_debug(NULL, 10);

-- PASO 7: Probar actualización con logs (CAMBIAR USER_ID POR UNO REAL)
SELECT '🔄 PRUEBA ACTUALIZACIÓN CON LOGS' as paso;
-- DESCOMENTA LA SIGUIENTE LÍNEA Y CAMBIA EL USER_ID:
-- SELECT actualizar_token_fcm_con_logs(
--     '58e28dd4-b952-4176-9753-21edd24bccae'::uuid,
--     'token_prueba_logs_' || EXTRACT(EPOCH FROM NOW())::text
-- );

-- PASO 8: Ver logs específicos de un usuario
SELECT '👤 LOGS DE USUARIO ESPECÍFICO' as paso;
SELECT * FROM ver_logs_fcm_debug('mpattydaquilema@gmail.com', 5);

-- PASO 9: Limpiar logs de prueba (opcional)
-- DELETE FROM debug_fcm_logs WHERE action_type = 'test_function';

-- =====================================================
-- COMANDOS PARA USAR DURANTE EL DEBUGGING EN VIVO
-- =====================================================

/*
MIENTRAS PRUEBAS LA APP, EJECUTA ESTOS COMANDOS:

1. Ver logs en tiempo real:
   SELECT * FROM ver_logs_fcm_debug('tu_email@gmail.com');

2. Monitoreo continuo:
   SELECT * FROM monitoreo_tiempo_real_tokens();

3. Estadísticas generales:
   SELECT * FROM estadisticas_tokens_fcm();

4. Ver logs de las últimas 2 horas:
   SELECT * FROM debug_fcm_logs 
   WHERE created_at > NOW() - INTERVAL '2 hours' 
   ORDER BY created_at DESC;

5. Ver solo errores:
   SELECT * FROM debug_fcm_logs 
   WHERE success = false 
   ORDER BY created_at DESC;
*/

-- =====================================================
-- RESULTADOS ESPERADOS
-- =====================================================

/*
✅ FUNCIONES CORRECTAS:
- actualizar_token_fcm_con_logs
- limpiar_token_logout_con_logs
- ver_logs_fcm_debug
- estadisticas_tokens_fcm
- monitoreo_tiempo_real_tokens
- log_fcm_debug

✅ TABLA CREADA:
- debug_fcm_logs

✅ LOGS FUNCIONANDO:
- Cada acción de token debe generar logs
- Los logs deben mostrar éxito/error
- Los logs deben incluir detalles del token

🔍 DEBUGGING:
- Si no ves logs, el problema está en Flutter
- Si ves logs pero tokens no se guardan, problema en SQL/RLS
- Si ves errores en logs, revisar permisos de base de datos
*/