import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notificacion.dart';

class NotificacionesRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener todas las notificaciones del usuario
  Future<List<Notificacion>> obtenerNotificaciones({
    FiltroNotificaciones? filtro,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('🔍 Obteniendo notificaciones para usuario: ${user.id}');

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint('📊 Respuesta de Supabase: ${response.length} notificaciones');

      final notificaciones = (response as List).map((json) {
        debugPrint('📝 Procesando notificación: ${json['title']}');
        return Notificacion.fromJson(json);
      }).toList();

      debugPrint('✅ Notificaciones procesadas: ${notificaciones.length}');

      return notificaciones;
    } catch (e) {
      debugPrint('❌ Error al obtener notificaciones: $e');
      throw Exception('Error al obtener notificaciones: $e');
    }
  }

  // Contar notificaciones no leídas
  Future<int> contarNoLeidas() async {
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      throw Exception('Error al contar notificaciones no leídas: $e');
    }
  }

  // Marcar notificación como leída
  Future<void> marcarComoLeida(String notificacionId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificacionId);
    } catch (e) {
      throw Exception('Error al marcar notificación como leída: $e');
    }
  }

  // Marcar todas como leídas
  Future<void> marcarTodasComoLeidas() async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _supabase.auth.currentUser!.id)
          .eq('is_read', false);
    } catch (e) {
      throw Exception(
        'Error al marcar todas las notificaciones como leídas: $e',
      );
    }
  }

  // Eliminar notificación
  Future<void> eliminarNotificacion(String notificacionId) async {
    try {
      await _supabase.from('notifications').delete().eq('id', notificacionId);
    } catch (e) {
      throw Exception('Error al eliminar notificación: $e');
    }
  }

  // Crear nueva notificación (para uso interno del sistema)
  Future<void> crearNotificacion({
    required String usuarioId,
    required TipoNotificacion tipo,
    required String titulo,
    required String mensaje,
    Map<String, dynamic>? datos,
    String? imagenUrl,
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': usuarioId,
        'type': tipo.name,
        'title': titulo,
        'message': mensaje,
        'metadata': datos,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al crear notificación: $e');
    }
  }

  // Suscribirse a notificaciones en tiempo real
  RealtimeChannel suscribirseANotificaciones(
    Function(Notificacion) onNotificacion,
  ) {
    final channel = _supabase
        .channel('notificaciones_${_supabase.auth.currentUser!.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _supabase.auth.currentUser!.id,
          ),
          callback: (payload) {
            final notificacion = Notificacion.fromJson(payload.newRecord);
            onNotificacion(notificacion);
          },
        )
        .subscribe();

    return channel;
  }

  // Obtener notificaciones agrupadas por tipo
  Future<Map<TipoNotificacion, List<Notificacion>>>
  obtenerNotificacionesAgrupadas() async {
    try {
      final notificaciones = await obtenerNotificaciones();
      final Map<TipoNotificacion, List<Notificacion>> agrupadas = {};

      for (final notificacion in notificaciones) {
        if (!agrupadas.containsKey(notificacion.tipo)) {
          agrupadas[notificacion.tipo] = [];
        }
        agrupadas[notificacion.tipo]!.add(notificacion);
      }

      return agrupadas;
    } catch (e) {
      throw Exception('Error al obtener notificaciones agrupadas: $e');
    }
  }
}
