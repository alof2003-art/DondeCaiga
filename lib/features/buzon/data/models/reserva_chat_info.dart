import '../../../reservas/data/models/reserva.dart';

/// Extensión del modelo Reserva con información adicional específica para el chat
class ReservaChatInfo extends Reserva {
  final bool esVigente;
  final int? diasRestantes;
  final String? tiempoTranscurrido;
  final bool puedeResenar;
  final bool yaReseno;
  final double? calificacionOtroUsuario;
  final String? fotoPerfilOtroUsuario;
  final String? nombreOtroUsuario;
  final bool esReservaComoViajero;

  ReservaChatInfo({
    required super.id,
    required super.propiedadId,
    required super.viajeroId,
    required super.fechaInicio,
    required super.fechaFin,
    required super.estado,
    required super.createdAt,
    required super.updatedAt,
    super.codigoVerificacion,
    super.tituloPropiedad,
    super.fotoPrincipalPropiedad,
    super.nombreViajero,
    super.fotoViajero,
    super.nombreAnfitrion,
    super.fotoAnfitrion,
    super.anfitrionId,
    required this.esVigente,
    this.diasRestantes,
    this.tiempoTranscurrido,
    required this.puedeResenar,
    required this.yaReseno,
    this.calificacionOtroUsuario,
    this.fotoPerfilOtroUsuario,
    this.nombreOtroUsuario,
    required this.esReservaComoViajero,
  });

  /// Factory constructor para crear ReservaChatInfo desde una Reserva existente
  factory ReservaChatInfo.fromReserva(
    Reserva reserva, {
    required String usuarioActualId,
    bool? puedeResenar,
    bool? yaReseno,
    double? calificacionOtroUsuario,
  }) {
    final ahora = DateTime.now();
    final esReservaComoViajero = reserva.viajeroId == usuarioActualId;

    // Determinar si la reserva está vigente
    final esVigente = reserva.esConfirmada && reserva.fechaFin.isAfter(ahora);

    // Calcular días restantes o tiempo transcurrido
    int? diasRestantes;
    String? tiempoTranscurrido;

    if (esVigente) {
      if (reserva.fechaInicio.isAfter(ahora)) {
        // Aún no ha comenzado
        diasRestantes = reserva.fechaInicio.difference(ahora).inDays;
      } else {
        // Ya comenzó, calcular días hasta el fin
        diasRestantes = reserva.fechaFin.difference(ahora).inDays;
      }
    } else if (reserva.esCompletada) {
      // Calcular tiempo transcurrido desde que terminó
      final diferencia = ahora.difference(reserva.fechaFin);
      tiempoTranscurrido = _formatearTiempoTranscurrido(diferencia);
    }

    // Determinar información del otro usuario
    String? nombreOtroUsuario;
    String? fotoPerfilOtroUsuario;

    if (esReservaComoViajero) {
      nombreOtroUsuario = reserva.nombreAnfitrion;
      fotoPerfilOtroUsuario = reserva.fotoAnfitrion;
    } else {
      nombreOtroUsuario = reserva.nombreViajero;
      fotoPerfilOtroUsuario = reserva.fotoViajero;
    }

    // Determinar si puede reseñar (solo viajeros pueden reseñar y solo después de completar)
    final puedeResenarCalculado =
        esReservaComoViajero &&
        reserva.esCompletada &&
        (puedeResenar ?? true) &&
        !(yaReseno ?? false);

    return ReservaChatInfo(
      id: reserva.id,
      propiedadId: reserva.propiedadId,
      viajeroId: reserva.viajeroId,
      fechaInicio: reserva.fechaInicio,
      fechaFin: reserva.fechaFin,
      estado: reserva.estado,
      createdAt: reserva.createdAt,
      updatedAt: reserva.updatedAt,
      codigoVerificacion: reserva.codigoVerificacion,
      tituloPropiedad: reserva.tituloPropiedad,
      fotoPrincipalPropiedad: reserva.fotoPrincipalPropiedad,
      nombreViajero: reserva.nombreViajero,
      fotoViajero: reserva.fotoViajero,
      nombreAnfitrion: reserva.nombreAnfitrion,
      fotoAnfitrion: reserva.fotoAnfitrion,
      anfitrionId: reserva.anfitrionId,
      esVigente: esVigente,
      diasRestantes: diasRestantes,
      tiempoTranscurrido: tiempoTranscurrido,
      puedeResenar: puedeResenarCalculado,
      yaReseno: yaReseno ?? false,
      calificacionOtroUsuario: calificacionOtroUsuario,
      fotoPerfilOtroUsuario: fotoPerfilOtroUsuario,
      nombreOtroUsuario: nombreOtroUsuario,
      esReservaComoViajero: esReservaComoViajero,
    );
  }

