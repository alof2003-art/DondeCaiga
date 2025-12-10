-- ============================================
-- CONVERTIR alof2003@gmail.com EN ADMIN
-- ============================================

-- Actualizar el rol del usuario a admin (rol_id = 3)
UPDATE users_profiles
SET rol_id = 3
WHERE email = 'alof2003@gmail.com';

-- Verificar que se actualizó correctamente
SELECT 
    up.id,
    up.email,
    up.nombre,
    r.nombre as rol
FROM users_profiles up
LEFT JOIN roles r ON up.rol_id = r.id
WHERE up.email = 'alof2003@gmail.com';

-- Mensaje de confirmación
SELECT '✅ Usuario alof2003@gmail.com convertido a ADMIN' as resultado;
