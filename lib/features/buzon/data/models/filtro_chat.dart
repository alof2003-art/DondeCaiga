/// Enum para definir el orden de fechas en los filtros
enum OrdenFecha { masReciente, masAntigua, rango }

/// Enum para filtrar por estado de las reservas
enum EstadoFiltro { vigentes, pasadas, conResenasPendientes }

/// Modelo que representa los filtros aplicables al chat
class FiltroChat {
  final String? terminoBusqueda;
  final OrdenFecha? ordenFecha;
  final bool ordenAlfabetico;
  final bool ascendente;
  final EstadoFiltro? estadoFiltro;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  const FiltroChat({
    this.terminoBusqueda,
    this.ordenFecha,
    this.ordenAlfabetico = false,
    this.ascendente = true,
    this.estadoFiltro,
    this.fechaInicio,
    this.fechaFin,
  });

  /// Factory constructor para crear filtros vacíos (sin filtros aplicados)
  factory FiltroChat.vacio() {
    return const FiltroChat();
  }

  /// Factory constructor para crear filtro solo por término de búsqueda
  factory FiltroChat.porTermino(String termino) {
    return FiltroChat(terminoBusqueda: termino);
  }

  /// Factory constructor para crear filtro solo por fecha
  factory FiltroChat.porFecha(
    OrdenFecha orden, {
    DateTime? inicio,
    DateTime? fin,
  }) {
    return FiltroChat(ordenFecha: orden, fechaInicio: inicio, fechaFin: fin);
  }

  /// Factory constructor para crear filtro solo por estado
  factory FiltroChat.porEstado(EstadoFiltro estado) {
    return FiltroChat(estadoFiltro: estado);
  }

  /// Factory constructor para crear filtro alfabético
  factory FiltroChat.alfabetico({bool ascendente = true}) {
    return FiltroChat(ordenAlfabetico: true, ascendente: ascendente);
  }

  /// Verifica si hay algún filtro aplicado
  bool get tienesFiltrosAplicados {
    return terminoBusqueda != null ||
        ordenFecha != null ||
        ordenAlfabetico ||
        estadoFiltro != null ||
        fechaInicio != null ||
        fechaFin != null;
  }

  /// Cuenta el número de filtros activos
  int get numeroFiltrosActivos {
    int count = 0;
    if (terminoBusqueda != null && terminoBusqueda!.isNotEmpty) count++;
    if (ordenFecha != null) count++;
    if (ordenAlfabetico) count++;
    if (estadoFiltro != null) count++;
    if (fechaInicio != null || fechaFin != null) count++;
    return count;
  }

  /// Verifica si es un filtro por rango de fechas
  bool get esRangoFechas {
    return ordenFecha == OrdenFecha.rango &&
        (fechaInicio != null || fechaFin != null);
  }

  /// Obtiene una descripción textual de los filtros aplicados
  String get descripcionFiltros {
    List<String> descripciones = [];

    if (terminoBusqueda != null && terminoBusqueda!.isNotEmpty) {
      descripciones.add('Búsqueda: "$terminoBusqueda"');
    }

    if (ordenFecha != null) {
      switch (ordenFecha!) {
        case OrdenFecha.masReciente:
          descripciones.add('Más recientes primero');
          break;
        case OrdenFecha.masAntigua:
          descripciones.add('Más antiguas primero');
          break;
        case OrdenFecha.rango:
          if (fechaInicio != null && fechaFin != null) {
            descripciones.add('Rango de fechas');
          }
          break;
      }
    }

    if (ordenAlfabetico) {
      descripciones.add(ascendente ? 'A-Z' : 'Z-A');
    }

    if (estadoFiltro != null) {
      switch (estadoFiltro!) {
        case EstadoFiltro.vigentes:
          descripciones.add('Solo vigentes');
          break;
        case EstadoFiltro.pasadas:
          descripciones.add('Solo pasadas');
          break;
        case EstadoFiltro.conResenasPendientes:
          descripciones.add('Con reseñas pendientes');
          break;
      }
    }

    return descripciones.isEmpty ? 'Sin filtros' : descripciones.join(', ');
  }

