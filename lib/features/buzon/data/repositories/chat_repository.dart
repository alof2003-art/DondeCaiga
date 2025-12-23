import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../reservas/data/models/reserva.dart';
import '../models/reserva_chat_info.dart';

class ChatRepository {
  final SupabaseClient _supabase;

  ChatRepository(this._supabase);

  /// Obtener reservas vigentes del usuario como viajero
  Future<List<ReservaChatInfo>> obtenerReservasViajeroVigentes(
    String userId,
  ) async {
    final ahora = DateTime.now();
    final ahoraStr = ahora.toIso8601String();

    final response = await _supabase
        .from('reservas')
        .select('''
          *,
          propiedades!reservas_propiedad_id_fkey(
            titulo,
            foto_principal_url,
            anfitrion_id,
            users_profiles!propiedades_anfitrion_id_fkey(nombre, foto_perfil_url)
          )
        ''')
        .eq('viajero_id', userId)
        .eq('estado', 'confirmada') // ✅ Solo reservas confirmadas
        .gte('fecha_fin', ahoraStr)
        .order('fecha_inicio', ascending: true)
        .limit(50);

    return await _convertirAReservaChatInfo(response as List, userId);
  }

  /// Obtener reservas pasadas del usuario como viajero
  Future<List<ReservaChatInfo>> obtenerReservasViajeroPasadas(
    String userId,
  ) async {
    final ahora = DateTime.now();
    final ahoraStr = ahora.toIso8601String();

    final response = await _supabase
        .from('reservas')
        .select('''
          *,
          propiedades!reservas_propiedad_id_fkey(
            titulo,
            foto_principal_url,
            anfitrion_id,
            users_profiles!propiedades_anfitrion_id_fkey(nombre, foto_perfil_url)
          )
        ''')
        .eq('viajero_id', userId)
        .inFilter('estado', [
          'completada',
          'confirmada',
        ]) // ✅ Incluir confirmadas que ya pasaron
        .lt('fecha_fin', ahoraStr)
        .order('fecha_fin', ascending: false);

    return await _convertirAReservaChatInfo(response as List, userId);
  }

  /// Obtener reservas vigentes en propiedades del usuario como anfitrión
  Future<List<ReservaChatInfo>> obtenerReservasAnfitrionVigentes(
    String userId,
  ) async {
    final ahora = DateTime.now();
    final ahoraStr = ahora.toIso8601String();

    // Primero obtener las propiedades del usuario
    final propiedadesResponse = await _supabase
        .from('propiedades')
        .select('id')
        .eq('anfitrion_id', userId);

    final propiedadIds = (propiedadesResponse as List)
        .map((p) => p['id'] as String)
        .toList();

    if (propiedadIds.isEmpty) {
      return [];
    }

    final response = await _supabase
        .from('reservas')
        .select('''
          *,
          propiedades!reservas_propiedad_id_fkey(titulo, foto_principal_url),
          users_profiles!reservas_viajero_id_fkey(nombre, foto_perfil_url)
        ''')
        .inFilter('propiedad_id', propiedadIds)
        .eq('estado', 'confirmada') // ✅ Solo reservas confirmadas
        .gte('fecha_fin', ahoraStr)
        .order('fecha_inicio', ascending: true);

    return await _convertirAReservaChatInfo(response as List, userId);
  }

  /// Obtener reservas pasadas en propiedades del usuario como anfitrión
  Future<List<ReservaChatInfo>> obtenerReservasAnfitrionPasadas(
    String userId,
  ) async {
    final ahora = DateTime.now();
    final ahoraStr = ahora.toIso8601String();

    // Primero obtener las propiedades del usuario
    final propiedadesResponse = await _supabase
        .from('propiedades')
        .select('id, titulo')
        .eq('anfitrion_id', userId);

    final propiedadIds = (propiedadesResponse as List)
        .map((p) => p['id'] as String)
        .toList();

    if (propiedadIds.isEmpty) {
      return [];
    }

    final response = await _supabase
        .from('reservas')
        .select('''
          *,
          propiedades!reservas_propiedad_id_fkey(titulo, foto_principal_url),
          users_profiles!reservas_viajero_id_fkey(nombre, foto_perfil_url)
        ''')
        .inFilter('propiedad_id', propiedadIds)
        .inFilter('estado', [
          'completada',
          'confirmada',
        ]) // ✅ Incluir confirmadas que ya pasaron
        .lt('fecha_fin', ahoraStr)
        .order('fecha_fin', ascending: false);

    return await _convertirAReservaChatInfo(response as List, userId);
  }

