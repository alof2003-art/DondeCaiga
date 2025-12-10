-- ============================================
-- ERRORES Y SOLUCIONES SQL
-- Proyecto: Donde Caiga
-- Fecha: 2025-12-04
-- ============================================

-- Este archivo documenta TODOS los errores SQL encontrados
-- durante el desarrollo y sus soluciones

-- ============================================
-- ERROR 1: Políticas Duplicadas en Mensajes
-- ============================================

-- FECHA: 2025-12-04
-- ARCHIVO: arreglar_tabla_mensajes.sql

-- ERROR:
-- ERROR: 42710: policy "Admins tienen acceso completo a mensajes" 
-- for table "mensajes" already exists

-- CAUSA:
-- Intentar ejecutar el mismo script SQL dos veces sin eliminar
-- las políticas existentes primero

-- SOLUCIÓN:
-- Agregar DROP POLICY IF EXISTS antes de crear cada política

DROP POLICY IF EXISTS "Participantes pueden ver mensajes de su reserva" ON mensajes;
DROP POLICY IF EXISTS "Participantes pueden enviar mensajes" ON mensajes;
DROP POLICY IF EXISTS "Usuarios pueden actualizar estado de lectura" ON mensajes;
DROP POLICY IF EXISTS "Admins tienen acceso completo a mensajes" ON mensajes;

-- Luego crear las políticas normalmente
CREATE POLICY "Admins tienen acceso completo a mensajes"
    ON mensajes FOR ALL
    USING (...);

-- ============================================
-- ERROR 2: Estructura Incorrecta de Tabla Mensajes
-- ============================================

-- FECHA: 2025-12-04
-- ARCHIVO: crear_tabla_mensajes.sql (ELIMINADO)

-- ERROR:
-- Los campos de la tabla no coincidían con el modelo Flutter
-- - Tenía 'contenido' en lugar de 'mensaje'
-- - Tenía 'destinatario_id' que no era necesario

-- CAUSA:
-- Primera versión de la tabla fue diseñada sin revisar
-- el modelo de datos de Flutter

-- SOLUCIÓN:
-- Recrear la tabla con la estructura correcta

DROP TABLE IF EXISTS mensajes CASCADE;

CREATE TABLE mensajes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reserva_id UUID NOT NULL REFERENCES reservas(id) ON DELETE CASCADE,
    remitente_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
    mensaje TEXT NOT NULL,  -- ✅ Correcto (antes era 'contenido')
    leido BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    -- ❌ Eliminado: destinatario_id (se infiere de la reserva)
);

-- ============================================
-- ERROR 3: Anfitriones No Veían Chats
-- ============================================

-- FECHA: 2025-12-04
-- ARCHIVO: lib/features/buzon/presentation/screens/chat_lista_screen.dart

-- ERROR:
-- Los anfitriones veían una lista vacía de chats

-- CAUSA:
-- El código solo obtenía reservas donde el usuario era viajero:
-- final reservas = await _reservaRepository.obtenerReservasViajero(user.id);

-- SOLUCIÓN SQL:
-- No fue necesario cambiar SQL, las políticas RLS ya permitían
-- que anfitriones vieran reservas de sus propiedades

-- SOLUCIÓN FLUTTER:
-- Obtener AMBAS listas de reservas y combinarlas:

-- final reservasViajero = await _reservaRepository.obtenerReservasViajero(user.id);
-- final reservasAnfitrion = await _reservaRepository.obtenerReservasAnfitrion(user.id);
-- final todasReservas = [...reservasViajero, ...reservasAnfitrion];

-- ============================================
-- ERROR 4: Trigger No Generaba Código de Verificación
-- ============================================

-- FECHA: 2025-12-04
-- ARCHIVO: agregar_codigo_verificacion_reservas.sql (ELIMINADO)

-- ERROR:
-- El código de verificación no se generaba automáticamente
-- al confirmar una reserva

-- CAUSA:
-- El trigger solo se ejecutaba en UPDATE, pero la condición
-- no verificaba correctamente el cambio de estado

-- SOLUCIÓN:
-- Mejorar la función del trigger para verificar el cambio de estado

