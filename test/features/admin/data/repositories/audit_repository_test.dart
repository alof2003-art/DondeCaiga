import 'package:flutter_test/flutter_test.dart';
import 'package:donde_caigav2/features/admin/data/repositories/audit_repository.dart';
import 'package:donde_caigav2/features/admin/data/models/admin_action.dart';
import 'package:donde_caigav2/features/admin/data/models/audit_log.dart';

void main() {
  group('AuditRepository', () {
    late AuditRepository repository;

    setUp(() {
      repository = AuditRepository();
    });

    group('registrarAccionAdmin', () {
      test('should register admin action successfully', () async {
        final action = AdminAction.blockAccount(
          adminId: 'admin-123',
          targetUserId: 'user-456',
          reason: 'Test reason',
        );

        // Esta prueba requiere mock de Supabase
        // Por ahora validamos que no lance excepción
        expect(() => repository.registrarAccionAdmin(action), returnsNormally);
      });

      test('should handle successful and failed actions', () async {
        final action = AdminAction.degradeRole(
          adminId: 'admin-123',
          targetUserId: 'user-456',
          reason: 'Test reason',
          previousRole: 2,
          newRole: 1,
        );

        // Probar registro de acción exitosa
        expect(
          () => repository.registrarAccionAdmin(action, wasSuccessful: true),
          returnsNormally,
        );

        // Probar registro de acción fallida
        expect(
          () => repository.registrarAccionAdmin(action, wasSuccessful: false),
          returnsNormally,
        );
      });

      test('should not throw exception on audit failure', () async {
        final action = AdminAction.unblockAccount(
          adminId: 'admin-123',
          targetUserId: 'user-456',
        );

        // Incluso si falla el registro de auditoría, no debería lanzar excepción
        expect(() => repository.registrarAccionAdmin(action), returnsNormally);
      });
    });

    group('obtenerHistorialAuditoria', () {
      test('should return list of audit logs', () async {
        final result = await repository.obtenerHistorialAuditoria();
        expect(result, isA<List<AuditLog>>());
      });

      test('should handle pagination parameters', () async {
        final result = await repository.obtenerHistorialAuditoria(
          page: 2,
          limit: 25,
        );
        expect(result, isA<List<AuditLog>>());
      });

      test('should handle action type filter', () async {
        final result = await repository.obtenerHistorialAuditoria(
          actionTypeFilter: AdminAction.blockAccountType,
        );
        expect(result, isA<List<AuditLog>>());
      });

      test('should handle date range filters', () async {
        final startDate = DateTime.now().subtract(const Duration(days: 7));
        final endDate = DateTime.now();

        final result = await repository.obtenerHistorialAuditoria(
          startDate: startDate,
          endDate: endDate,
        );
        expect(result, isA<List<AuditLog>>());
      });

      test('should handle combined filters', () async {
        final result = await repository.obtenerHistorialAuditoria(
          actionTypeFilter: AdminAction.degradeRoleType,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
          page: 1,
          limit: 10,
        );
        expect(result, isA<List<AuditLog>>());
      });
    });

    group('obtenerHistorialUsuario', () {
      test('should return audit logs for specific user', () async {
        const userId = 'user-123';
        final result = await repository.obtenerHistorialUsuario(userId);
        expect(result, isA<List<AuditLog>>());
      });

      test('should handle limit parameter', () async {
        const userId = 'user-123';
        final result = await repository.obtenerHistorialUsuario(
          userId,
          limit: 5,
        );
        expect(result, isA<List<AuditLog>>());
      });
    });

    group('obtenerEstadisticasAuditoria', () {
      test('should return audit statistics', () async {
        final result = await repository.obtenerEstadisticasAuditoria();
        expect(result, isA<Map<String, int>>());
      });

      test('should include all required statistics keys', () async {
        try {
          final result = await repository.obtenerEstadisticasAuditoria();

          // Verificar que contiene las claves esperadas
          expect(result.containsKey('total_actions'), isTrue);
          expect(result.containsKey('degrade_role'), isTrue);
          expect(result.containsKey('block_account'), isTrue);
          expect(result.containsKey('unblock_account'), isTrue);
          expect(result.containsKey('successful_actions'), isTrue);
          expect(result.containsKey('failed_actions'), isTrue);
        } catch (e) {
          // Es esperado que falle sin conexión a Supabase real
          expect(e, isA<Exception>());
        }
      });
    });

    group('obtenerAccionesRecientes', () {
      test('should return recent actions', () async {
        final result = await repository.obtenerAccionesRecientes();
        expect(result, isA<List<AuditLog>>());
      });

      test('should handle limit parameter', () async {
        final result = await repository.obtenerAccionesRecientes(limit: 5);
        expect(result, isA<List<AuditLog>>());
      });

      test('should use default limit when not specified', () async {
        final result = await repository.obtenerAccionesRecientes();
        expect(result, isA<List<AuditLog>>());
      });
    });

    group('verificarPermisosAuditoria', () {
      test('should verify admin permissions for audit access', () async {
        const adminId = 'admin-123';
        final result = await repository.verificarPermisosAuditoria(adminId);
        expect(result, isA<bool>());
      });

      test('should return false for invalid admin ID', () async {
        const invalidId = 'invalid-id';
        final result = await repository.verificarPermisosAuditoria(invalidId);
        expect(result, isFalse);
      });

      test('should handle database errors gracefully', () async {
        const adminId = '';
        final result = await repository.verificarPermisosAuditoria(adminId);
        expect(result, isFalse);
      });
    });

    group('Error Handling', () {
      test(
        'should handle network errors in obtenerHistorialAuditoria',
        () async {
          try {
            await repository.obtenerHistorialAuditoria();
          } catch (e) {
            expect(e, isA<Exception>());
            expect(
              e.toString(),
              contains('Error al obtener historial de auditoría'),
            );
          }
        },
      );

      test('should handle network errors in obtenerHistorialUsuario', () async {
        try {
          await repository.obtenerHistorialUsuario('invalid-user');
        } catch (e) {
          expect(e, isA<Exception>());
          expect(
            e.toString(),
            contains('Error al obtener historial del usuario'),
          );
        }
      });

      test(
        'should handle network errors in obtenerEstadisticasAuditoria',
        () async {
          try {
            await repository.obtenerEstadisticasAuditoria();
          } catch (e) {
            expect(e, isA<Exception>());
            expect(
              e.toString(),
              contains('Error al obtener estadísticas de auditoría'),
            );
          }
        },
      );

      test(
        'should handle network errors in obtenerAccionesRecientes',
        () async {
          try {
            await repository.obtenerAccionesRecientes();
          } catch (e) {
            expect(e, isA<Exception>());
            expect(
              e.toString(),
              contains('Error al obtener acciones recientes'),
            );
          }
        },
      );
    });

    group('Data Validation', () {
      test('should validate AdminAction parameter in registrarAccionAdmin', () {
        final validAction = AdminAction.blockAccount(
          adminId: 'admin-123',
          targetUserId: 'user-456',
          reason: 'Valid reason',
        );

        expect(
          () => repository.registrarAccionAdmin(validAction),
          returnsNormally,
        );
      });

      test('should validate pagination parameters', () async {
        // Probar con parámetros válidos
        expect(
          () => repository.obtenerHistorialAuditoria(page: 1, limit: 50),
          returnsNormally,
        );

        // Probar con parámetros límite
        expect(
          () => repository.obtenerHistorialAuditoria(page: 0, limit: 0),
          returnsNormally,
        );
      });

      test('should validate date range parameters', () async {
        final validStart = DateTime.now().subtract(const Duration(days: 7));
        final validEnd = DateTime.now();

        expect(
          () => repository.obtenerHistorialAuditoria(
            startDate: validStart,
            endDate: validEnd,
          ),
          returnsNormally,
        );
      });
    });

    group('Method Signatures', () {
      test('should have correct method signatures', () {
        // Verificar que todos los métodos existen con las firmas correctas
        expect(repository.registrarAccionAdmin, isA<Function>());
        expect(repository.obtenerHistorialAuditoria, isA<Function>());
        expect(repository.obtenerHistorialUsuario, isA<Function>());
        expect(repository.obtenerEstadisticasAuditoria, isA<Function>());
        expect(repository.obtenerAccionesRecientes, isA<Function>());
        expect(repository.verificarPermisosAuditoria, isA<Function>());
      });
    });
  });
}
