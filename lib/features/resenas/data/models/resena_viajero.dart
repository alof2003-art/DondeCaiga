class ResenaViajero {
  final String id;
  final String reservaId;
  final String viajeroId;
  final String anfitrionId;
  final double calificacion;
  final String? comentario;
  final Map<String, int?>? aspectos;
  final DateTime fechaCreacion;
  final String nombreViajero;
  final String? fotoViajero;
  final String nombreAnfitrion;
  final String? fotoAnfitrion;
  final String tituloPropiedad;

  const ResenaViajero({
    required this.id,
    required this.reservaId,
    required this.viajeroId,
    required this.anfitrionId,
    required this.calificacion,
    this.comentario,
    this.aspectos,
    required this.fechaCreacion,
    required this.nombreViajero,
    this.fotoViajero,
    required this.nombreAnfitrion,
    this.fotoAnfitrion,
    required this.tituloPropiedad,
  });

  /// Calcula la calificación promedio basada en los aspectos individuales
  double get calificacionCalculada {
    if (aspectos == null || aspectos!.isEmpty) {
      return calificacion;
    }

    final valores = aspectos!.values
        .where((v) => v != null)
        .cast<int>()
        .toList();
    if (valores.isEmpty) {
      return calificacion;
    }

    final suma = valores.reduce((a, b) => a + b);
    final promedio = suma / valores.length;
    return promedio.clamp(1.0, 5.0);
  }

  /// Obtiene la calificación que debería mostrarse (calculada o la almacenada)
  double get calificacionMostrar {
    final calculada = calificacionCalculada;
    // Si la calculada es diferente a la almacenada, usar la calculada
    return (calculada - calificacion).abs() > 0.01 ? calculada : calificacion;
  }

  factory ResenaViajero.fromJson(Map<String, dynamic> json) {
    Map<String, int?>? aspectosMap;
    if (json['aspectos'] != null) {
      final aspectosJson = json['aspectos'] as Map<String, dynamic>;
      aspectosMap = aspectosJson.map(
        (key, value) => MapEntry(key, value as int?),
      );
    }

    return ResenaViajero(
      id: json['id'] as String,
      reservaId: json['reserva_id'] as String,
      viajeroId: json['viajero_id'] as String,
      anfitrionId: json['anfitrion_id'] as String,
      calificacion: (json['calificacion'] as num).toDouble(),
      comentario: json['comentario'] as String?,
      aspectos: aspectosMap,
      fechaCreacion: DateTime.parse(json['created_at'] as String),
      nombreViajero: json['nombre_viajero'] as String? ?? 'Usuario',
      fotoViajero: json['foto_viajero'] as String?,
      nombreAnfitrion: json['nombre_anfitrion'] as String? ?? 'Anfitrión',
      fotoAnfitrion: json['foto_anfitrion'] as String?,
      tituloPropiedad: json['titulo_propiedad'] as String? ?? 'Propiedad',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reserva_id': reservaId,
      'viajero_id': viajeroId,
      'anfitrion_id': anfitrionId,
      'calificacion': calificacion,
      'comentario': comentario,
      'aspectos': aspectos,
      'created_at': fechaCreacion.toIso8601String(),
      'nombre_viajero': nombreViajero,
      'foto_viajero': fotoViajero,
      'nombre_anfitrion': nombreAnfitrion,
      'foto_anfitrion': fotoAnfitrion,
      'titulo_propiedad': tituloPropiedad,
    };
  }

  // Método para crear una nueva reseña de viajero
  Map<String, dynamic> toInsertJson() {
    return {
      'reserva_id': reservaId,
      'viajero_id': viajeroId,
      'anfitrion_id': anfitrionId,
      'calificacion': calificacion,
      'comentario': comentario,
      'aspectos': aspectos,
    };
  }

  // Método para obtener el promedio de aspectos
  double get promedioAspectos {
    if (aspectos == null || aspectos!.isEmpty) return calificacion.toDouble();

    final aspectosValidos = aspectos!.values
        .where((value) => value != null)
        .cast<int>()
        .toList();

    if (aspectosValidos.isEmpty) return calificacion.toDouble();

    return aspectosValidos.reduce((a, b) => a + b) / aspectosValidos.length;
  }

  // Método para obtener los aspectos con nombres legibles
  Map<String, String> get aspectosLegibles {
    return {
      'limpieza': 'Limpieza',
      'comunicacion': 'Comunicación',
      'respeto_normas': 'Respeto a las normas',
      'cuidado_propiedad': 'Cuidado de la propiedad',
      'puntualidad': 'Puntualidad',
    };
  }
}