CREATE OR REPLACE FUNCTION asignar_codigo_verificacion()
RETURNS TRIGGER AS $
BEGIN
    -- Solo generar código si:
    -- 1. El nuevo estado es 'confirmada'
    -- 2. El código aún no existe o está vacío
    IF NEW.estado = 'confirmada' AND 
       (OLD.codigo_verificacion IS NULL OR OLD.codigo_verificacion = '') THEN
        NEW.codigo_verificacion = generar_codigo_verificacion();
    END IF;
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- ============================================
-- ERROR 5: Políticas RLS Bloqueaban Registro
-- ============================================

-- FECHA: Inicio del proyecto
-- ARCHIVO: fix_users_profiles_rls.sql

-- ERROR:
-- Los usuarios no podían registrarse porque las políticas RLS
-- bloqueaban la inserción en users_profiles

-- CAUSA:
-- La política de INSERT requería auth.uid() = id, pero durante
-- el registro el usuario aún no estaba autenticado

-- SOLUCIÓN:
-- Crear trigger que inserta el perfil automáticamente después
-- de que auth.users crea el usuario

CREATE OR REPLACE FUNCTION crear_perfil_usuario_automatico()
RETURNS TRIGGER AS $
BEGIN
  INSERT INTO public.users_profiles (id, email, nombre, email_verified)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'nombre', 'Usuario'),
    NEW.email_confirmed_at IS NOT NULL
  );
  RETURN NEW;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_crear_perfil_usuario
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION crear_perfil_usuario_automatico();

-- ============================================
-- ERROR 6: Storage Policies Demasiado Restrictivas
-- ============================================

-- FECHA: Durante desarrollo
-- ARCHIVO: storage_policies_final.sql

-- ERROR:
-- Los usuarios no podían subir fotos de perfil ni documentos

-- CAUSA:
-- Las políticas de storage eran muy restrictivas y requerían
-- que el path del archivo coincidiera con el user_id

-- SOLUCIÓN (TEMPORAL - SOLO DESARROLLO):
-- Crear políticas permisivas para todos los buckets

CREATE POLICY "profile_photos_all"
ON storage.objects FOR ALL
TO public
USING (bucket_id = 'profile-photos')
WITH CHECK (bucket_id = 'profile-photos');

-- NOTA: En producción, estas políticas deben ser más restrictivas

-- ============================================
-- ERROR 7: Realtime No Funcionaba en Mensajes
-- ============================================

-- FECHA: 2025-12-04
-- ARCHIVO: arreglar_tabla_mensajes.sql (ELIMINADO)

-- ERROR:
-- Los mensajes no se actualizaban en tiempo real

-- CAUSA:
-- La tabla 'mensajes' no estaba agregada a la publicación
-- de Realtime de Supabase

-- SOLUCIÓN:
-- Agregar la tabla a la publicación de Realtime

DO $
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE mensajes;
EXCEPTION
    WHEN duplicate_object THEN
        NULL;
END $;

-- ============================================
-- ERROR 8: Reservas Pendientes Aparecían en Chat
-- ============================================

-- FECHA: 2025-12-04
-- ARCHIVO: lib/features/reservas/data/repositories/reserva_repository.dart

-- ERROR:
-- Los anfitriones veían chats de reservas pendientes/rechazadas

-- CAUSA:
-- La consulta no filtraba por estado de reserva

-- SOLUCIÓN SQL:
-- Agregar filtro en la consulta

-- final response = await _supabase
--     .from('reservas')
--     .select(...)
--     .inFilter('propiedad_id', propiedadIds)
--     .eq('estado', 'confirmada')  -- ✅ AGREGADO
--     .order('created_at', ascending: false);

-- ============================================
-- ERROR 9: Índices Faltantes en Mensajes
-- ============================================

-- FECHA: 2025-12-04
-- ARCHIVO: arreglar_tabla_mensajes.sql (ELIMINADO)

-- ERROR:
-- Las consultas de mensajes eran lentas

-- CAUSA:
-- No había índices en las columnas más consultadas

-- SOLUCIÓN:
-- Crear índices apropiados

