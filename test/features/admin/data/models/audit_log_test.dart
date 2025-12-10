import 'package:flutter_test/flutter_test.dart';
import 'package:donde_caigav2/features/admin/data/models/audit_log.dart';
import 'package:donde_caigav2/features/admin/data/models/admin_action.dart';

void main() {
  group('AuditLog', () {
    test('should create AuditLog with all required fields', () {
      final timestamp = DateTime.now();
      final auditLog = AuditLog(
        id: 'audit-123',
        adminId: 'admin-456',
        adminNombre: 'Admin User',
        targetUserId: 'user-789',
        targetUserNombre: 'Target User',
        actionType: 'degrade_role',
        actionData: {'previous_role': 2, 'new_role': 1},
        reason: 'Policy violation',
        timestamp: timestamp,
        wasSuccessful: true,
      );

      expect(auditLog.id, equals('audit-123'));
      expect(auditLog.adminId, equals('admin-456'));
      expect(auditLog.adminNombre, equals('Admin User'));
      expect(auditLog.targetUserId, equals('user-789'));
      expect(auditLog.targetUserNombre, equals('Target User'));
      expect(auditLog.actionType, equals('degrade_role'));
      expect(auditLog.reason, equals('Policy violation'));
      expect(auditLog.wasSuccessful, isTrue);
    });

    test('should serialize to JSON correctly', () {
      final timestamp = DateTime.now();
      final auditLog = AuditLog(
        id: 'audit-123',
        adminId: 'admin-456',
        adminNombre: 'Admin User',
        targetUserId: 'user-789',
        targetUserNombre: 'Target User',
        actionType: 'block_account',
        actionData: {'previous_status': 'activo'},
        reason: 'Spam behavior',
        timestamp: timestamp,
        wasSuccessful: true,
      );

      final json = auditLog.toJson();

      expect(json['id'], equals('audit-123'));
      expect(json['admin_id'], equals('admin-456'));
      expect(json['admin_nombre'], equals('Admin User'));
      expect(json['target_user_id'], equals('user-789'));
      expect(json['target_user_nombre'], equals('Target User'));
      expect(json['action_type'], equals('block_account'));
      expect(json['reason'], equals('Spam behavior'));
      expect(json['was_successful'], isTrue);
    });

    test('should deserialize from JSON correctly', () {
      final timestamp = DateTime.now();
      final json = {
        'id': 'audit-123',
        'admin_id': 'admin-456',
        'admin_nombre': 'Admin User',
        'target_user_id': 'user-789',
        'target_user_nombre': 'Target User',
        'action_type': 'unblock_account',
        'action_data': {'previous_status': 'bloqueado'},
        'reason': null,
        'created_at': timestamp.toIso8601String(),
        'was_successful': true,
      };

      final auditLog = AuditLog.fromJson(json);

      expect(auditLog.id, equals('audit-123'));
      expect(auditLog.adminNombre, equals('Admin User'));
      expect(auditLog.targetUserNombre, equals('Target User'));
      expect(auditLog.actionType, equals('unblock_account'));
      expect(auditLog.reason, isNull);
      expect(auditLog.wasSuccessful, isTrue);
      expect(auditLog.timestamp, equals(timestamp));
    });

    test('should handle missing names in JSON', () {
      final json = {
        'id': 'audit-123',
        'admin_id': 'admin-456',
        'target_user_id': 'user-789',
        'action_type': 'block_account',
        'created_at': DateTime.now().toIso8601String(),
      };

      final auditLog = AuditLog.fromJson(json);

      expect(auditLog.adminNombre, equals('Administrador'));
      expect(auditLog.targetUserNombre, equals('Usuario'));
      expect(auditLog.wasSuccessful, isTrue); // Default value
    });

    test('should return correct action display names', () {
      final degradeLog = AuditLog(
        id: '1',
        adminId: 'admin',
        adminNombre: 'Admin',
        targetUserId: 'user',
        targetUserNombre: 'User',
        actionType: 'degrade_role',
        actionData: {},
        timestamp: DateTime.now(),
        wasSuccessful: true,
      );

      final blockLog = AuditLog(
        id: '2',
        adminId: 'admin',
        adminNombre: 'Admin',
        targetUserId: 'user',
        targetUserNombre: 'User',
        actionType: 'block_account',
        actionData: {},
        timestamp: DateTime.now(),
        wasSuccessful: true,
      );

      final unblockLog = AuditLog(
        id: '3',
        adminId: 'admin',
        adminNombre: 'Admin',
        targetUserId: 'user',
        targetUserNombre: 'User',
        actionType: 'unblock_account',
        actionData: {},
        timestamp: DateTime.now(),
        wasSuccessful: true,
      );

      expect(degradeLog.actionDisplayName, equals('Degradar Rol'));
      expect(blockLog.actionDisplayName, equals('Bloquear Cuenta'));
      expect(unblockLog.actionDisplayName, equals('Desbloquear Cuenta'));
    });

    test('should return correct status icons', () {
      final successLog = AuditLog(
        id: '1',
        adminId: 'admin',
        adminNombre: 'Admin',
        targetUserId: 'user',
        targetUserNombre: 'User',
        actionType: 'block_account',
        actionData: {},
        timestamp: DateTime.now(),
        wasSuccessful: true,
      );

      final failureLog = AuditLog(
        id: '2',
        adminId: 'admin',
        adminNombre: 'Admin',
        targetUserId: 'user',
        targetUserNombre: 'User',
        actionType: 'block_account',
        actionData: {},
        timestamp: DateTime.now(),
        wasSuccessful: false,
      );

      expect(successLog.statusIcon, equals('✅'));
      expect(failureLog.statusIcon, equals('❌'));
    });

    test('should return correct action descriptions', () {
      final degradeLog = AuditLog(
        id: '1',
        adminId: 'admin',
        adminNombre: 'Admin',
        targetUserId: 'user',
        targetUserNombre: 'User',
        actionType: 'degrade_role',
        actionData: {'previous_role': 2, 'new_role': 1},
        timestamp: DateTime.now(),
        wasSuccessful: true,
      );

      final blockLog = AuditLog(
        id: '2',
        adminId: 'admin',
        adminNombre: 'Admin',
        targetUserId: 'user',
        targetUserNombre: 'User',
        actionType: 'block_account',
        actionData: {},
        timestamp: DateTime.now(),
        wasSuccessful: true,
      );

      final failedLog = AuditLog(
        id: '3',
        adminId: 'admin',
        adminNombre: 'Admin',
        targetUserId: 'user',
        targetUserNombre: 'User',
        actionType: 'unblock_account',
        actionData: {},
        timestamp: DateTime.now(),
        wasSuccessful: false,
      );

      expect(
        degradeLog.actionDescription,
        equals('Cambió rol de Anfitrión a Viajero'),
      );
      expect(blockLog.actionDescription, equals('Bloqueó la cuenta'));
      expect(failedLog.actionDescription, equals('Falló: Desbloquear Cuenta'));
    });

    test('should format timestamp correctly', () {
      final now = DateTime.now();

      final recentLog = AuditLog(
        id: '1',
        adminId: 'admin',
        adminNombre: 'Admin',
        targetUserId: 'user',
        targetUserNombre: 'User',
        actionType: 'block_account',
        actionData: {},
        timestamp: now.subtract(const Duration(minutes: 30)),
        wasSuccessful: true,
      );

      final oldLog = AuditLog(
        id: '2',
        adminId: 'admin',
        adminNombre: 'Admin',
        targetUserId: 'user',
        targetUserNombre: 'User',
        actionType: 'block_account',
        actionData: {},
        timestamp: now.subtract(const Duration(days: 2)),
        wasSuccessful: true,
      );

      expect(recentLog.formattedTimestamp, contains('minuto'));
      expect(oldLog.formattedTimestamp, contains('día'));
    });

    test('should create AuditLog from AdminAction', () {
      final action = AdminAction.blockAccount(
        adminId: 'admin-123',
        targetUserId: 'user-456',
        reason: 'Spam behavior',
      );

      final auditLog = AuditLog.fromAdminAction(
        id: 'audit-789',
        action: action,
        adminNombre: 'Admin User',
        targetUserNombre: 'Target User',
        wasSuccessful: true,
      );

      expect(auditLog.id, equals('audit-789'));
      expect(auditLog.adminId, equals('admin-123'));
      expect(auditLog.targetUserId, equals('user-456'));
      expect(auditLog.actionType, equals('block_account'));
      expect(auditLog.reason, equals('Spam behavior'));
      expect(auditLog.wasSuccessful, isTrue);
    });

    test('should handle null action data', () {
      final json = {
        'id': 'audit-123',
        'admin_id': 'admin-456',
        'target_user_id': 'user-789',
        'action_type': 'block_account',
        'action_data': null,
        'created_at': DateTime.now().toIso8601String(),
      };

      final auditLog = AuditLog.fromJson(json);
      expect(auditLog.actionData, isEmpty);
    });
  });
}
