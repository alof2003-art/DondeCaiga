-- ============================================
-- CONVERTIR USUARIO EN ADMINISTRADOR
-- ============================================
-- Usuario: arontello@gmail.com
-- Rol: Admin (rol_id = 3)
-- ============================================

-- Actualizar el rol del usuario a administrador
UPDATE users_profiles
SET rol_id = 3
WHERE email = 'arontello@gmail.com';

-- Verificar que el cambio se aplicó correctamente
SELECT 
    id,
    email,
    nombre,
    rol_id,
    (SELECT nombre FROM roles WHERE id = rol_id) as rol_nombre
FROM users_profiles
WHERE email = 'arontello@gmail.com';

-- ============================================
-- RESULTADO ESPERADO:
-- ============================================
-- Si el usuario existe, debería mostrar:
-- - email: arontello@gmail.com
-- - rol_id: 3
-- - rol_nombre: admin
-- ============================================

SELECT '✅ USUARIO CONVERTIDO A ADMINISTRADOR' as resultado;