CREATE INDEX IF NOT EXISTS idx_mensajes_reserva ON mensajes(reserva_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_remitente ON mensajes(remitente_id);
CREATE INDEX IF NOT EXISTS idx_mensajes_created_at ON mensajes(created_at);

-- ============================================
-- ERROR 10: Función update_updated_at Faltante
-- ============================================

-- FECHA: Inicio del proyecto
-- ARCHIVO: supabase_setup.sql

-- ERROR:
-- ERROR: function update_updated_at_column() does not exist

-- CAUSA:
-- Los triggers referenciaban una función que no existía

-- SOLUCIÓN:
-- Crear la función antes de crear los triggers

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- ============================================
-- ERROR 11: Extensión uuid-ossp No Habilitada
-- ============================================

-- FECHA: Inicio del proyecto
-- ARCHIVO: supabase_setup.sql

-- ERROR:
-- ERROR: function uuid_generate_v4() does not exist

-- CAUSA:
-- La extensión uuid-ossp no estaba habilitada en la base de datos

-- SOLUCIÓN:
-- Habilitar la extensión (Supabase la tiene por defecto)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- ERROR 12: Políticas RLS en Storage.buckets
-- ============================================

-- FECHA: Durante desarrollo
-- ARCHIVO: storage_buckets_policies.sql

-- ERROR:
-- Los usuarios no podían ver los buckets disponibles

-- CAUSA:
-- RLS estaba habilitado en storage.buckets sin políticas

-- SOLUCIÓN:
-- Crear política para permitir lectura de buckets

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir acceso a todos los buckets"
ON storage.buckets FOR SELECT
TO public
USING (true);

-- ============================================
-- ERROR 13: Trigger Duplicado en Reservas
-- ============================================

-- FECHA: 2025-12-04
-- ARCHIVO: agregar_codigo_verificacion_reservas.sql (ELIMINADO)

-- ERROR:
-- ERROR: trigger "trigger_asignar_codigo_verificacion" 
-- for relation "reservas" already exists

-- CAUSA:
-- Intentar crear el mismo trigger dos veces

-- SOLUCIÓN:
-- Usar DROP TRIGGER IF EXISTS antes de crear

DROP TRIGGER IF EXISTS trigger_asignar_codigo_verificacion ON reservas;
CREATE TRIGGER trigger_asignar_codigo_verificacion
    BEFORE UPDATE ON reservas
    FOR EACH ROW
    EXECUTE FUNCTION asignar_codigo_verificacion();

-- ============================================
-- ERROR 14: Warnings de withOpacity Deprecated
-- ============================================

-- FECHA: 2025-12-04
-- ARCHIVOS: Múltiples archivos Flutter

-- ERROR:
-- Warning: 'withOpacity' is deprecated and shouldn't be used

-- CAUSA:
-- Flutter actualizó la API de colores en versiones recientes

-- SOLUCIÓN (NO SQL - FLUTTER):
-- Reemplazar withOpacity() por withValues(alpha:)

-- Antes:
-- Colors.blue.withOpacity(0.05)

-- Después:
-- Colors.blue.withValues(alpha: 0.05)

-- ============================================
-- RESUMEN DE ERRORES
-- ============================================

-- Total de errores documentados: 14
-- Errores SQL: 11
-- Errores Flutter: 3

-- Categorías:
-- - Políticas RLS: 4 errores
-- - Estructura de tablas: 2 errores
-- - Triggers y funciones: 3 errores
-- - Storage: 2 errores
-- - Índices y performance: 1 error
-- - Realtime: 1 error
-- - Código Flutter: 3 errores

-- ============================================
-- ARCHIVOS SQL ELIMINADOS (CONSOLIDADOS)
-- ============================================

-- Los siguientes archivos fueron eliminados el 2025-12-04
-- porque su contenido fue consolidado en SISTEMA_CHAT_FINAL.sql:

-- 1. agregar_codigo_verificacion_reservas.sql
--    Razón: Consolidado en versión final

-- 2. crear_tabla_mensajes.sql
--    Razón: Estructura incorrecta (ERROR 2)

-- 3. arreglar_tabla_mensajes.sql
--    Razón: Consolidado en versión final

-- 4. actualizar_chat_completo.sql
--    Razón: Versión intermedia, reemplazada por final

-- ============================================
-- FIN DEL DOCUMENTO DE ERRORES Y SOLUCIONES
-- ============================================

SELECT '✅ TODOS LOS ERRORES Y SOLUCIONES DOCUMENTADOS' as resultado;