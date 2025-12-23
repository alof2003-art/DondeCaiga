import '../models/filtro_chat.dart';
import '../models/reserva_chat_info.dart';

/// Servicio para aplicar filtros a las reservas del chat
class ChatFilterService {
  // Cache simple para mejorar rendimiento
  final Map<String, List<ReservaChatInfo>> _cache = {};

  /// Limpiar caché cuando sea necesario
  void limpiarCache() {
    _cache.clear();
  }

  /// Aplicar todos los filtros especificados a una lista de reservas
  List<ReservaChatInfo> aplicarFiltros(
    List<ReservaChatInfo> reservas,
    FiltroChat filtro,
  ) {
    // Optimización: Si no hay filtros, retornar la lista original
    if (!filtro.tienesFiltrosAplicados) {
      return reservas;
    }

    // Generar clave de caché basada en filtros y cantidad de reservas
    final cacheKey = '${filtro.hashCode}_${reservas.length}';

    // Verificar caché
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    List<ReservaChatInfo> resultado = reservas;

    // Aplicar filtro por término de búsqueda
    if (filtro.terminoBusqueda != null && filtro.terminoBusqueda!.isNotEmpty) {
      resultado = filtrarPorLugar(resultado, filtro.terminoBusqueda!);
    }

    // Aplicar filtro por estado
    if (filtro.estadoFiltro != null) {
      resultado = filtrarPorEstado(resultado, filtro.estadoFiltro!);
    }

    // Aplicar filtro por rango de fechas
    if (filtro.esRangoFechas) {
      resultado = filtrarPorRangoFechas(
        resultado,
        filtro.fechaInicio,
        filtro.fechaFin,
      );
    }

    // Aplicar ordenamiento
    if (filtro.ordenFecha != null) {
      resultado = ordenarPorFecha(resultado, filtro.ordenFecha!);
    } else if (filtro.ordenAlfabetico) {
      resultado = ordenarAlfabeticamente(resultado, filtro.ascendente);
    }

    // Guardar en caché (limitar tamaño del caché)
    if (_cache.length > 10) {
      _cache.clear();
    }
    _cache[cacheKey] = resultado;

    return resultado;
  }

