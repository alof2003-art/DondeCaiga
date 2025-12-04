-- ============================================
-- SCRIPT PARA BORRAR TODOS LOS USUARIOS
-- ============================================
-- ⚠️ ADVERTENCIA: Esto borrará TODOS los usuarios de la app
-- Úsalo solo en desarrollo/pruebas

-- 1. Primero borrar los perfiles de users_profiles
-- (Esto se hace primero para evitar problemas de referencias)
DELETE FROM users_profiles;

-- 2. Luego borrar los usuarios de auth.users
-- Nota: Esto también borrará automáticamente los perfiles por el CASCADE
-- pero lo hacemos en orden para estar seguros

-- Para borrar usuarios de auth.users necesitas usar la función de Supabase
-- Ejecuta este código en el SQL Editor:

-- Opción 1: Borrar usuarios uno por uno (más seguro)
-- Reemplaza 'email@ejemplo.com' con el email del usuario que quieres borrar
-- SELECT auth.delete_user_by_email('email@ejemplo.com');

-- Opción 2: Borrar TODOS los usuarios (⚠️ PELIGROSO)
-- Descomenta las siguientes líneas solo si estás SEGURO:

DO $$
DECLARE
  usuario RECORD;
BEGIN
  FOR usuario IN SELECT id FROM auth.users LOOP
    PERFORM auth.delete_user_by_id(usuario.id);
  END LOOP;
END $$;

-- 3. Verificar que todo se borró
SELECT COUNT(*) as usuarios_en_auth FROM auth.users;
SELECT COUNT(*) as perfiles_en_tabla FROM users_profiles;

-- Si todo salió bien, ambos conteos deberían ser 0
