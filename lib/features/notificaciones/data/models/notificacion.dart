class Notificacion {
  final String id;
  final String usuarioId;
  final TipoNotificacion tipo;
  final String titulo;
  final String mensaje;
  final Map<String, dynamic>? datos;
  final DateTime fechaCreacion;
  final bool leida;
  final String? imagenUrl;

  const Notificacion({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.datos,
    required this.fechaCreacion,
    this.leida = false,
    this.imagenUrl,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'] as String,
      usuarioId: json['user_id'] as String,
      tipo: TipoNotificacion.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TipoNotificacion.general,
      ),
      titulo: json['title'] as String,
      mensaje: json['message'] as String,
      datos: json['metadata'] as Map<String, dynamic>?,
      fechaCreacion: DateTime.parse(json['created_at'] as String),
      leida: json['is_read'] as bool? ?? false,
      imagenUrl: null, // No hay imagen_url en esta tabla
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'tipo': tipo.name,
      'titulo': titulo,
      'mensaje': mensaje,
      'datos': datos,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'leida': leida,
      'imagen_url': imagenUrl,
    };
  }

  Notificacion copyWith({
    String? id,
    String? usuarioId,
    TipoNotificacion? tipo,
    String? titulo,
    String? mensaje,
    Map<String, dynamic>? datos,
    DateTime? fechaCreacion,
    bool? leida,
    String? imagenUrl,
  }) {
    return Notificacion(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      datos: datos ?? this.datos,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      leida: leida ?? this.leida,
      imagenUrl: imagenUrl ?? this.imagenUrl,
    );
  }
}

enum TipoNotificacion {
  solicitudReserva('Solicitud de Reserva', 'Nueva solicitud para tu propiedad'),
  reservaAceptada('Reserva Aceptada', 'Tu reserva ha sido aceptada'),
  reservaRechazada('Reserva Rechazada', 'Tu reserva ha sido rechazada'),
  nuevaResena('Nueva Reseña', 'Has recibido una nueva reseña'),
  solicitudAnfitrion('Solicitud Anfitrión', 'Solicitud para ser anfitrión'),
  anfitrionAceptado(
    'Anfitrión Aceptado',
    'Tu solicitud de anfitrión fue aceptada',
  ),
  anfitrionRechazado(
    'Anfitrión Rechazado',
    'Tu solicitud de anfitrión fue rechazada',
  ),
  nuevoMensaje('Nuevo Mensaje', 'Tienes un nuevo mensaje'),
  llegadaHuesped('Llegada de Huésped', 'Tu huésped ha llegado'),
  finEstadia('Fin de Estadía', 'La estadía ha terminado'),
  recordatorioCheckin('Recordatorio Check-in', 'Recordatorio de check-in'),
  recordatorioCheckout('Recordatorio Check-out', 'Recordatorio de check-out'),
  general('General', 'Notificación general');

  const TipoNotificacion(this.titulo, this.descripcion);

  final String titulo;
  final String descripcion;
}

class FiltroNotificaciones {
  final Set<TipoNotificacion> tiposSeleccionados;
  final bool soloNoLeidas;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  const FiltroNotificaciones({
    this.tiposSeleccionados = const {},
    this.soloNoLeidas = false,
    this.fechaDesde,
    this.fechaHasta,
  });

  FiltroNotificaciones copyWith({
    Set<TipoNotificacion>? tiposSeleccionados,
    bool? soloNoLeidas,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) {
    return FiltroNotificaciones(
      tiposSeleccionados: tiposSeleccionados ?? this.tiposSeleccionados,
      soloNoLeidas: soloNoLeidas ?? this.soloNoLeidas,
      fechaDesde: fechaDesde ?? this.fechaDesde,
      fechaHasta: fechaHasta ?? this.fechaHasta,
    );
  }
}