  /// Filtrar reservas por lugar (nombre de propiedad o ciudad)
  List<ReservaChatInfo> filtrarPorLugar(
    List<ReservaChatInfo> reservas,
    String termino,
  ) {
    final terminoLower = termino.toLowerCase().trim();

    if (terminoLower.isEmpty) {
      return reservas;
    }

    return reservas.where((reserva) {
      // Buscar en el título de la propiedad
      final titulo = reserva.tituloPropiedad?.toLowerCase() ?? '';
      if (titulo.contains(terminoLower)) {
        return true;
      }

      // Buscar en el nombre del otro usuario
      final nombreOtroUsuario = reserva.nombreOtroUsuario?.toLowerCase() ?? '';
      if (nombreOtroUsuario.contains(terminoLower)) {
        return true;
      }

      // Buscar en el nombre del anfitrión
      final nombreAnfitrion = reserva.nombreAnfitrion?.toLowerCase() ?? '';
      if (nombreAnfitrion.contains(terminoLower)) {
        return true;
      }

      // Buscar en el nombre del viajero
      final nombreViajero = reserva.nombreViajero?.toLowerCase() ?? '';
      if (nombreViajero.contains(terminoLower)) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Ordenar reservas por fecha
  List<ReservaChatInfo> ordenarPorFecha(
    List<ReservaChatInfo> reservas,
    OrdenFecha orden,
  ) {
    final List<ReservaChatInfo> resultado = List.from(reservas);

    switch (orden) {
      case OrdenFecha.masReciente:
        resultado.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
        break;
      case OrdenFecha.masAntigua:
        resultado.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
        break;
      case OrdenFecha.rango:
        // Para rango, mantener el orden actual (se filtra por rango en otro método)
        break;
    }

    return resultado;
  }

  /// Ordenar reservas alfabéticamente por título de propiedad
  List<ReservaChatInfo> ordenarAlfabeticamente(
    List<ReservaChatInfo> reservas,
    bool ascendente,
  ) {
    final List<ReservaChatInfo> resultado = List.from(reservas);

    resultado.sort((a, b) {
      final tituloA = a.tituloPropiedad ?? '';
      final tituloB = b.tituloPropiedad ?? '';

      final comparacion = tituloA.toLowerCase().compareTo(
        tituloB.toLowerCase(),
      );
      return ascendente ? comparacion : -comparacion;
    });

    return resultado;
  }

  /// Filtrar reservas por estado
  List<ReservaChatInfo> filtrarPorEstado(
    List<ReservaChatInfo> reservas,
    EstadoFiltro estado,
  ) {
    List<ReservaChatInfo> resultado;
    switch (estado) {
      case EstadoFiltro.vigentes:
        resultado = reservas.where((reserva) => reserva.esVigente).toList();
        break;

      case EstadoFiltro.pasadas:
        resultado = reservas.where((reserva) => !reserva.esVigente).toList();
        break;

      case EstadoFiltro.conResenasPendientes:
        resultado = reservas
            .where((reserva) => reserva.tieneResenaPendiente)
            .toList();
        break;
    }

    return resultado;
  }

  /// Filtrar reservas por rango de fechas
  List<ReservaChatInfo> filtrarPorRangoFechas(
    List<ReservaChatInfo> reservas,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  ) {
    if (fechaInicio == null && fechaFin == null) {
      return reservas;
    }

    return reservas.where((reserva) {
      // Verificar si la reserva está dentro del rango especificado
      if (fechaInicio != null && reserva.fechaFin.isBefore(fechaInicio)) {
        return false;
      }

      if (fechaFin != null && reserva.fechaInicio.isAfter(fechaFin)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Obtener estadísticas de filtrado
  Map<String, int> obtenerEstadisticasFiltrado(
    List<ReservaChatInfo> reservasOriginales,
    List<ReservaChatInfo> reservasFiltradas,
    FiltroChat filtro,
  ) {
    return {
      'total_originales': reservasOriginales.length,
      'total_filtradas': reservasFiltradas.length,
      'filtros_aplicados': filtro.numeroFiltrosActivos,
      'vigentes': reservasFiltradas.where((r) => r.esVigente).length,
      'pasadas': reservasFiltradas.where((r) => !r.esVigente).length,
      'con_resenas_pendientes': reservasFiltradas
          .where((r) => r.tieneResenaPendiente)
          .length,
    };
  }

  /// Verificar si una reserva coincide con los criterios de búsqueda
  bool coincideConBusqueda(ReservaChatInfo reserva, String termino) {
    final terminoLower = termino.toLowerCase().trim();

    if (terminoLower.isEmpty) {
      return true;
    }

    // Lista de campos donde buscar
    final camposBusqueda = [
      reserva.tituloPropiedad,
      reserva.nombreOtroUsuario,
      reserva.nombreAnfitrion,
      reserva.nombreViajero,
    ];

    return camposBusqueda.any(
      (campo) => campo?.toLowerCase().contains(terminoLower) ?? false,
    );
  }

  /// Obtener sugerencias de búsqueda basadas en las reservas disponibles
  List<String> obtenerSugerenciasBusqueda(List<ReservaChatInfo> reservas) {
    final Set<String> sugerencias = {};

    for (final reserva in reservas) {
      // Agregar títulos de propiedades
      if (reserva.tituloPropiedad != null &&
          reserva.tituloPropiedad!.isNotEmpty) {
        sugerencias.add(reserva.tituloPropiedad!);
      }

      // Agregar nombres de usuarios
      if (reserva.nombreOtroUsuario != null &&
          reserva.nombreOtroUsuario!.isNotEmpty) {
        sugerencias.add(reserva.nombreOtroUsuario!);
      }
    }

    final lista = sugerencias.toList();
    lista.sort();
    return lista.take(10).toList(); // Limitar a 10 sugerencias
  }

  /// Validar que los filtros sean coherentes
  bool validarFiltros(FiltroChat filtro) {
    // Verificar que el rango de fechas sea válido
    if (filtro.fechaInicio != null && filtro.fechaFin != null) {
      if (filtro.fechaInicio!.isAfter(filtro.fechaFin!)) {
        return false;
      }
    }

    // Verificar que el término de búsqueda no sea solo espacios
    if (filtro.terminoBusqueda != null) {
      if (filtro.terminoBusqueda!.trim().isEmpty) {
        return false;
      }
    }

    return true;
  }

  /// Crear filtro optimizado para búsqueda rápida
  FiltroChat optimizarFiltroParaBusqueda(FiltroChat filtro) {
    // Si solo hay término de búsqueda, optimizar para búsqueda rápida
    if (filtro.terminoBusqueda != null &&
        filtro.terminoBusqueda!.isNotEmpty &&
        !filtro.tienesFiltrosAplicados) {
      return FiltroChat.porTermino(filtro.terminoBusqueda!.trim());
    }

    return filtro;
  }

  /// Filtrar por múltiples criterios combinados (filtro avanzado)
  List<ReservaChatInfo> filtrarPorCriteriosCombinados(
    List<ReservaChatInfo> reservas,
    Map<String, dynamic> criterios,
  ) {
    List<ReservaChatInfo> resultado = List.from(reservas);

    // Filtro por duración de estancia
    if (criterios.containsKey('duracion_minima')) {
      final duracionMinima = criterios['duracion_minima'] as int;
      resultado = resultado
          .where((reserva) => reserva.duracionDias >= duracionMinima)
          .toList();
    }

    if (criterios.containsKey('duracion_maxima')) {
      final duracionMaxima = criterios['duracion_maxima'] as int;
      resultado = resultado
          .where((reserva) => reserva.duracionDias <= duracionMaxima)
          .toList();
    }

    // Filtro por proximidad a vencer
    if (criterios.containsKey('proximas_a_vencer') &&
        criterios['proximas_a_vencer'] == true) {
      resultado = resultado
          .where((reserva) => reserva.estaProximaAVencer)
          .toList();
    }

    // Filtro por tipo de usuario (solo viajero o solo anfitrión)
    if (criterios.containsKey('solo_como_viajero') &&
        criterios['solo_como_viajero'] == true) {
      resultado = resultado
          .where((reserva) => reserva.esReservaComoViajero)
          .toList();
    }

    if (criterios.containsKey('solo_como_anfitrion') &&
        criterios['solo_como_anfitrion'] == true) {
      resultado = resultado
          .where((reserva) => !reserva.esReservaComoViajero)
          .toList();
    }

    // Filtro por calificación del otro usuario
    if (criterios.containsKey('calificacion_minima')) {
      final calificacionMinima = criterios['calificacion_minima'] as double;
      resultado = resultado
          .where(
            (reserva) =>
                reserva.calificacionOtroUsuario != null &&
                reserva.calificacionOtroUsuario! >= calificacionMinima,
          )
          .toList();
    }

    return resultado;
  }

  /// Aplicar filtros con priorización (algunos filtros son más importantes)
  List<ReservaChatInfo> aplicarFiltrosConPrioridad(
    List<ReservaChatInfo> reservas,
    FiltroChat filtro, {
    bool priorizarVigentes = true,
    bool priorizarConResenas = false,
  }) {
    List<ReservaChatInfo> resultado = aplicarFiltros(reservas, filtro);

    // Ordenar por prioridad
    resultado.sort((a, b) {
      // Priorizar reservas vigentes si está habilitado
      if (priorizarVigentes) {
        if (a.esVigente && !b.esVigente) return -1;
        if (!a.esVigente && b.esVigente) return 1;
      }

      // Priorizar reservas con reseñas pendientes si está habilitado
      if (priorizarConResenas) {
        if (a.tieneResenaPendiente && !b.tieneResenaPendiente) return -1;
        if (!a.tieneResenaPendiente && b.tieneResenaPendiente) return 1;
      }

      // Ordenar por fecha como criterio secundario
      return b.fechaInicio.compareTo(a.fechaInicio);
    });

    return resultado;
  }

  /// Crear filtros inteligentes basados en el contexto
  FiltroChat crearFiltroInteligente(String contexto) {
    switch (contexto) {
      case 'reservas_recientes':
        // Mostrar reservas de los últimos 3 meses
        final hace3Meses = DateTime.now().subtract(const Duration(days: 90));
        return FiltroChat.porFecha(OrdenFecha.rango, inicio: hace3Meses);

      case 'necesitan_atencion':
        // Mostrar reservas que necesitan atención (con reseñas pendientes)
        return FiltroChat.porEstado(EstadoFiltro.conResenasPendientes);

      case 'mas_populares':
        // Ordenar alfabéticamente para encontrar fácilmente
        return FiltroChat.alfabetico();

      default:
        return FiltroChat.vacio();
    }
  }

  /// Obtener filtros sugeridos basados en el contenido actual
  List<FiltroChat> obtenerFiltrosSugeridos(List<ReservaChatInfo> reservas) {
    final List<FiltroChat> sugerencias = [];

    // Sugerir filtro por vigentes si hay reservas vigentes
    final tieneVigentes = reservas.any((r) => r.esVigente);
    if (tieneVigentes) {
      sugerencias.add(FiltroChat.porEstado(EstadoFiltro.vigentes));
    }

    // Sugerir filtro por reseñas pendientes si las hay
    final tieneResenasPendientes = reservas.any((r) => r.tieneResenaPendiente);
    if (tieneResenasPendientes) {
      sugerencias.add(FiltroChat.porEstado(EstadoFiltro.conResenasPendientes));
    }

    // Sugerir orden alfabético si hay muchas reservas
    if (reservas.length > 10) {
      sugerencias.add(FiltroChat.alfabetico());
    }

    // Sugerir filtro por fecha reciente
    sugerencias.add(FiltroChat.porFecha(OrdenFecha.masReciente));

    return sugerencias;
  }
}
