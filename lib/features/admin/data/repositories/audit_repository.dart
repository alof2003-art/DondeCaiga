import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_action.dart';
import '../models/audit_log.dart';

class AuditRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Registra una acción administrativa en el historial de auditoría
  Future<void> registrarAccionAdmin(
    AdminAction action, {
    bool wasSuccessful = true,
  }) async {
    try {
      await _supabase.from('admin_audit_log').insert({
        'admin_id': action.adminId,
        'target_user_id': action.targetUserId,
        'action_type': action.actionType,
        'action_data': action.actionData,
        'reason': action.reason,
        'was_successful': wasSuccessful,
      });
    } catch (e) {
      // Log el error pero no fallar la operación principal
      print('Error al registrar acción en auditoría: $e');
      // En producción, esto debería usar un sistema de logging apropiado
    }
  }

  /// Obtiene el historial de auditoría con filtros opcionales
  Future<List<AuditLog>> obtenerHistorialAuditoria({
    String? actionTypeFilter,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      // Calcular offset para paginación
      final offset = (page - 1) * limit;

      // Construir query base usando la función SQL personalizada
      final response = await _supabase
          .rpc('get_audit_log_with_names')
          .range(offset, offset + limit - 1);

      // Filtrar en el cliente si es necesario (idealmente se haría en SQL)
      List<dynamic> filteredData = response;

      if (actionTypeFilter != null) {
        filteredData = filteredData
            .where((item) => item['action_type'] == actionTypeFilter)
            .toList();
      }

      if (startDate != null) {
        filteredData = filteredData
            .where(
              (item) => DateTime.parse(item['created_at']).isAfter(startDate),
            )
            .toList();
      }

      if (endDate != null) {
        filteredData = filteredData
            .where(
              (item) => DateTime.parse(item['created_at']).isBefore(endDate),
            )
            .toList();
      }

      return filteredData.map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener historial de auditoría: $e');
    }
  }

  /// Obtiene el historial de auditoría para un usuario específico
  Future<List<AuditLog>> obtenerHistorialUsuario(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .rpc('get_audit_log_with_names')
          .eq('target_user_id', userId)
          .limit(limit);

      return (response as List).map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener historial del usuario: $e');
    }
  }

  /// Obtiene estadísticas de auditoría
  Future<Map<String, int>> obtenerEstadisticasAuditoria() async {
    try {
      // Contar acciones por tipo
      final degradeCount = await _supabase
          .from('admin_audit_log')
          .select('id')
          .eq('action_type', AdminAction.degradeRoleType)
          .count(CountOption.exact);

      final blockCount = await _supabase
          .from('admin_audit_log')
          .select('id')
          .eq('action_type', AdminAction.blockAccountType)
          .count(CountOption.exact);

      final unblockCount = await _supabase
          .from('admin_audit_log')
          .select('id')
          .eq('action_type', AdminAction.unblockAccountType)
          .count(CountOption.exact);

      // Contar acciones exitosas vs fallidas
      final successCount = await _supabase
          .from('admin_audit_log')
          .select('id')
          .eq('was_successful', true)
          .count(CountOption.exact);

      final failureCount = await _supabase
          .from('admin_audit_log')
          .select('id')
          .eq('was_successful', false)
          .count(CountOption.exact);

      return {
        'total_actions':
            degradeCount.count + blockCount.count + unblockCount.count,
        'degrade_role': degradeCount.count,
        'block_account': blockCount.count,
        'unblock_account': unblockCount.count,
        'successful_actions': successCount.count,
        'failed_actions': failureCount.count,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas de auditoría: $e');
    }
  }

  /// Obtiene las acciones más recientes
  Future<List<AuditLog>> obtenerAccionesRecientes({int limit = 10}) async {
    try {
      final response = await _supabase
          .rpc('get_audit_log_with_names')
          .limit(limit);

      return (response as List).map((json) => AuditLog.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener acciones recientes: $e');
    }
  }

  /// Verifica si un administrador tiene permisos para ver auditoría
  Future<bool> verificarPermisosAuditoria(String adminId) async {
    try {
      final response = await _supabase
          .from('users_profiles')
          .select('rol_id')
          .eq('id', adminId)
          .single();

      return response['rol_id'] == 3; // Solo administradores
    } catch (e) {
      return false;
    }
  }
}
