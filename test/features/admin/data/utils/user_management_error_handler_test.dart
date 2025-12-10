import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:donde_caigav2/features/admin/data/utils/user_management_error_handler.dart';
import 'package:donde_caigav2/features/admin/data/models/admin_action_result.dart';

void main() {
  group('UserManagementErrorHandler', () {
    group('handleError', () {
      test('should handle AuthException correctly', () {
        final authError = AuthException('Unauthorized', statusCode: '401');
        final result = UserManagementErrorHandler.handleError(authError);

        expect(result.isFailure, isTrue);
        expect(result.errorCode, equals('UNAUTHORIZED'));
        expect(result.message, contains('No tienes permisos'));
      });

      test('should handle PostgrestException correctly', () {
        final postgrestError = PostgrestException(
          message: 'RLS policy violation',
          code: 'PGRST301',
        );
        final result = UserManagementErrorHandler.handleError(postgrestError);

        expect(result.isFailure, isTrue);
        expect(result.errorCode, equals('RLS_VIOLATION'));
        expect(result.message, contains('No tienes permisos'));
      });

      test('should handle network errors correctly', () {
        final networkError = Exception('SocketException: Connection failed');
        final result = UserManagementErrorHandler.handleError(networkError);

        expect(result.isFailure, isTrue);
        expect(result.errorCode, equals('NETWORK_ERROR'));
        expect(result.message, contains('conexión'));
      });

      test('should handle custom application errors', () {
        final adminPermissionError = AdminPermissionError();
        final result = UserManagementErrorHandler.handleError(
          adminPermissionError,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorCode, equals('PERMISSION_DENIED'));
      });

      test('should handle UserNotFoundError', () {
        final userNotFoundError = UserNotFoundError();
        final result = UserManagementErrorHandler.handleError(
          userNotFoundError,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorCode, equals('USER_NOT_FOUND'));
      });

      test('should handle AdminTargetError', () {
        final adminTargetError = AdminTargetError();
        final result = UserManagementErrorHandler.handleError(adminTargetError);

        expect(result.isFailure, isTrue);
        expect(result.errorCode, equals('ADMIN_TARGET_ERROR'));
      });

      test('should handle SelfManagementError', () {
        final selfManagementError = SelfManagementError();
        final result = UserManagementErrorHandler.handleError(
          selfManagementError,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorCode, equals('SELF_MANAGEMENT_ERROR'));
      });

      test('should handle ViajeroPromotionError', () {
        final viajeroPromotionError = ViajeroPromotionError();
        final result = UserManagementErrorHandler.handleError(
          viajeroPromotionError,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorCode, equals('VIAJERO_PROMOTION_DENIED'));
      });

      test('should handle UserAlreadyBlockedError', () {
        final userAlreadyBlockedError = UserAlreadyBlockedError();
        final result = UserManagementErrorHandler.handleError(
          userAlreadyBlockedError,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorCode, equals('USER_ALREADY_BLOCKED'));
      });

      test('should handle UserAlreadyActiveError', () {
        final userAlreadyActiveError = UserAlreadyActiveError();
        final result = UserManagementErrorHandler.handleError(
          userAlreadyActiveError,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorCode, equals('USER_ALREADY_ACTIVE'));
      });

      test('should handle UserAlreadyViajeroError', () {
        final userAlreadyViajeroError = UserAlreadyViajeroError();
        final result = UserManagementErrorHandler.handleError(
          userAlreadyViajeroError,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorCode, equals('USER_ALREADY_VIAJERO'));
      });

      test('should handle MissingReasonError', () {
        final missingReasonError = MissingReasonError();
        final result = UserManagementErrorHandler.handleError(
          missingReasonError,
        );

        expect(result.isFailure, isTrue);
        expect(result.errorCode, equals('MISSING_REASON'));
      });

      test('should handle unknown errors', () {
        final unknownError = Exception('Some unknown error');
        final result = UserManagementErrorHandler.handleError(unknownError);

        expect(result.isFailure, isTrue);
        expect(result.errorCode, equals('UNKNOWN_ERROR'));
        expect(result.message, contains('Some unknown error'));
      });
    });

    group('_handleAuthError', () {
      test('should handle 401 status code', () {
        final authError = AuthException('Unauthorized', statusCode: '401');
        final result = UserManagementErrorHandler.handleError(authError);

        expect(result.errorCode, equals('UNAUTHORIZED'));
        expect(result.message, contains('No tienes permisos'));
      });

      test('should handle 403 status code', () {
        final authError = AuthException('Forbidden', statusCode: '403');
        final result = UserManagementErrorHandler.handleError(authError);

        expect(result.errorCode, equals('FORBIDDEN'));
        expect(result.message, contains('Acceso denegado'));
      });

      test('should handle 422 status code', () {
        final authError = AuthException('Invalid data', statusCode: '422');
        final result = UserManagementErrorHandler.handleError(authError);

        expect(result.errorCode, equals('INVALID_DATA'));
        expect(result.message, contains('Datos inválidos'));
      });

      test('should handle unknown auth status codes', () {
        final authError = AuthException('Unknown error', statusCode: '500');
        final result = UserManagementErrorHandler.handleError(authError);

        expect(result.errorCode, equals('AUTH_ERROR'));
        expect(result.message, contains('Error de autenticación'));
      });
    });

    group('_handlePostgrestError', () {
      test('should handle RLS policy violations', () {
        final postgrestError = PostgrestException(
          message: 'RLS policy violation detected',
          code: 'PGRST301',
        );
        final result = UserManagementErrorHandler.handleError(postgrestError);

        expect(result.errorCode, equals('RLS_VIOLATION'));
        expect(result.message, contains('No tienes permisos'));
      });

      test('should handle foreign key violations', () {
        final postgrestError = PostgrestException(
          message: 'foreign key constraint violates',
          code: 'PGRST400',
        );
        final result = UserManagementErrorHandler.handleError(postgrestError);

        expect(result.errorCode, equals('FOREIGN_KEY_VIOLATION'));
        expect(result.message, contains('dependencias de datos'));
      });

      test('should handle duplicate entries', () {
        final postgrestError = PostgrestException(
          message: 'duplicate key value violates unique constraint',
          code: 'PGRST409',
        );
        final result = UserManagementErrorHandler.handleError(postgrestError);

        expect(result.errorCode, equals('DUPLICATE_ENTRY'));
        expect(result.message, contains('Ya existe un registro'));
      });

      test('should handle not found errors', () {
        final postgrestError = PostgrestException(
          message: 'not found',
          code: 'PGRST116',
        );
        final result = UserManagementErrorHandler.handleError(postgrestError);

        expect(result.errorCode, equals('USER_NOT_FOUND'));
      });

      test('should handle generic database errors', () {
        final postgrestError = PostgrestException(
          message: 'Generic database error',
          code: 'PGRST500',
        );
        final result = UserManagementErrorHandler.handleError(postgrestError);

        expect(result.errorCode, equals('DATABASE_ERROR'));
        expect(result.message, contains('Error en la base de datos'));
      });
    });

    group('isRecoverableError', () {
      test('should identify recoverable errors from AdminActionResult', () {
        final networkError = AdminActionResult.networkError();
        final permissionError = AdminActionResult.permissionDenied();

        expect(
          UserManagementErrorHandler.isRecoverableError(networkError),
          isTrue,
        );
        expect(
          UserManagementErrorHandler.isRecoverableError(permissionError),
          isFalse,
        );
      });

      test('should identify recoverable errors from exception strings', () {
        final socketException = Exception('SocketException: Connection failed');
        final timeoutException = Exception('TimeoutException: Request timeout');
        final authException = Exception('Authentication failed');

        expect(
          UserManagementErrorHandler.isRecoverableError(socketException),
          isTrue,
        );
        expect(
          UserManagementErrorHandler.isRecoverableError(timeoutException),
          isTrue,
        );
        expect(
          UserManagementErrorHandler.isRecoverableError(authException),
          isFalse,
        );
      });
    });

    group('getFriendlyMessage', () {
      test('should return success message for successful results', () {
        final successResult = AdminActionResult.success(
          message: 'Operation completed',
        );
        final message = UserManagementErrorHandler.getFriendlyMessage(
          successResult,
        );

        expect(message, equals('Operation completed'));
      });

      test('should return friendly messages for specific error codes', () {
        final networkError = AdminActionResult.networkError();
        final permissionError = AdminActionResult.permissionDenied();
        final userNotFoundError = AdminActionResult.userNotFound();

        expect(
          UserManagementErrorHandler.getFriendlyMessage(networkError),
          contains('conexión'),
        );
        expect(
          UserManagementErrorHandler.getFriendlyMessage(permissionError),
          contains('permisos'),
        );
        expect(
          UserManagementErrorHandler.getFriendlyMessage(userNotFoundError),
          contains('no existe'),
        );
      });

      test('should return original message for unknown error codes', () {
        final unknownError = AdminActionResult.failure(
          message: 'Custom error message',
          errorCode: 'UNKNOWN_CODE',
        );
        final message = UserManagementErrorHandler.getFriendlyMessage(
          unknownError,
        );

        expect(message, equals('Custom error message'));
      });

      test('should return default message for empty messages', () {
        final emptyError = AdminActionResult.failure(
          message: '',
          errorCode: 'UNKNOWN_CODE',
        );
        final message = UserManagementErrorHandler.getFriendlyMessage(
          emptyError,
        );

        expect(message, contains('error inesperado'));
      });
    });

    group('getMessageColor', () {
      test('should return green for success results', () {
        final successResult = AdminActionResult.success(message: 'Success');
        final color = UserManagementErrorHandler.getMessageColor(successResult);

        expect(color, equals(const Color(0xFF4CAF50)));
      });

      test('should return appropriate colors for different error types', () {
        final networkError = AdminActionResult.networkError();
        final permissionError = AdminActionResult.permissionDenied();
        final warningError = AdminActionResult.userAlreadyBlocked();

        expect(
          UserManagementErrorHandler.getMessageColor(networkError),
          equals(const Color(0xFFFF9800)), // Orange
        );
        expect(
          UserManagementErrorHandler.getMessageColor(permissionError),
          equals(const Color(0xFFF44336)), // Red
        );
        expect(
          UserManagementErrorHandler.getMessageColor(warningError),
          equals(const Color(0xFFFF9800)), // Orange
        );
      });

      test('should return red for unknown error codes', () {
        final unknownError = AdminActionResult.failure(
          message: 'Unknown error',
          errorCode: 'UNKNOWN_CODE',
        );
        final color = UserManagementErrorHandler.getMessageColor(unknownError);

        expect(color, equals(const Color(0xFFF44336))); // Red
      });
    });

    group('getMessageIcon', () {
      test('should return check_circle for success results', () {
        final successResult = AdminActionResult.success(message: 'Success');
        final icon = UserManagementErrorHandler.getMessageIcon(successResult);

        expect(icon, equals(Icons.check_circle));
      });

      test('should return appropriate icons for different error types', () {
        final networkError = AdminActionResult.networkError();
        final permissionError = AdminActionResult.permissionDenied();
        final userNotFoundError = AdminActionResult.userNotFound();
        final missingReasonError = AdminActionResult.missingReason();

        expect(
          UserManagementErrorHandler.getMessageIcon(networkError),
          equals(Icons.wifi_off),
        );
        expect(
          UserManagementErrorHandler.getMessageIcon(permissionError),
          equals(Icons.lock),
        );
        expect(
          UserManagementErrorHandler.getMessageIcon(userNotFoundError),
          equals(Icons.person_off),
        );
        expect(
          UserManagementErrorHandler.getMessageIcon(missingReasonError),
          equals(Icons.edit_note),
        );
      });

      test('should return error icon for unknown error codes', () {
        final unknownError = AdminActionResult.failure(
          message: 'Unknown error',
          errorCode: 'UNKNOWN_CODE',
        );
        final icon = UserManagementErrorHandler.getMessageIcon(unknownError);

        expect(icon, equals(Icons.error));
      });
    });
  });
}
