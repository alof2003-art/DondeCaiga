-- ============================================
-- TRIGGER AUTOMÁTICO PARA CREAR PERFIL DE USUARIO
-- ============================================
-- Este trigger crea automáticamente un perfil en users_profiles
-- cuando se registra un nuevo usuario en auth.users

-- 1. CREAR FUNCIÓN QUE SE EJECUTARÁ AUTOMÁTICAMENTE
CREATE OR REPLACE FUNCTION crear_perfil_usuario_automatico()
RETURNS TRIGGER AS $$
BEGIN
  -- Insertar el perfil del usuario en la tabla users_profiles
  INSERT INTO public.users_profiles (id, email, nombre, email_verified)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'nombre', 'Usuario'), -- Toma el nombre de los metadatos o usa 'Usuario'
    false
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. CREAR TRIGGER QUE EJECUTA LA FUNCIÓN
DROP TRIGGER IF EXISTS trigger_crear_perfil_usuario ON auth.users;

CREATE TRIGGER trigger_crear_perfil_usuario
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION crear_perfil_usuario_automatico();

-- 3. VERIFICAR QUE EL TRIGGER SE CREÓ
SELECT 
  trigger_name as nombre_trigger,
  event_manipulation as evento,
  event_object_table as tabla
FROM information_schema.triggers
WHERE trigger_name = 'trigger_crear_perfil_usuario';

-- ============================================
-- NOTA IMPORTANTE
-- ============================================
-- Ahora cuando un usuario se registre en auth.users,
-- automáticamente se creará su perfil en users_profiles
-- con los datos básicos (id, email, nombre)
--
-- Los datos adicionales (teléfono, foto, cédula) se 
-- actualizarán después desde la aplicación
