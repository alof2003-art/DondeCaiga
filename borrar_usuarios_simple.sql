-- ============================================
-- FORMA SIMPLE DE BORRAR USUARIOS
-- ============================================

-- OPCIÓN 1: Borrar un usuario específico por email
-- Reemplaza 'usuario@ejemplo.com' con el email que quieres borrar
SELECT auth.delete_user_by_email('usuario@ejemplo.com');

-- OPCIÓN 2: Borrar TODOS los usuarios (⚠️ úsalo con cuidado)
-- Primero borra los perfiles
DELETE FROM users_profiles;

-- Luego borra todos los usuarios de auth
DO $$
DECLARE
  usuario RECORD;
BEGIN
  FOR usuario IN SELECT id FROM auth.users LOOP
    PERFORM auth.delete_user_by_id(usuario.id);
  END LOOP;
END $$;

-- Verificar que se borraron
SELECT COUNT(*) as total_usuarios FROM auth.users;
SELECT COUNT(*) as total_perfiles FROM users_profiles;
