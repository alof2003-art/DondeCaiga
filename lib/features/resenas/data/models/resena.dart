class Resena {
  final String id;
  final String reservaId;
  final String viajeroId;
  final String anfitrionId;
  final String propiedadId;
  final int calificacion;
  final String? comentario;
  final DateTime fechaCreacion;
  final String nombreViajero;
  final String? fotoViajero;
  final String tituloPropiedad;

  const Resena({
    required this.id,
    required this.reservaId,
    required this.viajeroId,
    required this.anfitrionId,
    required this.propiedadId,
    required this.calificacion,
    this.comentario,
    required this.fechaCreacion,
    required this.nombreViajero,
    this.fotoViajero,
    required this.tituloPropiedad,
  });

  factory Resena.fromJson(Map<String, dynamic> json) {
    return Resena(
      id: json['id'] as String,
      reservaId: json['reserva_id'] as String,
      viajeroId: json['viajero_id'] as String,
      anfitrionId: json['anfitrion_id'] as String,
      propiedadId: json['propiedad_id'] as String,
      calificacion: json['calificacion'] as int,
      comentario: json['comentario'] as String?,
      fechaCreacion: DateTime.parse(json['created_at'] as String),
      nombreViajero: json['nombre_viajero'] as String? ?? 'Usuario',
      fotoViajero: json['foto_viajero'] as String?,
      tituloPropiedad: json['titulo_propiedad'] as String? ?? 'Propiedad',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reserva_id': reservaId,
      'viajero_id': viajeroId,
      'anfitrion_id': anfitrionId,
      'propiedad_id': propiedadId,
      'calificacion': calificacion,
      'comentario': comentario,
      'created_at': fechaCreacion.toIso8601String(),
      'nombre_viajero': nombreViajero,
      'foto_viajero': fotoViajero,
      'titulo_propiedad': tituloPropiedad,
    };
  }
}
