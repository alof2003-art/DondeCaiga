import 'package:flutter_test/flutter_test.dart';
import 'package:donde_caigav2/features/admin/data/models/admin_action_result.dart';

void main() {
  group('AdminActionResult', () {
    test('should create success result', () {
      final result = AdminActionResult.success(
        message: 'Operation completed successfully',
        data: {'userId': '123'},
      );

      expect(result.success, isTrue);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.message, equals('Operation completed successfully'));
      expect(result.data?['userId'], equals('123'));
      expect(result.errorCode, isNull);
      expect(result.hasErrorCode, isFalse);
      expect(result.hasData, isTrue);
    });

    test('should create failure result', () {
      final result = AdminActionResult.failure(
        message: 'Operation failed',
        errorCode: 'TEST_ERROR',
        data: {'details': 'error details'},
      );

      expect(result.success, isFalse);
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.message, equals('Operation failed'));
      expect(result.errorCode, equals('TEST_ERROR'));
      expect(result.hasErrorCode, isTrue);
      expect(result.getData<String>('details'), equals('error details'));
    });

    test('should create permission denied error', () {
      final result = AdminActionResult.permissionDenied();

      expect(result.isFailure, isTrue);
      expect(
        result.message,
        equals('No tienes permisos para realizar esta acción'),
      );
      expect(result.errorCode, equals('PERMISSION_DENIED'));
    });

    test('should create user not found error', () {
      final result = AdminActionResult.userNotFound();

      expect(result.isFailure, isTrue);
      expect(
        result.message,
        equals('El usuario seleccionado no existe o fue eliminado'),
      );
      expect(result.errorCode, equals('USER_NOT_FOUND'));
    });

    test('should create network error', () {
      final result = AdminActionResult.networkError();

      expect(result.isFailure, isTrue);
      expect(
        result.message,
        equals('Error de conexión. Verifica tu internet e intenta nuevamente'),
      );
      expect(result.errorCode, equals('NETWORK_ERROR'));
    });

    test('should create admin target error', () {
      final result = AdminActionResult.adminTargetError();

      expect(result.isFailure, isTrue);
      expect(
        result.message,
        equals('No tienes permisos para gestionar esta cuenta'),
      );
      expect(result.errorCode, equals('ADMIN_TARGET_ERROR'));
    });

    test('should create self management error', () {
      final result = AdminActionResult.selfManagementError();

      expect(result.isFailure, isTrue);
      expect(result.message, equals('No puedes gestionar tu propia cuenta'));
      expect(result.errorCode, equals('SELF_MANAGEMENT_ERROR'));
    });

    test('should create viajero promotion error', () {
      final result = AdminActionResult.viajeroPromotionError();

      expect(result.isFailure, isTrue);
      expect(
        result.message,
        equals(
          'Los viajeros deben usar el proceso de verificación normal para ser anfitriones',
        ),
      );
      expect(result.errorCode, equals('VIAJERO_PROMOTION_DENIED'));
    });

    test('should create user already blocked error', () {
      final result = AdminActionResult.userAlreadyBlocked();

      expect(result.isFailure, isTrue);
      expect(result.message, equals('El usuario ya está bloqueado'));
      expect(result.errorCode, equals('USER_ALREADY_BLOCKED'));
    });

    test('should create user already active error', () {
      final result = AdminActionResult.userAlreadyActive();

      expect(result.isFailure, isTrue);
      expect(result.message, equals('El usuario ya está activo'));
      expect(result.errorCode, equals('USER_ALREADY_ACTIVE'));
    });

    test('should create user already viajero error', () {
      final result = AdminActionResult.userAlreadyViajero();

      expect(result.isFailure, isTrue);
      expect(result.message, equals('El usuario ya es viajero'));
      expect(result.errorCode, equals('USER_ALREADY_VIAJERO'));
    });

    test('should create missing reason error', () {
      final result = AdminActionResult.missingReason();

      expect(result.isFailure, isTrue);
      expect(
        result.message,
        equals('Debes proporcionar un motivo para esta acción'),
      );
      expect(result.errorCode, equals('MISSING_REASON'));
    });

    test('should create unknown error without details', () {
      final result = AdminActionResult.unknownError();

      expect(result.isFailure, isTrue);
      expect(
        result.message,
        equals('Ocurrió un error inesperado. Intenta nuevamente'),
      );
      expect(result.errorCode, equals('UNKNOWN_ERROR'));
    });

    test('should create unknown error with details', () {
      final result = AdminActionResult.unknownError(
        'Database connection failed',
      );

      expect(result.isFailure, isTrue);
      expect(
        result.message,
        equals('Ocurrió un error inesperado: Database connection failed'),
      );
      expect(result.errorCode, equals('UNKNOWN_ERROR'));
    });

    test('should get data with correct type', () {
      final result = AdminActionResult.success(
        message: 'Success',
        data: {'count': 42, 'name': 'test', 'active': true},
      );

      expect(result.getData<int>('count'), equals(42));
      expect(result.getData<String>('name'), equals('test'));
      expect(result.getData<bool>('active'), isTrue);
      expect(result.getData<String>('nonexistent'), isNull);
    });

    test('should handle null data correctly', () {
      final result = AdminActionResult.success(message: 'Success');

      expect(result.hasData, isFalse);
      expect(result.getData<String>('any'), isNull);
    });

    test('should implement equality correctly', () {
      final result1 = AdminActionResult.success(message: 'Test');
      final result2 = AdminActionResult.success(message: 'Test');
      final result3 = AdminActionResult.failure(
        message: 'Test',
        errorCode: 'ERROR',
      );

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });

    test('should implement toString correctly', () {
      final result = AdminActionResult.failure(
        message: 'Test error',
        errorCode: 'TEST_CODE',
      );

      expect(result.toString(), contains('AdminActionResult'));
      expect(result.toString(), contains('success: false'));
      expect(result.toString(), contains('Test error'));
      expect(result.toString(), contains('TEST_CODE'));
    });
  });
}
