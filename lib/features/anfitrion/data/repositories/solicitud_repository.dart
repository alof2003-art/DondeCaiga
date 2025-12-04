import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/solicitud_anfitrion.dart';

class SolicitudRepository {
  final SupabaseClient _supabase;

  SolicitudRepository(this._supabase);

  /// Crear una nueva solicitud para ser anfitrión
  Future<void> crearSolicitud({
    required String usuarioId,
    required String fotoSelfieUrl,
    required String fotoPropiedadUrl,
    String? mensaje,
  }) async {
    await _supabase.from('solicitudes_anfitrion').insert({
      'usuario_id': usuarioId,
      'foto_selfie_url': fotoSelfieUrl,
      'foto_propiedad_url': fotoPropiedadUrl,
      'mensaje': mensaje,
      'estado': 'pendiente',
    });
  }

  /// Obtener todas las solicitudes pendientes (para admin)
  Future<List<SolicitudAnfitrion>> obtenerSolicitudesPendientes() async {
    final response = await _supabase
        .from('solicitudes_anfitrion')
        .select('''
          *,
          users_profiles!solicitudes_anfitrion_usuario_id_fkey(nombre, email)
        ''')
        .eq('estado', 'pendiente')
        .order('fecha_solicitud', ascending: false);

    return (response as List).map((json) {
      // Combinar datos de la solicitud con datos del usuario
      final solicitud = Map<String, dynamic>.from(json);
      final usuario = json['users_profiles'];

      if (usuario != null) {
        solicitud['nombre_usuario'] = usuario['nombre'];
        solicitud['email_usuario'] = usuario['email'];
      }

      return SolicitudAnfitrion.fromJson(solicitud);
    }).toList();
  }

  /// Obtener solicitud de un usuario específico
  Future<SolicitudAnfitrion?> obtenerSolicitudUsuario(String usuarioId) async {
    try {
      final response = await _supabase
          .from('solicitudes_anfitrion')
          .select()
          .eq('usuario_id', usuarioId)
          .order('fecha_solicitud', ascending: false)
          .limit(1)
          .single();

      return SolicitudAnfitrion.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Aprobar solicitud (admin)
  Future<void> aprobarSolicitud({
    required String solicitudId,
    required String adminId,
    required String usuarioId,
  }) async {
    // 1. Actualizar estado de la solicitud
    await _supabase
        .from('solicitudes_anfitrion')
        .update({
          'estado': 'aprobada',
          'fecha_respuesta': DateTime.now().toIso8601String(),
          'admin_revisor_id': adminId,
        })
        .eq('id', solicitudId);

    // 2. Cambiar rol del usuario a anfitrión (rol_id = 2)
    await _supabase
        .from('users_profiles')
        .update({'rol_id': 2})
        .eq('id', usuarioId);
  }

  /// Rechazar solicitud (admin)
  Future<void> rechazarSolicitud({
    required String solicitudId,
    required String adminId,
    String? comentario,
  }) async {
    await _supabase
        .from('solicitudes_anfitrion')
        .update({
          'estado': 'rechazada',
          'fecha_respuesta': DateTime.now().toIso8601String(),
          'admin_revisor_id': adminId,
          'comentario_admin': comentario,
        })
        .eq('id', solicitudId);
  }
}
