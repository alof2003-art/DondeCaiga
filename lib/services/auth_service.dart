import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/data/models/user_registration_data.dart';
import '../features/auth/data/repositories/user_repository.dart';
import 'storage_service.dart';
import '../core/utils/error_handler.dart';

class AuthService {
  final SupabaseClient _supabase;
  final StorageService _storage;
  final UserRepository _userRepository;

  AuthService(this._supabase, this._storage, this._userRepository);

  /// Stream de cambios en el estado de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Obtiene el usuario actual
  Future<User?> getCurrentUser() async {
    return _supabase.auth.currentUser;
  }

  /// Verifica si hay una sesión activa
  Future<bool> hasActiveSession() async {
    final session = _supabase.auth.currentSession;
    return session != null;
  }

  /// Verifica si el email del usuario actual está verificado
  Future<bool> isEmailVerified() async {
    final user = await getCurrentUser();
    if (user == null) return false;

    // Refrescar la sesión para obtener los datos más recientes
    await _supabase.auth.refreshSession();
    final refreshedUser = _supabase.auth.currentUser;

    return refreshedUser?.emailConfirmedAt != null;
  }

  /// Inicia sesión con email y contraseña
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Verificar si el email está verificado
      if (response.user != null && response.user!.emailConfirmedAt == null) {
        // Cerrar sesión si el email no está verificado
        await signOut();
        throw AuthException(
          'Por favor verifica tu email antes de iniciar sesión',
        );
      }

      // Verificar si la cuenta está bloqueada
      if (response.user != null) {
        final userProfile = await _userRepository.getUserProfile(
          response.user!.id,
        );

        if (userProfile != null && userProfile.estadoCuenta == 'bloqueado') {
          // Obtener el motivo del bloqueo desde la auditoría
          final blockReason = await _getBlockReason(response.user!.id);

          // Cerrar sesión inmediatamente
          await signOut();

          // Lanzar excepción con el motivo del bloqueo
          throw AccountBlockedException(blockReason);
        }
      }

      return response;
    } catch (e) {
      ErrorHandler.logError(e);
      rethrow;
    }
  }

  /// Obtiene el motivo del bloqueo desde la auditoría
  Future<String> _getBlockReason(String userId) async {
    try {
      // Usar función SQL que bypasa RLS
      final response = await _supabase.rpc(
        'get_block_reason',
        params: {'user_id': userId},
      );

      if (response != null && response.isNotEmpty) {
        final data = response.first;
        final reason = data['reason'] as String?;
        final dateStr = data['created_at'] as String?;

        if (dateStr != null) {
          final date = DateTime.parse(dateStr);
          final formattedDate = '${date.day}/${date.month}/${date.year}';

          return reason != null && reason.isNotEmpty
              ? 'Tu cuenta fue bloqueada el $formattedDate.\n\nMotivo: $reason\n\nContacta al administrador para más información.'
              : 'Tu cuenta fue bloqueada el $formattedDate.\n\nContacta al administrador para más información.';
        }
      }

      return 'Tu cuenta ha sido bloqueada.\n\nContacta al administrador para más información.';
    } catch (e) {
      print('Error obteniendo motivo de bloqueo: $e');
      return 'Tu cuenta ha sido bloqueada.\n\nContacta al administrador para más información.';
    }
  }

  /// Registra un nuevo usuario
  Future<AuthResponse> signUp(UserRegistrationData data) async {
    try {
      print('🚀 [AUTH] Iniciando registro de usuario...');

      // 1. Crear usuario en Supabase Auth con metadatos
      // El trigger automático creará el perfil básico en users_profiles
      print('📝 [AUTH] Creando usuario en Supabase Auth...');
      final authResponse = await _supabase.auth.signUp(
        email: data.email,
        password: data.password,
        data: {
          'nombre': data.nombre, // Esto se usa en el trigger
        },
      );

      if (authResponse.user == null) {
        throw AuthException('Error al crear la cuenta');
      }

      final userId = authResponse.user!.id;
      print('✅ [AUTH] Usuario creado con ID: $userId');

      // 2. Esperar un momento para que el trigger cree el perfil
      print('⏳ [AUTH] Esperando a que el trigger cree el perfil...');
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Subir foto de perfil si existe
      String? profilePhotoUrl;
      if (data.profilePhoto != null) {
        try {
          print('📸 [STORAGE] Subiendo foto de perfil...');
          profilePhotoUrl = await _storage.uploadProfilePhoto(
            data.profilePhoto!,
            userId,
          );
          print('✅ [STORAGE] Foto de perfil subida: $profilePhotoUrl');
        } catch (e) {
          print('❌ [STORAGE] Error al subir foto de perfil: $e');
          ErrorHandler.logError(e);
          // Continuar aunque falle la subida de la foto
        }
      } else {
        print('ℹ️ [STORAGE] No hay foto de perfil para subir');
      }

      // 4. Subir documento de identidad si existe
      String? idDocumentUrl;
      if (data.idDocument != null) {
        try {
          print('📄 [STORAGE] Subiendo documento de identidad...');
          idDocumentUrl = await _storage.uploadIdDocument(
            data.idDocument!,
            userId,
          );
          print('✅ [STORAGE] Documento subido: $idDocumentUrl');
        } catch (e) {
          print('❌ [STORAGE] Error al subir documento: $e');
          ErrorHandler.logError(e);
          // Continuar aunque falle la subida del documento
        }
      } else {
        print('ℹ️ [STORAGE] No hay documento para subir');
      }

      // 5. Actualizar el perfil con datos adicionales (teléfono, fotos)
      final updates = <String, dynamic>{};
      if (data.telefono != null && data.telefono!.isNotEmpty) {
        updates['telefono'] = data.telefono;
      }
      if (profilePhotoUrl != null) {
        updates['foto_perfil_url'] = profilePhotoUrl;
      }
      if (idDocumentUrl != null) {
        updates['cedula_url'] = idDocumentUrl;
      }

      if (updates.isNotEmpty) {
        try {
          print('💾 [DB] Actualizando perfil con: $updates');
          await _userRepository.updateUserProfile(userId, updates);
          print('✅ [DB] Perfil actualizado exitosamente');
        } catch (e) {
          print('❌ [DB] Error al actualizar perfil: $e');
          ErrorHandler.logError(e);
          // Continuar aunque falle la actualización
        }
      } else {
        print('ℹ️ [DB] No hay datos adicionales para actualizar');
      }

      // 6. Cerrar sesión automáticamente después del registro
      // El usuario debe verificar su email antes de iniciar sesión
      await signOut();

      return authResponse;
    } catch (e) {
      ErrorHandler.logError(e);
      rethrow;
    }
  }

  /// Cierra la sesión del usuario actual
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      ErrorHandler.logError(e);
      rethrow;
    }
  }

  /// Envía un email de recuperación de contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      ErrorHandler.logError(e);
      rethrow;
    }
  }

  /// Reenvía el email de verificación
  Future<void> resendVerificationEmail() async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        throw AuthException('No hay usuario autenticado');
      }

      await _supabase.auth.resend(type: OtpType.signup, email: user.email);
    } catch (e) {
      ErrorHandler.logError(e);
      rethrow;
    }
  }
}
