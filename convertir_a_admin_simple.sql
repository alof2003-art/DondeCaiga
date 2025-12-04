-- ============================================
-- CONVERTIR CUENTA A ADMIN
-- ============================================

-- Actualizar el usuario alof2003@gmail.com a rol de admin (rol_id = 3)
UPDATE users_profiles
SET rol_id = 3
WHERE email = 'alof2003@gmail.com';

-- Verificar que se actualizó
SELECT 
  email,
  nombre,
  rol_id,
  CASE 
    WHEN rol_id = 1 THEN 'viajero'
    WHEN rol_id = 2 THEN 'anfitrion'
    WHEN rol_id = 3 THEN 'admin'
  END as rol_nombre
FROM users_profiles
WHERE email = 'alof2003@gmail.com';
