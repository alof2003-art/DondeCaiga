class AdminAction {
  final String adminId;
  final String targetUserId;
  final String actionType;
  final Map<String, dynamic> actionData;
  final String? reason;
  final DateTime timestamp;

  // Constantes para tipos de acción
  static const String degradeRoleType = 'degrade_role';
  static const String blockAccountType = 'block_account';
  static const String unblockAccountType = 'unblock_account';

  AdminAction({
    required this.adminId,
    required this.targetUserId,
    required this.actionType,
    required this.actionData,
    this.reason,
    required this.timestamp,
  });

  factory AdminAction.fromJson(Map<String, dynamic> json) {
    return AdminAction(
      adminId: json['admin_id'] as String,
      targetUserId: json['target_user_id'] as String,
      actionType: json['action_type'] as String,
      actionData: Map<String, dynamic>.from(json['action_data'] ?? {}),
      reason: json['reason'] as String?,
      timestamp: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'admin_id': adminId,
      'target_user_id': targetUserId,
      'action_type': actionType,
      'action_data': actionData,
      'reason': reason,
      'created_at': timestamp.toIso8601String(),
    };
  }

  // Factory methods para crear acciones específicas
  factory AdminAction.degradeRole({
    required String adminId,
    required String targetUserId,
    required String reason,
    required int previousRole,
    required int newRole,
  }) {
    return AdminAction(
      adminId: adminId,
      targetUserId: targetUserId,
      actionType: degradeRoleType,
      actionData: {'previous_role': previousRole, 'new_role': newRole},
      reason: reason,
      timestamp: DateTime.now(),
    );
  }

  factory AdminAction.blockAccount({
    required String adminId,
    required String targetUserId,
    required String reason,
  }) {
    return AdminAction(
      adminId: adminId,
      targetUserId: targetUserId,
      actionType: blockAccountType,
      actionData: {'previous_status': 'activo', 'new_status': 'bloqueado'},
      reason: reason,
      timestamp: DateTime.now(),
    );
  }

  factory AdminAction.unblockAccount({
    required String adminId,
    required String targetUserId,
  }) {
    return AdminAction(
      adminId: adminId,
      targetUserId: targetUserId,
      actionType: unblockAccountType,
      actionData: {'previous_status': 'bloqueado', 'new_status': 'activo'},
      reason: null,
      timestamp: DateTime.now(),
    );
  }

  // Getters para facilitar el acceso a datos específicos
  bool get isDegradeRole => actionType == degradeRoleType;
  bool get isBlockAccount => actionType == blockAccountType;
  bool get isUnblockAccount => actionType == unblockAccountType;

  String get actionDisplayName {
    switch (actionType) {
      case degradeRoleType:
        return 'Degradar Rol';
      case blockAccountType:
        return 'Bloquear Cuenta';
      case unblockAccountType:
        return 'Desbloquear Cuenta';
      default:
        return 'Acción Desconocida';
    }
  }
}
