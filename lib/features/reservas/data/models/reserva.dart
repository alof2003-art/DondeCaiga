class Reserva {
  final String id;
  final String propiedadId;
  final String viajeroId;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String
  estado; // pendiente, confirmada, rechazada, completada, cancelada
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? codigoVerificacion;

  // Datos adicionales para mostrar en la lista
  final String? tituloPropiedad;
  final String? fotoPrincipalPropiedad;
  final String? nombreViajero;
  final String? fotoViajero;
  final String? nombreAnfitrion;
  final String? fotoAnfitrion;
  final String? anfitrionId;

  Reserva({
    required this.id,
    required this.propiedadId,
    required this.viajeroId,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
    this.codigoVerificacion,
    this.tituloPropiedad,
    this.fotoPrincipalPropiedad,
    this.nombreViajero,
    this.fotoViajero,
    this.nombreAnfitrion,
    this.fotoAnfitrion,
    this.anfitrionId,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'] as String,
      propiedadId: json['propiedad_id'] as String,
      viajeroId: json['viajero_id'] as String,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: DateTime.parse(json['fecha_fin'] as String),
      estado: json['estado'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      codigoVerificacion: json['codigo_verificacion'] as String?,
      tituloPropiedad: json['titulo_propiedad'] as String?,
      fotoPrincipalPropiedad: json['foto_principal_propiedad'] as String?,
      nombreViajero: json['nombre_viajero'] as String?,
      fotoViajero: json['foto_viajero'] as String?,
      nombreAnfitrion: json['nombre_anfitrion'] as String?,
      fotoAnfitrion: json['foto_anfitrion'] as String?,
      anfitrionId: json['anfitrion_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propiedad_id': propiedadId,
      'viajero_id': viajeroId,
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      'estado': estado,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int get duracionDias {
    return fechaFin.difference(fechaInicio).inDays;
  }

  bool get esPendiente => estado == 'pendiente';
  bool get esConfirmada => estado == 'confirmada';
  bool get esRechazada => estado == 'rechazada';
  bool get esCompletada => estado == 'completada';
  bool get esCancelada => estado == 'cancelada';
}
