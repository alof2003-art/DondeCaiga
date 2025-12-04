class Propiedad {
  final String id;
  final String anfitrionId;
  final String titulo;
  final String? descripcion;
  final String direccion;
  final String? ciudad;
  final String? pais;
  final double? latitud;
  final double? longitud;
  final int capacidadPersonas;
  final int? numeroHabitaciones;
  final int? numeroBanos;
  final bool tieneGaraje;
  final String? fotoPrincipalUrl;
  final String estado; // activo, inactivo, pendiente
  final DateTime createdAt;
  final DateTime updatedAt;

  // Datos adicionales del anfitrión (para mostrar en la lista)
  final String? nombreAnfitrion;
  final String? fotoAnfitrion;

  Propiedad({
    required this.id,
    required this.anfitrionId,
    required this.titulo,
    this.descripcion,
    required this.direccion,
    this.ciudad,
    this.pais,
    this.latitud,
    this.longitud,
    required this.capacidadPersonas,
    this.numeroHabitaciones,
    this.numeroBanos,
    this.tieneGaraje = false,
    this.fotoPrincipalUrl,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
    this.nombreAnfitrion,
    this.fotoAnfitrion,
  });

  factory Propiedad.fromJson(Map<String, dynamic> json) {
    return Propiedad(
      id: json['id'] as String,
      anfitrionId: json['anfitrion_id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      direccion: json['direccion'] as String,
      ciudad: json['ciudad'] as String?,
      pais: json['pais'] as String?,
      latitud: json['latitud'] != null
          ? (json['latitud'] as num).toDouble()
          : null,
      longitud: json['longitud'] != null
          ? (json['longitud'] as num).toDouble()
          : null,
      capacidadPersonas: json['capacidad_personas'] as int,
      numeroHabitaciones: json['numero_habitaciones'] as int?,
      numeroBanos: json['numero_banos'] as int?,
      tieneGaraje: json['tiene_garaje'] as bool? ?? false,
      fotoPrincipalUrl: json['foto_principal_url'] as String?,
      estado: json['estado'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      nombreAnfitrion: json['nombre_anfitrion'] as String?,
      fotoAnfitrion: json['foto_anfitrion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anfitrion_id': anfitrionId,
      'titulo': titulo,
      'descripcion': descripcion,
      'direccion': direccion,
      'ciudad': ciudad,
      'pais': pais,
      'latitud': latitud,
      'longitud': longitud,
      'capacidad_personas': capacidadPersonas,
      'numero_habitaciones': numeroHabitaciones,
      'numero_banos': numeroBanos,
      'tiene_garaje': tieneGaraje,
      'foto_principal_url': fotoPrincipalUrl,
      'estado': estado,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
