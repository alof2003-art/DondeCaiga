import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_stats.dart';
import '../models/admin_action_result.dart';
import '../models/admin_action.dart';
import '../../../auth/data/models/user_profile.dart';
import 'audit_repository.dart';

class AdminRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuditRepository _auditRepository = AuditRepository();

  // Obtener estadísticas del sistema
  Future<AdminStats> obtenerEstadisticas() async {
    try {
      // Obtener total de usuarios
      final totalUsuariosResponse = await _supabase
          .from('users_profiles')
          .select('id')
          .count(CountOption.exact);

      // Obtener usuarios por rol
      final viajeros = await _supabase
          .from('users_profiles')
          .select('id')
          .eq('rol_id', 1)
          .count(CountOption.exact);

      final anfitriones = await _supabase
          .from('users_profiles')
          .select('id')
          .eq('rol_id', 2)
          .count(CountOption.exact);

      final administradores = await _supabase
          .from('users_profiles')
          .select('id')
          .eq('rol_id', 3)
          .count(CountOption.exact);

      // Obtener total de propiedades
      final totalPropiedades = await _supabase
          .from('propiedades')
          .select('id')
          .count(CountOption.exact);

      return AdminStats(
        totalUsuarios: totalUsuariosResponse.count,
        totalViajeros: viajeros.count,
        totalAnfitriones: anfitriones.count,
        totalAdministradores: administradores.count,
        totalAlojamientos: totalPropiedades.count,
      );
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // Obtener lista de todos los usuarios con su rol
  Future<List<UserProfile>> obtenerTodosLosUsuarios() async {
    try {
      final response = await _supabase
          .from('users_profiles')
          .select('''
            id,
            email,
            nombre,
            telefono,
            foto_perfil_url,
            created_at,
            updated_at,
            email_verified,
            rol_id,
            estado_cuenta
          ''')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  // ============================================
  // NUEVAS FUNCIONES DE GESTIÓN DE USUARIOS
  // ============================================

  /// Obtener usuarios gestionables (excluye administradores)
  Future<List<UserProfile>> obtenerUsuariosGestionables({
    String? searchQuery,
    int? roleFilter,
    String? statusFilter,
  }) async {
    try {
      var query = _supabase
          .from('users_profiles')
          .select('''
            id,
            email,
            nombre,
            telefono,
            foto_perfil_url,
            created_at,
            updated_at,
            email_verified,
            rol_id,
            estado_cuenta
          ''')
          .neq('rol_id', 3) // Excluir administradores
          .order('created_at', ascending: false);

      final response = await query;
      var users = (response as List)
          .map((json) => UserProfile.fromJson(json))
          .toList();

      // Aplicar filtros en el cliente
      if (roleFilter != null) {
        users = users.where((user) => user.rolId == roleFilter).toList();
      }

      if (statusFilter != null) {
        users = users
            .where((user) => user.estadoCuenta == statusFilter)
            .toList();
      }

      // Aplicar filtro de búsqueda en el cliente
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        users = users.where((user) {
          return user.nombre.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query);
        }).toList();
      }

      return users;
    } catch (e) {
      throw Exception('Error al obtener usuarios gestionables: $e');
    }
  }

  /// Validar permisos administrativos
  Future<bool> validarPermisosAdmin(String adminId, String targetUserId) async {
    try {
      // Verificar que el usuario actual es administrador
      final adminResponse = await _supabase
          .from('users_profiles')
          .select('rol_id')
          .eq('id', adminId)
          .single();

      if (adminResponse['rol_id'] != 3) {
        return false; // No es administrador
      }

      // Verificar que no intenta gestionarse a sí mismo
      if (adminId == targetUserId) {
        return false; // Auto-gestión no permitida
      }

      // Verificar que el usuario objetivo no es administrador
      final targetResponse = await _supabase
          .from('users_profiles')
          .select('rol_id')
          .eq('id', targetUserId)
          .single();

      if (targetResponse['rol_id'] == 3) {
        return false; // No puede gestionar otros administradores
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Degradar anfitrión a viajero
  Future<AdminActionResult> degradarAnfitrionAViajero(
    String userId,
    String adminId,
    String reason,
  ) async {
    try {
      // Validar permisos
      if (!await validarPermisosAdmin(adminId, userId)) {
        return AdminActionResult.permissionDenied();
      }

      // Verificar que el motivo no esté vacío
      if (reason.trim().isEmpty) {
        return AdminActionResult.missingReason();
      }

      // Obtener información del usuario
      final userResponse = await _supabase
          .from('users_profiles')
          .select('rol_id, estado_cuenta, nombre')
          .eq('id', userId)
          .single();

      // Verificar que el usuario existe
      if (userResponse.isEmpty) {
        return AdminActionResult.userNotFound();
      }

      // Verificar que el usuario es anfitrión
      if (userResponse['rol_id'] != 2) {
        return AdminActionResult.userAlreadyViajero();
      }

      // Verificar que la cuenta está activa
      if (userResponse['estado_cuenta'] != 'activo') {
        return AdminActionResult.failure(
          message: 'No se puede degradar una cuenta bloqueada',
          errorCode: 'ACCOUNT_BLOCKED',
        );
      }

      // Crear acción de auditoría
      final action = AdminAction.degradeRole(
        adminId: adminId,
        targetUserId: userId,
        reason: reason,
        previousRole: 2,
        newRole: 1,
      );

      // Iniciar transacción
      await _supabase.rpc('begin_transaction');

      try {
        // 1. Cambiar rol a viajero
        await _supabase
            .from('users_profiles')
            .update({'rol_id': 1})
            .eq('id', userId);

        // 2. Desactivar todas las propiedades del usuario
        await _supabase
            .from('propiedades')
            .update({'estado': 'inactivo'})
            .eq('anfitrion_id', userId)
            .eq('estado', 'activo');

        // 3. Eliminar solicitudes de anfitrión existentes
        await _supabase
            .from('solicitudes_anfitrion')
            .delete()
            .eq('usuario_id', userId);

        // 4. Crear nueva solicitud de anfitrión pendiente
        await _supabase.from('solicitudes_anfitrion').insert({
          'usuario_id': userId,
          'estado': 'pendiente',
          'comentario':
              'Solicitud creada automáticamente después de degradación de rol por administrador',
        });

        // 5. Registrar en auditoría
        await _auditRepository.registrarAccionAdmin(
          action,
          wasSuccessful: true,
        );

        // Confirmar transacción
        await _supabase.rpc('commit_transaction');

        return AdminActionResult.success(
          message:
              'Usuario degradado exitosamente de Anfitrión a Viajero. Se creó una nueva solicitud de verificación.',
          data: {
            'previous_role': 2,
            'new_role': 1,
            'user_name': userResponse['nombre'],
          },
        );
      } catch (e) {
        // Revertir transacción en caso de error
        await _supabase.rpc('rollback_transaction');

        // Registrar fallo en auditoría
        await _auditRepository.registrarAccionAdmin(
          action,
          wasSuccessful: false,
        );

        rethrow;
      }
    } catch (e) {
      return AdminActionResult.unknownError(e.toString());
    }
  }

  /// Bloquear cuenta de usuario
  Future<AdminActionResult> bloquearCuentaUsuario(
    String userId,
    String reason,
    String adminId,
  ) async {
    try {
      // Validar permisos
      if (!await validarPermisosAdmin(adminId, userId)) {
        return AdminActionResult.permissionDenied();
      }

      // Verificar que el motivo no esté vacío
      if (reason.trim().isEmpty) {
        return AdminActionResult.missingReason();
      }

      // Obtener información del usuario
      final userResponse = await _supabase
          .from('users_profiles')
          .select('estado_cuenta, nombre, rol_id')
          .eq('id', userId)
          .single();

      // Verificar que el usuario existe
      if (userResponse.isEmpty) {
        return AdminActionResult.userNotFound();
      }

      // Verificar que la cuenta no está ya bloqueada
      if (userResponse['estado_cuenta'] == 'bloqueado') {
        return AdminActionResult.userAlreadyBlocked();
      }

      // Crear acción de auditoría
      final action = AdminAction.blockAccount(
        adminId: adminId,
        targetUserId: userId,
        reason: reason,
      );

      // Iniciar transacción
      await _supabase.rpc('begin_transaction');

      try {
        // 1. Bloquear cuenta
        await _supabase
            .from('users_profiles')
            .update({'estado_cuenta': 'bloqueado'})
            .eq('id', userId);

        // 2. Si es anfitrión, desactivar todas sus propiedades
        if (userResponse['rol_id'] == 2) {
          await _supabase
              .from('propiedades')
              .update({'estado': 'inactivo'})
              .eq('anfitrion_id', userId)
              .eq('estado', 'activo');
        }

        // 3. Cancelar reservas pendientes del usuario
        await _supabase
            .from('reservas')
            .update({'estado': 'cancelada'})
            .eq('viajero_id', userId)
            .eq('estado', 'pendiente');

        // 4. Registrar en auditoría
        await _auditRepository.registrarAccionAdmin(
          action,
          wasSuccessful: true,
        );

        // Confirmar transacción
        await _supabase.rpc('commit_transaction');

        return AdminActionResult.success(
          message:
              'Cuenta bloqueada exitosamente. Se cancelaron las reservas pendientes y se desactivaron las propiedades.',
          data: {'user_name': userResponse['nombre'], 'reason': reason},
        );
      } catch (e) {
        // Revertir transacción en caso de error
        await _supabase.rpc('rollback_transaction');

        // Registrar fallo en auditoría
        await _auditRepository.registrarAccionAdmin(
          action,
          wasSuccessful: false,
        );

        rethrow;
      }
    } catch (e) {
      return AdminActionResult.unknownError(e.toString());
    }
  }

  /// Desbloquear cuenta de usuario
  Future<AdminActionResult> desbloquearCuentaUsuario(
    String userId,
    String adminId,
  ) async {
    try {
      // Validar permisos
      if (!await validarPermisosAdmin(adminId, userId)) {
        return AdminActionResult.permissionDenied();
      }

      // Obtener información del usuario
      final userResponse = await _supabase
          .from('users_profiles')
          .select('estado_cuenta, nombre')
          .eq('id', userId)
          .single();

      // Verificar que el usuario existe
      if (userResponse.isEmpty) {
        return AdminActionResult.userNotFound();
      }

      // Verificar que la cuenta está bloqueada
      if (userResponse['estado_cuenta'] != 'bloqueado') {
        return AdminActionResult.userAlreadyActive();
      }

      // Crear acción de auditoría
      final action = AdminAction.unblockAccount(
        adminId: adminId,
        targetUserId: userId,
      );

      try {
        // Desbloquear cuenta
        await _supabase
            .from('users_profiles')
            .update({'estado_cuenta': 'activo'})
            .eq('id', userId);

        // Registrar en auditoría
        await _auditRepository.registrarAccionAdmin(
          action,
          wasSuccessful: true,
        );

        return AdminActionResult.success(
          message:
              'Cuenta desbloqueada exitosamente. El usuario puede acceder nuevamente.',
          data: {'user_name': userResponse['nombre']},
        );
      } catch (e) {
        // Registrar fallo en auditoría
        await _auditRepository.registrarAccionAdmin(
          action,
          wasSuccessful: false,
        );

        rethrow;
      }
    } catch (e) {
      return AdminActionResult.unknownError(e.toString());
    }
  }

  /// Eliminar cuenta de usuario permanentemente
  Future<AdminActionResult> eliminarCuentaUsuario(
    String userId,
    String reason,
    String adminId,
  ) async {
    try {
      // Validar permisos
      if (!await validarPermisosAdmin(adminId, userId)) {
        return AdminActionResult.permissionDenied();
      }

      // Verificar que el motivo no esté vacío
      if (reason.trim().isEmpty) {
        return AdminActionResult.missingReason();
      }

      // Obtener información del usuario
      final userResponse = await _supabase
          .from('users_profiles')
          .select('nombre, rol_id, foto_perfil_url')
          .eq('id', userId)
          .single();

      // Verificar que el usuario existe
      if (userResponse.isEmpty) {
        return AdminActionResult.userNotFound();
      }

      // Crear acción de auditoría ANTES de eliminar
      final action = AdminAction.deleteAccount(
        adminId: adminId,
        targetUserId: userId,
        reason: reason,
      );

      // Registrar en auditoría ANTES de eliminar
      await _auditRepository.registrarAccionAdmin(action, wasSuccessful: true);

      try {
        // Iniciar eliminación completa
        await _eliminarDatosCompletos(userId);

        return AdminActionResult.success(
          message:
              'Cuenta de ${userResponse['nombre']} eliminada permanentemente. Todos los datos asociados han sido borrados.',
          data: {
            'user_name': userResponse['nombre'],
            'reason': reason,
            'deleted_at': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        // Registrar fallo en auditoría
        await _auditRepository.registrarAccionAdmin(
          AdminAction.deleteAccount(
            adminId: adminId,
            targetUserId: userId,
            reason: reason,
          ),
          wasSuccessful: false,
        );

        return AdminActionResult.failure(
          message: 'Error al eliminar la cuenta: ${e.toString()}',
          errorCode: 'DELETE_FAILED',
        );
      }
    } catch (e) {
      return AdminActionResult.unknownError(e.toString());
    }
  }

  /// Método privado para eliminar todos los datos del usuario
  Future<void> _eliminarDatosCompletos(String userId) async {
    // 1. Eliminar todas las reservas del usuario (como viajero)
    await _supabase.from('reservas').delete().eq('viajero_id', userId);

    // 2. Eliminar todas las reservas en propiedades del usuario (como anfitrión)
    final propiedadesUsuario = await _supabase
        .from('propiedades')
        .select('id')
        .eq('anfitrion_id', userId);

    for (final propiedad in propiedadesUsuario) {
      await _supabase
          .from('reservas')
          .delete()
          .eq('propiedad_id', propiedad['id']);
    }

    // 3. Eliminar todas las reseñas escritas por el usuario
    await _supabase.from('resenas').delete().eq('viajero_id', userId);

    // 4. Eliminar todas las reseñas recibidas en propiedades del usuario
    for (final propiedad in propiedadesUsuario) {
      await _supabase
          .from('resenas')
          .delete()
          .eq('propiedad_id', propiedad['id']);
    }

    // 5. Eliminar fotos de propiedades del storage
    for (final propiedad in propiedadesUsuario) {
      final fotosPropiedad = await _supabase
          .from('fotos_propiedades')
          .select('url_foto')
          .eq('propiedad_id', propiedad['id']);

      for (final foto in fotosPropiedad) {
        final fileName = foto['url_foto'].toString().split('/').last;
        await _supabase.storage.from('propiedades-fotos').remove([fileName]);
      }

      // Eliminar registros de fotos de propiedades
      await _supabase
          .from('fotos_propiedades')
          .delete()
          .eq('propiedad_id', propiedad['id']);
    }

    // 6. Eliminar todas las propiedades del usuario
    await _supabase.from('propiedades').delete().eq('anfitrion_id', userId);

    // 7. Eliminar todos los mensajes de chat del usuario
    await _supabase.from('mensajes').delete().eq('remitente_id', userId);

    // 9. Eliminar todas las solicitudes de anfitrión del usuario
    await _supabase
        .from('solicitudes_anfitrion')
        .delete()
        .eq('usuario_id', userId);

    // 10. Eliminar foto de perfil del storage
    final userProfile = await _supabase
        .from('users_profiles')
        .select('foto_perfil_url')
        .eq('id', userId)
        .single();

    if (userProfile['foto_perfil_url'] != null) {
      final fileName = userProfile['foto_perfil_url']
          .toString()
          .split('/')
          .last;
      await _supabase.storage.from('profile-photos').remove([fileName]);
    }

    // 11. Finalmente, eliminar el perfil del usuario
    await _supabase.from('users_profiles').delete().eq('id', userId);
  }
}
