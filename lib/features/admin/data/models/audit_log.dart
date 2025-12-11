import 'admin_action.dart';

class AuditLog {
  final String id;
  final String adminId;
  final String adminNombre;
  final String targetUserId;
  final String targetUserNombre;
  final String actionType;
  final Map<String, dynamic> actionData;
  final String? reason;
  final DateTime timestamp;
  final bool wasSuccessful;

  AuditLog({
    required this.id,
    required this.adminId,
    required this.adminNombre,
    required this.targetUserId,
    required this.targetUserNombre,
    required this.actionType,
    required this.actionData,
    this.reason,
    required this.timestamp,
    required this.wasSuccessful,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      adminId: json['admin_id'] as String,
      adminNombre: json['admin_nombre'] as String? ?? 'Administrador',
      targetUserId: json['target_user_id'] as String,
      targetUserNombre: json['target_user_nombre'] as String? ?? 'Usuario',
      actionType: json['action_type'] as String,
      actionData: Map<String, dynamic>.from(json['action_data'] ?? {}),
      reason: json['reason'] as String?,
      timestamp: DateTime.parse(json['created_at'] as String),
      wasSuccessful: json['was_successful'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_id': adminId,
      'admin_nombre': adminNombre,
      'target_user_id': targetUserId,
      'target_user_nombre': targetUserNombre,
      'action_type': actionType,
      'action_data': actionData,
      'reason': reason,
      'created_at': timestamp.toIso8601String(),
      'was_successful': wasSuccessful,
    };
  }

  // Getters para facilitar el acceso a información específica
  String get actionDisplayName {
    switch (actionType) {
      case 'degrade_role':
        return 'Degradar Rol';
      case 'block_account':
        return 'Bloquear Cuenta';
      case 'unblock_account':
        return 'Desbloquear Cuenta';
      default:
        return 'Acción Desconocida';
    }
  }

  String get statusIcon {
    return wasSuccessful ? '✅' : '❌';
  }

  String get actionDescription {
    if (!wasSuccessful) {
      return 'Falló: $actionDisplayName';
    }

    switch (actionType) {
      case 'degrade_role':
        final previousRole = actionData['previous_role'] == 2
            ? 'Anfitrión'
            : 'Viajero';
        final newRole = actionData['new_role'] == 1 ? 'Viajero' : 'Anfitrión';
        return 'Cambió rol de $previousRole a $newRole';
      case 'block_account':
        return 'Bloqueó la cuenta';
      case 'unblock_account':
        return 'Desbloqueó la cuenta';
      default:
        return actionDisplayName;
    }
  }

  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} día${difference.inDays > 1 ? 's' : ''} atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''} atrás';
    } else {
      return 'Hace un momento';
    }
  }

  // Método para crear un log de auditoría a partir de una acción
  factory AuditLog.fromAdminAction({
    required String id,
    required AdminAction action,
    required String adminNombre,
    required String targetUserNombre,
    required bool wasSuccessful,
  }) {
    return AuditLog(
      id: id,
      adminId: action.adminId,
      adminNombre: adminNombre,
      targetUserId: action.targetUserId,
      targetUserNombre: targetUserNombre,
      actionType: action.actionType,
      actionData: action.actionData,
      reason: action.reason,
      timestamp: action.timestamp,
      wasSuccessful: wasSuccessful,
    );
  }
}
