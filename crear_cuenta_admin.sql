-- ============================================
-- SCRIPT PARA CREAR/ACTUALIZAR CUENTA ADMIN
-- ============================================

-- Actualizar el usuario alof2003@gmail.com a rol de admin
UPDATE users_profiles
SET rol_id = 3
WHERE email = 'alof2003@gmail.com';

-- Verificar que se actualizó correctamente
SELECT 
  up.email,
  up.nombre,
  r.nombre as rol
FROM users_profiles up
JOIN roles r ON up.rol_id = r.id
WHERE up.email = 'alof2003@gmail.com';

-- Si el usuario aún no existe, primero debes registrarte con ese email
-- Luego ejecuta este script para convertirte en admin
