class Resena {
  final String id;
  final String propiedadId;
  final String viajeroId;
  final String? reservaId;
  final int calificacion;
  final String? comentario;
  final DateTime createdAt;

  // Campos adicionales del viajero
  final String? nombreViajero;
  final String? fotoPerfilViajero;

  Resena({
    required this.id,
    required this.propiedadId,
    required this.viajeroId,
    this.reservaId,
    required this.calificacion,
    this.comentario,
    required this.createdAt,
    this.nombreViajero,
    this.fotoPerfilViajero,
  });

  factory Resena.fromJson(Map<String, dynamic> json) {
    return Resena(
      id: json['id'] as String,
      propiedadId: json['propiedad_id'] as String,
      viajeroId: json['viajero_id'] as String,
      reservaId: json['reserva_id'] as String?,
      calificacion: json['calificacion'] as int,
      comentario: json['comentario'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      nombreViajero: json['nombre_viajero'] as String?,
      fotoPerfilViajero: json['foto_perfil_viajero'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propiedad_id': propiedadId,
      'viajero_id': viajeroId,
      'reserva_id': reservaId,
      'calificacion': calificacion,
      'comentario': comentario,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