  /// Crea una copia del filtro con nuevos valores
  FiltroChat copyWith({
    String? terminoBusqueda,
    OrdenFecha? ordenFecha,
    bool? ordenAlfabetico,
    bool? ascendente,
    EstadoFiltro? estadoFiltro,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool limpiarTermino = false,
    bool limpiarOrdenFecha = false,
    bool limpiarEstado = false,
    bool limpiarFechas = false,
  }) {
    return FiltroChat(
      terminoBusqueda: limpiarTermino
          ? null
          : (terminoBusqueda ?? this.terminoBusqueda),
      ordenFecha: limpiarOrdenFecha ? null : (ordenFecha ?? this.ordenFecha),
      ordenAlfabetico: ordenAlfabetico ?? this.ordenAlfabetico,
      ascendente: ascendente ?? this.ascendente,
      estadoFiltro: limpiarEstado ? null : (estadoFiltro ?? this.estadoFiltro),
      fechaInicio: limpiarFechas ? null : (fechaInicio ?? this.fechaInicio),
      fechaFin: limpiarFechas ? null : (fechaFin ?? this.fechaFin),
    );
  }

  /// Limpia todos los filtros
  FiltroChat limpiar() {
    return FiltroChat.vacio();
  }

  /// Serialización para persistencia local
  Map<String, dynamic> toJson() {
    return {
      'terminoBusqueda': terminoBusqueda,
      'ordenFecha': ordenFecha?.index,
      'ordenAlfabetico': ordenAlfabetico,
      'ascendente': ascendente,
      'estadoFiltro': estadoFiltro?.index,
      'fechaInicio': fechaInicio?.toIso8601String(),
      'fechaFin': fechaFin?.toIso8601String(),
    };
  }

  /// Deserialización desde persistencia local
  factory FiltroChat.fromJson(Map<String, dynamic> json) {
    return FiltroChat(
      terminoBusqueda: json['terminoBusqueda'] as String?,
      ordenFecha: json['ordenFecha'] != null
          ? OrdenFecha.values[json['ordenFecha'] as int]
          : null,
      ordenAlfabetico: json['ordenAlfabetico'] as bool? ?? false,
      ascendente: json['ascendente'] as bool? ?? true,
      estadoFiltro: json['estadoFiltro'] != null
          ? EstadoFiltro.values[json['estadoFiltro'] as int]
          : null,
      fechaInicio: json['fechaInicio'] != null
          ? DateTime.parse(json['fechaInicio'] as String)
          : null,
      fechaFin: json['fechaFin'] != null
          ? DateTime.parse(json['fechaFin'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FiltroChat &&
        other.terminoBusqueda == terminoBusqueda &&
        other.ordenFecha == ordenFecha &&
        other.ordenAlfabetico == ordenAlfabetico &&
        other.ascendente == ascendente &&
        other.estadoFiltro == estadoFiltro &&
        other.fechaInicio == fechaInicio &&
        other.fechaFin == fechaFin;
  }

  @override
  int get hashCode {
    return terminoBusqueda.hashCode ^
        ordenFecha.hashCode ^
        ordenAlfabetico.hashCode ^
        ascendente.hashCode ^
        estadoFiltro.hashCode ^
        fechaInicio.hashCode ^
        fechaFin.hashCode;
  }

  @override
  String toString() {
    return 'FiltroChat(terminoBusqueda: $terminoBusqueda, ordenFecha: $ordenFecha, '
        'ordenAlfabetico: $ordenAlfabetico, ascendente: $ascendente, '
        'estadoFiltro: $estadoFiltro, fechaInicio: $fechaInicio, fechaFin: $fechaFin)';
  }
}

/// Extensiones para los enums de filtros
extension OrdenFechaExtension on OrdenFecha {
  String get descripcion {
    switch (this) {
      case OrdenFecha.masReciente:
        return 'Más recientes primero';
      case OrdenFecha.masAntigua:
        return 'Más antiguas primero';
      case OrdenFecha.rango:
        return 'Rango personalizado';
    }
  }

  String get nombre {
    switch (this) {
      case OrdenFecha.masReciente:
        return 'Recientes';
      case OrdenFecha.masAntigua:
        return 'Antiguas';
      case OrdenFecha.rango:
        return 'Rango';
    }
  }
}

extension EstadoFiltroExtension on EstadoFiltro {
  String get descripcion {
    switch (this) {
      case EstadoFiltro.vigentes:
        return 'Reservas vigentes';
      case EstadoFiltro.pasadas:
        return 'Reservas pasadas';
      case EstadoFiltro.conResenasPendientes:
        return 'Con reseñas pendientes';
    }
  }

  String get nombre {
    switch (this) {
      case EstadoFiltro.vigentes:
        return 'Vigentes';
      case EstadoFiltro.pasadas:
        return 'Pasadas';
      case EstadoFiltro.conResenasPendientes:
        return 'Pendientes';
    }
  }
}
