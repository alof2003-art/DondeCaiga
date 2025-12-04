import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UserRepository {
  final SupabaseClient _supabase;

  UserRepository(this._supabase);

  /// Crea un perfil de usuario en la base de datos
  Future<UserProfile> createUserProfile({
    required String userId,
    required String email,
    required String nombre,
    String? telefono,
    String? fotoPerfilUrl,
    String? cedulaUrl,
  }) async {
    final data = {
      'id': userId,
      'email': email,
      'nombre': nombre,
      'telefono': telefono,
      'foto_perfil_url': fotoPerfilUrl,
      'cedula_url': cedulaUrl,
      'email_verified': false,
    };

    final response = await _supabase
        .from('users_profiles')
        .insert(data)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  /// Obtiene el perfil de un usuario por su ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users_profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      // Si no existe el perfil, retornar null
      return null;
    }
  }

  /// Actualiza el perfil de un usuario
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    print('💾 [REPOSITORY] Actualizando perfil del usuario: $userId');
    print('📝 [REPOSITORY] Datos a actualizar: $updates');

    try {
      final response = await _supabase
          .from('users_profiles')
          .update(updates)
          .eq('id', userId)
          .select();

      print('✅ [REPOSITORY] Actualización exitosa');
      print('📊 [REPOSITORY] Respuesta de Supabase: $response');
    } catch (e) {
      print('❌ [REPOSITORY] Error en actualización: $e');
      print('🔍 [REPOSITORY] Tipo de error: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Marca el email como verificado
  Future<void> markEmailAsVerified(String userId) async {
    await _supabase
        .from('users_profiles')
        .update({'email_verified': true})
        .eq('id', userId);
  }

  /// Actualiza la URL de la foto de perfil
  Future<void> updateProfilePhotoUrl(String userId, String photoUrl) async {
    await updateUserProfile(userId, {'foto_perfil_url': photoUrl});
  }

  /// Actualiza la URL del documento de identidad
  Future<void> updateIdDocumentUrl(String userId, String documentUrl) async {
    await updateUserProfile(userId, {'cedula_url': documentUrl});
  }

  /// Elimina un perfil de usuario
  Future<void> deleteUserProfile(String userId) async {
    await _supabase.from('users_profiles').delete().eq('id', userId);
  }
}