  /// Formatea el tiempo transcurrido en un string legible
  static String _formatearTiempoTranscurrido(Duration diferencia) {
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

  /// Obtiene el texto descriptivo del tiempo para mostrar en la UI
  String get textoTiempo {
    if (esVigente && diasRestantes != null) {
      if (fechaInicio.isAfter(DateTime.now())) {
        return diasRestantes! > 0
            ? 'Comienza en $diasRestantes día${diasRestantes! > 1 ? 's' : ''}'
            : 'Comienza hoy';
      } else {
        return diasRestantes! > 0
            ? 'Termina en $diasRestantes día${diasRestantes! > 1 ? 's' : ''}'
            : 'Termina hoy';
      }
    } else if (tiempoTranscurrido != null) {
      return tiempoTranscurrido!;
    }
    return '';
  }

  /// Obtiene el texto del estado de la reseña
  String get textoEstadoResena {
    if (!esReservaComoViajero) return '';
    if (!esCompletada) return '';
    if (yaReseno) return 'Reseñado';
    if (puedeResenar) return 'Comparte tu experiencia';
    return '';
  }

  /// Verifica si debe mostrar el botón de reseña
  bool get deberMostrarBotonResena {
    return esReservaComoViajero && puedeResenar && !yaReseno;
  }

  /// Verifica si debe mostrar el indicador de reseña pendiente
  bool get tieneResenaPendiente {
    return esReservaComoViajero && esCompletada && !yaReseno && puedeResenar;
  }

  /// Obtiene el nombre para mostrar según el contexto
  String get nombreParaMostrar {
    return nombreOtroUsuario ??
        (esReservaComoViajero ? 'Anfitrión' : 'Viajero');
  }

  /// Obtiene la foto para mostrar según el contexto
  String? get fotoParaMostrar {
    return fotoPerfilOtroUsuario;
  }

  /// Verifica si la reserva está próxima a vencer (menos de 3 días)
  bool get estaProximaAVencer {
    if (!esVigente || diasRestantes == null) return false;
    return diasRestantes! <= 3 && diasRestantes! > 0;
  }

  /// Obtiene el subtítulo descriptivo para la tarjeta
  String get subtituloDescriptivo {
    if (esReservaComoViajero) {
      return 'Hospedaje con $nombreParaMostrar';
    } else {
      return 'Huésped: $nombreParaMostrar';
    }
  }

  /// Crea una copia con nuevos valores
  ReservaChatInfo copyWith({
    bool? esVigente,
    int? diasRestantes,
    String? tiempoTranscurrido,
    bool? puedeResenar,
    bool? yaReseno,
    double? calificacionOtroUsuario,
    String? fotoPerfilOtroUsuario,
    String? nombreOtroUsuario,
    bool? esReservaComoViajero,
  }) {
    return ReservaChatInfo(
      id: id,
      propiedadId: propiedadId,
      viajeroId: viajeroId,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      estado: estado,
      createdAt: createdAt,
      updatedAt: updatedAt,
      codigoVerificacion: codigoVerificacion,
      tituloPropiedad: tituloPropiedad,
      fotoPrincipalPropiedad: fotoPrincipalPropiedad,
      nombreViajero: nombreViajero,
      fotoViajero: fotoViajero,
      nombreAnfitrion: nombreAnfitrion,
      fotoAnfitrion: fotoAnfitrion,
      anfitrionId: anfitrionId,
      esVigente: esVigente ?? this.esVigente,
      diasRestantes: diasRestantes ?? this.diasRestantes,
      tiempoTranscurrido: tiempoTranscurrido ?? this.tiempoTranscurrido,
      puedeResenar: puedeResenar ?? this.puedeResenar,
      yaReseno: yaReseno ?? this.yaReseno,
      calificacionOtroUsuario:
          calificacionOtroUsuario ?? this.calificacionOtroUsuario,
      fotoPerfilOtroUsuario:
          fotoPerfilOtroUsuario ?? this.fotoPerfilOtroUsuario,
      nombreOtroUsuario: nombreOtroUsuario ?? this.nombreOtroUsuario,
      esReservaComoViajero: esReservaComoViajero ?? this.esReservaComoViajero,
    );
  }

  @override
  String toString() {
    return 'ReservaChatInfo(id: $id, tituloPropiedad: $tituloPropiedad, '
        'esVigente: $esVigente, diasRestantes: $diasRestantes, '
        'puedeResenar: $puedeResenar, yaReseno: $yaReseno, '
        'esReservaComoViajero: $esReservaComoViajero)';
  }
}
