-- ============================================
-- TABLA DE AUDITORÍA ADMINISTRATIVA
-- Sistema de Gestión de Usuarios por Admin
-- ============================================

-- Crear tabla de auditoría administrativa
CREATE TABLE IF NOT EXISTS admin_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
  target_user_id UUID NOT NULL REFERENCES users_profiles(id) ON DELETE CASCADE,
  action_type VARCHAR(50) NOT NULL CHECK (action_type IN ('degrade_role', 'block_account', 'unblock_account')),
  action_data JSONB,
  reason TEXT,
  was_successful BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_audit_log_admin ON admin_audit_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_target ON admin_audit_log(target_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action_type ON admin_audit_log(action_type);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON admin_audit_log(created_at DESC);

-- Comentarios de documentación
COMMENT ON TABLE admin_audit_log IS 'Registro de auditoría para acciones administrativas sobre usuarios';
COMMENT ON COLUMN admin_audit_log.admin_id IS 'ID del administrador que realizó la acción';
COMMENT ON COLUMN admin_audit_log.target_user_id IS 'ID del usuario objetivo de la acción';
COMMENT ON COLUMN admin_audit_log.action_type IS 'Tipo de acción: degrade_role, block_account, unblock_account';
COMMENT ON COLUMN admin_audit_log.action_data IS 'Datos adicionales de la acción en formato JSON';
COMMENT ON COLUMN admin_audit_log.reason IS 'Motivo de la acción administrativa';
COMMENT ON COLUMN admin_audit_log.was_successful IS 'Indica si la acción fue exitosa';

-- Habilitar RLS (Row Level Security)
ALTER TABLE admin_audit_log ENABLE ROW LEVEL SECURITY;

-- Política: Solo administradores pueden insertar registros
CREATE POLICY "Admins can insert audit logs" ON admin_audit_log
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users_profiles 
      WHERE id = auth.uid() AND rol_id = 3
    )
  );

-- Política: Solo administradores pueden leer registros de auditoría
CREATE POLICY "Admins can read audit logs" ON admin_audit_log
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users_profiles 
      WHERE id = auth.uid() AND rol_id = 3
    )
  );

-- Función para obtener información completa de auditoría con nombres
CREATE OR REPLACE FUNCTION get_audit_log_with_names()
RETURNS TABLE (
  id UUID,
  admin_id UUID,
  admin_nombre TEXT,
  target_user_id UUID,
  target_user_nombre TEXT,
  action_type VARCHAR(50),
  action_data JSONB,
  reason TEXT,
  was_successful BOOLEAN,
  created_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE SQL
SECURITY DEFINER
AS $$
  SELECT 
    al.id,
    al.admin_id,
    admin_profile.nombre as admin_nombre,
    al.target_user_id,
    target_profile.nombre as target_user_nombre,
    al.action_type,
    al.action_data,
    al.reason,
    al.was_successful,
    al.created_at
  FROM admin_audit_log al
  LEFT JOIN users_profiles admin_profile ON al.admin_id = admin_profile.id
  LEFT JOIN users_profiles target_profile ON al.target_user_id = target_profile.id
  ORDER BY al.created_at DESC;
$$;

-- Otorgar permisos de ejecución a usuarios autenticados
GRANT EXECUTE ON FUNCTION get_audit_log_with_names() TO authenticated;

-- Funciones auxiliares para transacciones (simplificadas)
-- Nota: En Supabase, las transacciones se manejan automáticamente por operación
-- Estas funciones son placeholders para compatibilidad
CREATE OR REPLACE FUNCTION begin_transaction()
RETURNS void
LANGUAGE SQL
AS $$
  SELECT 1; -- No-op, Supabase maneja transacciones automáticamente
$$;

CREATE OR REPLACE FUNCTION commit_transaction()
RETURNS void
LANGUAGE SQL
AS $$
  SELECT 1; -- No-op, Supabase maneja transacciones automáticamente
$$;

CREATE OR REPLACE FUNCTION rollback_transaction()
RETURNS void
LANGUAGE SQL
AS $$
  SELECT 1; -- No-op, Supabase maneja transacciones automáticamente
$$;