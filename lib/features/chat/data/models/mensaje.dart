class Mensaje {
  final String id;
  final String reservaId;
  final String remitenteId;
  final String mensaje;
  final bool leido;
  final DateTime createdAt;

  Mensaje({
    required this.id,
    required this.reservaId,
    required this.remitenteId,
    required this.mensaje,
    required this.leido,
    required this.createdAt,
  });

  factory Mensaje.fromJson(Map<String, dynamic> json) {
    return Mensaje(
      id: json['id'] as String,
      reservaId: json['reserva_id'] as String,
      remitenteId: json['remitente_id'] as String,
      mensaje: json['mensaje'] as String,
      leido: json['leido'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reserva_id': reservaId,
      'remitente_id': remitenteId,
      'mensaje': mensaje,
      'leido': leido,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
