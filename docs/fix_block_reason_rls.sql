-- ============================================
-- FIX: Permitir obtener motivo de bloqueo sin RLS
-- Soluciona el problema donde usuarios bloqueados
-- no pueden ver el motivo de su bloqueo
-- ============================================

-- Función pública para obtener motivo de bloqueo (sin RLS)
CREATE OR REPLACE FUNCTION get_block_reason(user_id UUID)
RETURNS TABLE (
  reason TEXT,
  created_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE SQL
SECURITY DEFINER -- Ejecuta con permisos del propietario (bypass RLS)
AS $$
  SELECT 
    al.reason,
    al.created_at
  FROM admin_audit_log al
  WHERE al.target_user_id = user_id
    AND al.action_type = 'block_account'
    AND al.was_successful = true
  ORDER BY al.created_at DESC
  LIMIT 1;
$$;

-- Otorgar permisos a usuarios autenticados
GRANT EXECUTE ON FUNCTION get_block_reason(UUID) TO authenticated;

-- También permitir a usuarios anónimos (para casos edge)
GRANT EXECUTE ON FUNCTION get_block_reason(UUID) TO anon;

-- Comentario de documentación
COMMENT ON FUNCTION get_block_reason(UUID) IS 'Obtiene el motivo del bloqueo de un usuario sin restricciones RLS';