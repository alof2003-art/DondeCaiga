import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:donde_caigav2/features/chat/data/models/mensaje.dart';

class MensajeRepository {
  final SupabaseClient _supabase;

  MensajeRepository(this._supabase);

  /// Enviar un mensaje
  Future<void> enviarMensaje({
    required String reservaId,
    required String remitenteId,
    required String mensaje,
  }) async {
    await _supabase.from('mensajes').insert({
      'reserva_id': reservaId,
      'remitente_id': remitenteId,
      'mensaje': mensaje,
      'leido': false,
      'created_at': DateTime.now().toUtc().toIso8601String(), // Forzar UTC
    });
  }

  /// Obtener mensajes de una reserva
  Future<List<Mensaje>> obtenerMensajes(String reservaId) async {
    final response = await _supabase
        .from('mensajes')
        .select()
        .eq('reserva_id', reservaId)
        .order('created_at', ascending: true); // Orden cronológico correcto

    return (response as List).map((json) => Mensaje.fromJson(json)).toList();
  }

  /// Suscribirse a mensajes en tiempo real
  RealtimeChannel suscribirseAMensajes(
    String reservaId,
    Function(Mensaje) onNuevoMensaje,
  ) {
    final channel = _supabase
        .channel('mensajes_$reservaId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'reserva_id',
            value: reservaId,
          ),
          callback: (payload) {
            final mensaje = Mensaje.fromJson(payload.newRecord);
            onNuevoMensaje(mensaje);
          },
        )
        .subscribe();

    return channel;
  }

  /// Marcar mensaje como leído
  Future<void> marcarComoLeido(String mensajeId) async {
    await _supabase
        .from('mensajes')
        .update({'leido': true})
        .eq('id', mensajeId);
  }
}