  /// Obtener todas las reservas del usuario categorizadas
  Future<Map<String, List<ReservaChatInfo>>> obtenerReservasCategorizada(
    String userId,
  ) async {
    final futures = await Future.wait([
      obtenerReservasViajeroVigentes(userId),
      obtenerReservasViajeroPasadas(userId),
      obtenerReservasAnfitrionVigentes(userId),
      obtenerReservasAnfitrionPasadas(userId),
    ]);

    return {
      'viajeroVigentes': futures[0],
      'viajeroPasadas': futures[1],
      'anfitrionVigentes': futures[2],
      'anfitrionPasadas': futures[3],
    };
  }

  /// Verificar si el usuario es anfitrión (tiene propiedades)
  Future<bool> esAnfitrion(String userId) async {
    final response = await _supabase
        .from('propiedades')
        .select('id')
        .eq('anfitrion_id', userId)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  /// Obtener la reserva vigente actual del usuario como viajero (si existe)
  Future<ReservaChatInfo?> obtenerReservaVigenteActual(String userId) async {
    final ahora = DateTime.now();
    final ahoraStr = ahora.toIso8601String();

    try {
      final response = await _supabase
          .from('reservas')
          .select('''
            *,
            propiedades!reservas_propiedad_id_fkey(
              titulo,
              foto_principal_url,
              anfitrion_id,
              users_profiles!propiedades_anfitrion_id_fkey(nombre, foto_perfil_url)
            )
          ''')
          .eq('viajero_id', userId)
          .eq('estado', 'confirmada')
          .lte('fecha_inicio', ahoraStr)
          .gte('fecha_fin', ahoraStr)
          .order('fecha_inicio', ascending: true)
          .limit(1);

      if ((response as List).isEmpty) {
        return null;
      }

      final reservasInfo = await _convertirAReservaChatInfo(response, userId);
      return reservasInfo.isNotEmpty ? reservasInfo.first : null;
    } catch (e) {
      return null;
    }
  }

  /// Método privado para convertir respuesta de Supabase a ReservaChatInfo
  Future<List<ReservaChatInfo>> _convertirAReservaChatInfo(
    List<dynamic> response,
    String usuarioActualId,
  ) async {
    final List<ReservaChatInfo> reservasInfo = [];

    for (final json in response) {
      final reserva = await _procesarReservaJson(json, usuarioActualId);
      if (reserva != null) {
        // Verificar estado de reseñas para viajeros
        bool? puedeResenar;
        bool? yaReseno;

        if (reserva.viajeroId == usuarioActualId && reserva.esCompletada) {
          final estadoResena = await _verificarEstadoResena(
            reserva.id,
            usuarioActualId,
          );
          puedeResenar = estadoResena['puedeResenar'];
          yaReseno = estadoResena['yaReseno'];
        }

        final reservaChatInfo = ReservaChatInfo.fromReserva(
          reserva,
          usuarioActualId: usuarioActualId,
          puedeResenar: puedeResenar,
          yaReseno: yaReseno,
        );

        reservasInfo.add(reservaChatInfo);
      }
    }

    return reservasInfo;
  }

  /// Procesar JSON de reserva y crear objeto Reserva
  Future<Reserva?> _procesarReservaJson(
    dynamic json,
    String usuarioActualId,
  ) async {
    try {
      final reserva = Map<String, dynamic>.from(json);
      final propiedad = json['propiedades'];
      final viajero = json['users_profiles'];

      if (propiedad != null) {
        reserva['titulo_propiedad'] = propiedad['titulo'];
        reserva['foto_principal_propiedad'] = propiedad['foto_principal_url'];
        reserva['anfitrion_id'] = propiedad['anfitrion_id'];

        final anfitrion = propiedad['users_profiles'];
        if (anfitrion != null) {
          reserva['nombre_anfitrion'] = anfitrion['nombre'];
          reserva['foto_anfitrion'] = anfitrion['foto_perfil_url'];
        }
      }

      if (viajero != null) {
        reserva['nombre_viajero'] = viajero['nombre'];
        reserva['foto_viajero'] = viajero['foto_perfil_url'];
      }

      return Reserva.fromJson(reserva);
    } catch (e) {
      // Error procesando reserva JSON: $e
      return null;
    }
  }

  /// Verificar si un usuario puede reseñar una reserva específica
  Future<bool> puedeResenar(String reservaId, String userId) async {
    try {
      // Obtener la reserva para verificar que esté completada y el usuario sea el viajero
      final reservaResponse = await _supabase
          .from('reservas')
          .select('viajero_id, estado, fecha_fin')
          .eq('id', reservaId)
          .single();

      // Verificar que el usuario sea el viajero
      if (reservaResponse['viajero_id'] != userId) {
        return false;
      }

      // Verificar que la reserva esté completada O confirmada pero ya haya pasado su fecha de fin
      final estado = reservaResponse['estado'] as String;
      final fechaFin = DateTime.parse(reservaResponse['fecha_fin'] as String);
      final ahora = DateTime.now();

      final esResenableState =
          estado == 'completada' ||
          (estado == 'confirmada' && fechaFin.isBefore(ahora));

      if (!esResenableState) {
        return false;
      }

      // Verificar que no haya reseñado ya
      final yaReseno = await this.yaReseno(reservaId, userId);
      return !yaReseno;
    } catch (e) {
      // Error verificando si puede reseñar: $e
      return false;
    }
  }

  /// Verificar si un usuario ya reseñó una reserva específica
  Future<bool> yaReseno(String reservaId, String userId) async {
    try {
      final response = await _supabase
          .from('resenas')
          .select('id')
          .eq('reserva_id', reservaId)
          .eq('usuario_id', userId)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      // Error verificando si ya reseñó: $e
      return false;
    }
  }

  /// Obtener reservas con reseñas pendientes para un viajero
  Future<List<ReservaChatInfo>> obtenerReservasConResenasPendientes(
    String userId,
  ) async {
    final reservasPasadas = await obtenerReservasViajeroPasadas(userId);

    final reservasPendientes = <ReservaChatInfo>[];

    for (final reserva in reservasPasadas) {
      if (reserva.tieneResenaPendiente) {
        reservasPendientes.add(reserva);
      }
    }

    return reservasPendientes;
  }

  /// Marcar una reserva como reseñada (actualizar el estado local)
  Future<void> marcarComoResenado(String reservaId, String userId) async {
    // Este método se puede usar para actualizar el estado local después de crear una reseña
    // La verificación real se hace consultando la tabla de reseñas
    // Reserva $reservaId marcada como reseñada por usuario $userId
  }

  /// Obtener información de reseña existente para una reserva
  Future<Map<String, dynamic>?> obtenerInfoResena(
    String reservaId,
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('resenas')
          .select('id, calificacion, comentario, created_at')
          .eq('reserva_id', reservaId)
          .eq('usuario_id', userId)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Calcular días restantes hasta el check-in o check-out de una reserva vigente
  int? calcularDiasRestantes(Reserva reserva) {
    final ahora = DateTime.now();

    if (!reserva.esConfirmada || reserva.fechaFin.isBefore(ahora)) {
      return null; // No es vigente
    }

    if (reserva.fechaInicio.isAfter(ahora)) {
      // Aún no ha comenzado - días hasta check-in
      return reserva.fechaInicio.difference(ahora).inDays;
    } else {
      // Ya comenzó - días hasta check-out
      return reserva.fechaFin.difference(ahora).inDays;
    }
  }

  /// Calcular tiempo transcurrido desde que terminó una reserva
  String? calcularTiempoTranscurrido(Reserva reserva) {
    final ahora = DateTime.now();

    if (!reserva.esCompletada || reserva.fechaFin.isAfter(ahora)) {
      return null; // No ha terminado aún
    }

    final diferencia = ahora.difference(reserva.fechaFin);

    if (diferencia.inDays > 365) {
      final anos = (diferencia.inDays / 365).floor();
      return 'Hace $anos año${anos > 1 ? 's' : ''}';
    } else if (diferencia.inDays > 30) {
      final meses = (diferencia.inDays / 30).floor();
      return 'Hace $meses mes${meses > 1 ? 'es' : ''}';
    } else if (diferencia.inDays > 0) {
      return 'Hace ${diferencia.inDays} día${diferencia.inDays > 1 ? 's' : ''}';
    } else if (diferencia.inHours > 0) {
      return 'Hace ${diferencia.inHours} hora${diferencia.inHours > 1 ? 's' : ''}';
    } else {
      return 'Hace unos minutos';
    }
  }

  /// Obtener información del otro usuario (anfitrión o viajero) con calificación promedio
  Future<Map<String, dynamic>?> obtenerInfoOtroUsuario(String userId) async {
    try {
      final response = await _supabase
          .from('users_profiles')
          .select('nombre, foto_perfil_url')
          .eq('id', userId)
          .single();

      // Obtener calificación promedio del usuario
      final calificacionPromedio = await _obtenerCalificacionPromedio(userId);

      return {
        'nombre': response['nombre'],
        'foto_perfil_url': response['foto_perfil_url'],
        'calificacion_promedio': calificacionPromedio,
      };
    } catch (e) {
      // Error obteniendo info del otro usuario: $e
      return null;
    }
  }

  /// Verificar si una reserva está próxima a vencer (menos de 3 días)
  bool estaProximaAVencer(Reserva reserva) {
    final diasRestantes = calcularDiasRestantes(reserva);
    return diasRestantes != null && diasRestantes <= 3 && diasRestantes > 0;
  }

  /// Obtener el texto descriptivo del estado de una reserva
  String obtenerTextoEstadoReserva(Reserva reserva, String usuarioActualId) {
    if (reserva.esPendiente) {
      return 'Pendiente de confirmación';
    } else if (reserva.esConfirmada) {
      final ahora = DateTime.now();
      if (reserva.fechaInicio.isAfter(ahora)) {
        final dias = reserva.fechaInicio.difference(ahora).inDays;
        return dias > 0
            ? 'Comienza en $dias día${dias > 1 ? 's' : ''}'
            : 'Comienza hoy';
      } else if (reserva.fechaFin.isAfter(ahora)) {
        final dias = reserva.fechaFin.difference(ahora).inDays;
        return dias > 0
            ? 'Termina en $dias día${dias > 1 ? 's' : ''}'
            : 'Termina hoy';
      }
    } else if (reserva.esCompletada) {
      final tiempoTranscurrido = calcularTiempoTranscurrido(reserva);
      return tiempoTranscurrido ?? 'Completada';
    } else if (reserva.esCancelada) {
      return 'Cancelada';
    } else if (reserva.esRechazada) {
      return 'Rechazada';
    }

    return 'Estado desconocido';
  }

  /// Obtener calificación promedio de un usuario (método privado)
  Future<double?> _obtenerCalificacionPromedio(String userId) async {
    try {
      // Obtener calificaciones como anfitrión (reseñas de sus propiedades)
      final calificacionesAnfitrion = await _supabase
          .from('resenas')
          .select('calificacion')
          .eq('propiedad_anfitrion_id', userId);

      // Obtener calificaciones como viajero (si las hay en el futuro)
      // Por ahora solo consideramos las calificaciones como anfitrión

      final calificaciones = (calificacionesAnfitrion as List)
          .map((r) => (r['calificacion'] as num).toDouble())
          .toList();

      if (calificaciones.isEmpty) {
        return null;
      }

      final suma = calificaciones.reduce((a, b) => a + b);
      return suma / calificaciones.length;
    } catch (e) {
      // Error obteniendo calificación promedio: $e
      return null;
    }
  }

  /// Verificar el estado de reseña para una reserva específica (método privado)
  Future<Map<String, bool>> _verificarEstadoResena(
    String reservaId,
    String userId,
  ) async {
    try {
      final puedeResenarResult = await puedeResenar(reservaId, userId);
      final yaResenoResult = await yaReseno(reservaId, userId);

      return {'puedeResenar': puedeResenarResult, 'yaReseno': yaResenoResult};
    } catch (e) {
      // Error verificando estado de reseña: $e
      // En caso de error, asumir que puede reseñar pero no ha reseñado
      return {'puedeResenar': true, 'yaReseno': false};
    }
  }
}
