import 'package:flutter_test/flutter_test.dart';
import 'package:donde_caigav2/features/admin/data/models/admin_action.dart';

void main() {
  group('AdminAction', () {
    test('should create AdminAction with all required fields', () {
      final timestamp = DateTime.now();
      final action = AdminAction(
        adminId: 'admin-123',
        targetUserId: 'user-456',
        actionType: AdminAction.degradeRoleType,
        actionData: {'previous_role': 2, 'new_role': 1},
        reason: 'Test reason',
        timestamp: timestamp,
      );

      expect(action.adminId, equals('admin-123'));
      expect(action.targetUserId, equals('user-456'));
      expect(action.actionType, equals(AdminAction.degradeRoleType));
      expect(action.actionData['previous_role'], equals(2));
      expect(action.reason, equals('Test reason'));
      expect(action.timestamp, equals(timestamp));
    });

    test('should serialize to JSON correctly', () {
      final timestamp = DateTime.now();
      final action = AdminAction(
        adminId: 'admin-123',
        targetUserId: 'user-456',
        actionType: AdminAction.blockAccountType,
        actionData: {'previous_status': 'activo'},
        reason: 'Inappropriate behavior',
        timestamp: timestamp,
      );

      final json = action.toJson();

      expect(json['admin_id'], equals('admin-123'));
      expect(json['target_user_id'], equals('user-456'));
      expect(json['action_type'], equals(AdminAction.blockAccountType));
      expect(json['action_data']['previous_status'], equals('activo'));
      expect(json['reason'], equals('Inappropriate behavior'));
      expect(json['created_at'], equals(timestamp.toIso8601String()));
    });

    test('should deserialize from JSON correctly', () {
      final timestamp = DateTime.now();
      final json = {
        'admin_id': 'admin-123',
        'target_user_id': 'user-456',
        'action_type': AdminAction.unblockAccountType,
        'action_data': {'previous_status': 'bloqueado'},
        'reason': null,
        'created_at': timestamp.toIso8601String(),
      };

      final action = AdminAction.fromJson(json);

      expect(action.adminId, equals('admin-123'));
      expect(action.targetUserId, equals('user-456'));
      expect(action.actionType, equals(AdminAction.unblockAccountType));
      expect(action.actionData['previous_status'], equals('bloqueado'));
      expect(action.reason, isNull);
      expect(action.timestamp, equals(timestamp));
    });

    test('should create degrade role action with factory method', () {
      final action = AdminAction.degradeRole(
        adminId: 'admin-123',
        targetUserId: 'user-456',
        reason: 'Policy violation',
        previousRole: 2,
        newRole: 1,
      );

      expect(action.actionType, equals(AdminAction.degradeRoleType));
      expect(action.reason, equals('Policy violation'));
      expect(action.actionData['previous_role'], equals(2));
      expect(action.actionData['new_role'], equals(1));
      expect(action.isDegradeRole, isTrue);
      expect(action.isBlockAccount, isFalse);
    });

    test('should create block account action with factory method', () {
      final action = AdminAction.blockAccount(
        adminId: 'admin-123',
        targetUserId: 'user-456',
        reason: 'Spam behavior',
      );

      expect(action.actionType, equals(AdminAction.blockAccountType));
      expect(action.reason, equals('Spam behavior'));
      expect(action.actionData['previous_status'], equals('activo'));
      expect(action.actionData['new_status'], equals('bloqueado'));
      expect(action.isBlockAccount, isTrue);
      expect(action.isDegradeRole, isFalse);
    });

    test('should create unblock account action with factory method', () {
      final action = AdminAction.unblockAccount(
        adminId: 'admin-123',
        targetUserId: 'user-456',
      );

      expect(action.actionType, equals(AdminAction.unblockAccountType));
      expect(action.reason, isNull);
      expect(action.actionData['previous_status'], equals('bloqueado'));
      expect(action.actionData['new_status'], equals('activo'));
      expect(action.isUnblockAccount, isTrue);
      expect(action.isBlockAccount, isFalse);
    });

    test('should return correct display names', () {
      final degradeAction = AdminAction.degradeRole(
        adminId: 'admin-123',
        targetUserId: 'user-456',
        reason: 'Test',
        previousRole: 2,
        newRole: 1,
      );

      final blockAction = AdminAction.blockAccount(
        adminId: 'admin-123',
        targetUserId: 'user-456',
        reason: 'Test',
      );

      final unblockAction = AdminAction.unblockAccount(
        adminId: 'admin-123',
        targetUserId: 'user-456',
      );

      expect(degradeAction.actionDisplayName, equals('Degradar Rol'));
      expect(blockAction.actionDisplayName, equals('Bloquear Cuenta'));
      expect(unblockAction.actionDisplayName, equals('Desbloquear Cuenta'));
    });

    test('should handle empty action data', () {
      final json = {
        'admin_id': 'admin-123',
        'target_user_id': 'user-456',
        'action_type': AdminAction.degradeRoleType,
        'action_data': null,
        'reason': 'Test',
        'created_at': DateTime.now().toIso8601String(),
      };

      final action = AdminAction.fromJson(json);
      expect(action.actionData, isEmpty);
    });
  });
}
