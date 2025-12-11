/// Modelo para los filtros de exploración de propiedades
class FiltroExplorar {
  final String? terminoBusqueda;
  final OrdenExplorar? orden;
  final bool? soloConGaraje;
  final int? habitacionesMinimas;
  final int? banosMinimos;
  final double? calificacionMinima;
  final bool? soloNuevos; // Menos de 1 mes

  const FiltroExplorar({
    this.terminoBusqueda,
    this.orden,
    this.soloConGaraje,
    this.habitacionesMinimas,
    this.banosMinimos,
    this.calificacionMinima,
    this.soloNuevos,
  });

  /// Factory constructor para filtros vacíos
  factory FiltroExplorar.vacio() {
    return const FiltroExplorar();
  }

  /// Verifica si hay algún filtro aplicado
  bool get tienesFiltrosAplicados {
    return terminoBusqueda != null ||
        orden != null ||
        soloConGaraje == true ||
        habitacionesMinimas != null ||
        banosMinimos != null ||
        calificacionMinima != null ||
        soloNuevos == true;
  }

  /// Cuenta el número de filtros activos
  int get numeroFiltrosActivos {
    int count = 0;
    if (terminoBusqueda != null && terminoBusqueda!.isNotEmpty) count++;
    if (orden != null) count++;
    if (soloConGaraje == true) count++;
    if (habitacionesMinimas != null) count++;
    if (banosMinimos != null) count++;
    if (calificacionMinima != null) count++;
    if (soloNuevos == true) count++;
    return count;
  }

  /// Crea una copia con nuevos valores
  FiltroExplorar copyWith({
    String? terminoBusqueda,
    OrdenExplorar? orden,
    bool? soloConGaraje,
    int? habitacionesMinimas,
    int? banosMinimos,
    double? calificacionMinima,
    bool? soloNuevos,
    bool limpiarTermino = false,
    bool limpiarOrden = false,
    bool limpiarGaraje = false,
    bool limpiarHabitaciones = false,
    bool limpiarBanos = false,
    bool limpiarCalificacion = false,
    bool limpiarNuevos = false,
  }) {
    return FiltroExplorar(
      terminoBusqueda: limpiarTermino
          ? null
          : (terminoBusqueda ?? this.terminoBusqueda),
      orden: limpiarOrden ? null : (orden ?? this.orden),
      soloConGaraje: limpiarGaraje
          ? null
          : (soloConGaraje ?? this.soloConGaraje),
      habitacionesMinimas: limpiarHabitaciones
          ? null
          : (habitacionesMinimas ?? this.habitacionesMinimas),
      banosMinimos: limpiarBanos ? null : (banosMinimos ?? this.banosMinimos),
      calificacionMinima: limpiarCalificacion
          ? null
          : (calificacionMinima ?? this.calificacionMinima),
      soloNuevos: limpiarNuevos ? null : (soloNuevos ?? this.soloNuevos),
    );
  }

  /// Limpia todos los filtros
  FiltroExplorar limpiar() {
    return FiltroExplorar.vacio();
  }

  @override
  String toString() {
    return 'FiltroExplorar(terminoBusqueda: $terminoBusqueda, orden: $orden, '
        'soloConGaraje: $soloConGaraje, habitacionesMinimas: $habitacionesMinimas, '
        'banosMinimos: $banosMinimos, calificacionMinima: $calificacionMinima, '
        'soloNuevos: $soloNuevos)';
  }
}

/// Enum para los tipos de ordenamiento
enum OrdenExplorar {
  alfabeticoAZ,
  alfabeticoZA,
  mejorCalificados,
  masCapacidad,
  nuevos,
  masHabitaciones,
}

/// Extensión para obtener descripciones de los ordenamientos
extension OrdenExplorarExtension on OrdenExplorar {
  String get descripcion {
    switch (this) {
      case OrdenExplorar.alfabeticoAZ:
        return 'A-Z';
      case OrdenExplorar.alfabeticoZA:
        return 'Z-A';
      case OrdenExplorar.mejorCalificados:
        return 'Mejor calificados';
      case OrdenExplorar.masCapacidad:
        return 'Más capacidad';
      case OrdenExplorar.nuevos:
        return 'Más nuevos';
      case OrdenExplorar.masHabitaciones:
        return 'Más habitaciones';
    }
  }

  String get nombre {
    switch (this) {
      case OrdenExplorar.alfabeticoAZ:
        return 'A-Z';
      case OrdenExplorar.alfabeticoZA:
        return 'Z-A';
      case OrdenExplorar.mejorCalificados:
        return 'Calificación';
      case OrdenExplorar.masCapacidad:
        return 'Capacidad';
      case OrdenExplorar.nuevos:
        return 'Nuevos';
      case OrdenExplorar.masHabitaciones:
        return 'Habitaciones';
    }
  }
}
