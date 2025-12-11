import 'package:flutter/material.dart';
import '../../../../main.dart';
import '../../../propiedades/data/models/propiedad.dart';
import '../../../propiedades/data/repositories/propiedad_repository.dart';
import 'detalle_propiedad_screen.dart';
import '../../../../core/widgets/custom_app_bar_header.dart';
import '../../data/models/filtro_explorar.dart';
import '../widgets/filtros_explorar_dialog.dart';

class ExplorarScreen extends StatefulWidget {
  const ExplorarScreen({super.key});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  late final PropiedadRepository _propiedadRepository;
  List<Propiedad> _propiedades = [];
  List<Propiedad> _propiedadesFiltradas = [];
  bool _isLoading = true;
  String? _error;

  // Controladores para filtros y búsqueda
  final TextEditingController _searchController = TextEditingController();
  FiltroExplorar _filtroActual = FiltroExplorar.vacio();

  @override
  void initState() {
    super.initState();
    _propiedadRepository = PropiedadRepository(supabase);
    _searchController.addListener(_aplicarFiltros);
    _cargarPropiedades();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarPropiedades() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final propiedades = await _propiedadRepository
          .obtenerPropiedadesActivas();
      setState(() {
        _propiedades = propiedades;
        _propiedadesFiltradas = propiedades;
        _isLoading = false;
      });
      _aplicarFiltros();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltros() {
    final termino = _searchController.text.toLowerCase().trim();

    setState(() {
      _propiedadesFiltradas = _propiedades.where((propiedad) {
        // Filtro por término de búsqueda
        bool coincideBusqueda = true;
        if (termino.isNotEmpty) {
          coincideBusqueda =
              propiedad.titulo.toLowerCase().contains(termino) ||
              (propiedad.nombreAnfitrion?.toLowerCase().contains(termino) ??
                  false) ||
              (propiedad.ciudad?.toLowerCase().contains(termino) ?? false);
        }

        // Aplicar filtros avanzados
        final filtroConBusqueda = _filtroActual.copyWith(
          terminoBusqueda: termino.isEmpty ? null : termino,
        );

        // Filtro por garaje
        if (filtroConBusqueda.soloConGaraje == true && !propiedad.tieneGaraje) {
          return false;
        }

        // Filtro por habitaciones mínimas
        if (filtroConBusqueda.habitacionesMinimas != null) {
          final habitaciones = propiedad.numeroHabitaciones ?? 0;
          if (habitaciones < filtroConBusqueda.habitacionesMinimas!) {
            return false;
          }
        }

        // Filtro por baños mínimos
        if (filtroConBusqueda.banosMinimos != null) {
          final banos = propiedad.numeroBanos ?? 0;
          if (banos < filtroConBusqueda.banosMinimos!) {
            return false;
          }
        }

        // Filtro por calificación mínima
        if (filtroConBusqueda.calificacionMinima != null) {
          final calificacion = propiedad.calificacionPromedio ?? 0;
          if (calificacion < filtroConBusqueda.calificacionMinima!) {
            return false;
          }
        }

        // Filtro por nuevos (menos de 1 mes)
        if (filtroConBusqueda.soloNuevos == true) {
          final hace30Dias = DateTime.now().subtract(const Duration(days: 30));
          if (!propiedad.createdAt.isAfter(hace30Dias)) {
            return false;
          }
        }

        return coincideBusqueda;
      }).toList();

      // Aplicar ordenamiento
      _aplicarOrdenamiento(_filtroActual.orden);
    });
  }

  void _aplicarOrdenamiento(OrdenExplorar? orden) {
    if (orden == null) return;

    switch (orden) {
      case OrdenExplorar.alfabeticoAZ:
        _propiedadesFiltradas.sort(
          (a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()),
        );
        break;
      case OrdenExplorar.alfabeticoZA:
        _propiedadesFiltradas.sort(
          (a, b) => b.titulo.toLowerCase().compareTo(a.titulo.toLowerCase()),
        );
        break;
      case OrdenExplorar.mejorCalificados:
        _propiedadesFiltradas.sort(
          (a, b) => (b.calificacionPromedio ?? 0).compareTo(
            a.calificacionPromedio ?? 0,
          ),
        );
        break;
      case OrdenExplorar.masCapacidad:
        _propiedadesFiltradas.sort(
          (a, b) => b.capacidadPersonas.compareTo(a.capacidadPersonas),
        );
        break;
      case OrdenExplorar.nuevos:
        _propiedadesFiltradas.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );
        break;
      case OrdenExplorar.masHabitaciones:
        _propiedadesFiltradas.sort(
          (a, b) =>
              (b.numeroHabitaciones ?? 0).compareTo(a.numeroHabitaciones ?? 0),
        );
        break;
    }
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText:
                  'Buscar por nombre del alojamiento, anfitrión o ciudad...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF4DB6AC)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF4DB6AC),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Botón de filtros
          Row(
            children: [
              const Text(
                'Filtros: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _mostrarDialogoFiltros,
                icon: Icon(
                  Icons.tune,
                  size: 18,
                  color: _filtroActual.tienesFiltrosAplicados
                      ? Colors.white
                      : const Color(0xFF4DB6AC),
                ),
                label: Text(
                  _filtroActual.tienesFiltrosAplicados
                      ? 'Filtros (${_filtroActual.numeroFiltrosActivos})'
                      : 'Filtros',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _filtroActual.tienesFiltrosAplicados
                      ? const Color(0xFF4DB6AC)
                      : Colors.white,
                  foregroundColor: _filtroActual.tienesFiltrosAplicados
                      ? Colors.white
                      : const Color(0xFF4DB6AC),
                  side: const BorderSide(color: Color(0xFF4DB6AC)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              if (_filtroActual.tienesFiltrosAplicados) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _filtroActual = FiltroExplorar.vacio();
                    });
                    _aplicarFiltros();
                  },
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: 'Limpiar filtros',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoFiltros() {
    showDialog(
      context: context,
      builder: (context) => FiltrosExplorarDialog(
        filtroInicial: _filtroActual,
        onFiltroAplicado: (nuevoFiltro) {
          setState(() {
            _filtroActual = nuevoFiltro;
          });
          _aplicarFiltros();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomAppBarHeader(
          supabase: supabase,
          screenTitle: 'Explorar Alojamientos',
        ),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar alojamientos',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cargarPropiedades,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_propiedadesFiltradas.isEmpty && _propiedades.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron alojamientos',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros términos de búsqueda',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_propiedades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay alojamientos disponibles',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Vuelve más tarde',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPropiedades,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determinar si usar layout de cuadrícula o lista
          final useGridLayout = constraints.maxWidth > 500;

          if (useGridLayout) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth > 800 ? 3 : 2,
                childAspectRatio: constraints.maxWidth > 800 ? 0.8 : 0.9,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _propiedadesFiltradas.length,
              itemBuilder: (context, index) {
                final propiedad = _propiedadesFiltradas[index];
                return _PropiedadCard(
                  propiedad: propiedad,
                  isGridLayout: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetallePropiedadScreen(propiedadId: propiedad.id),
                      ),
                    );
                  },
                );
              },
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _propiedadesFiltradas.length,
              itemBuilder: (context, index) {
                final propiedad = _propiedadesFiltradas[index];
                return _PropiedadCard(
                  propiedad: propiedad,
                  isGridLayout: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DetallePropiedadScreen(propiedadId: propiedad.id),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class _PropiedadCard extends StatelessWidget {
  final Propiedad propiedad;
  final VoidCallback onTap;
  final bool isGridLayout;

  const _PropiedadCard({
    required this.propiedad,
    required this.onTap,
    this.isGridLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageHeight = isGridLayout ? 140.0 : 200.0;
    final padding = isGridLayout ? 10.0 : 16.0;
    final titleSize = isGridLayout ? 14.0 : 18.0;

    return Card(
      margin: isGridLayout
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto principal
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: propiedad.fotoPrincipalUrl != null
                      ? Image.network(
                          propiedad.fotoPrincipalUrl!,
                          height: imageHeight,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: imageHeight,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.home,
                                size: isGridLayout ? 40 : 60,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          height: imageHeight,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.home,
                            size: isGridLayout ? 40 : 60,
                            color: Colors.grey,
                          ),
                        ),
                ),

                // Información
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título
                      Text(
                        propiedad.titulo,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: isGridLayout ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: isGridLayout ? 4 : 8),

                      // Información del anfitrión (solo en lista)
                      if (!isGridLayout && propiedad.nombreAnfitrion != null)
                        _HostInfoRow(
                          nombreAnfitrion: propiedad.nombreAnfitrion!,
                          calificacionAnfitrion:
                              propiedad.calificacionAnfitrion,
                        ),

                      if (!isGridLayout && propiedad.nombreAnfitrion != null)
                        const SizedBox(height: 8),

                      // Ciudad
                      if (propiedad.ciudad != null)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: isGridLayout ? 14 : 16,
                              color: const Color(0xFF4DB6AC),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                propiedad.ciudad!,
                                style: TextStyle(
                                  fontSize: isGridLayout ? 12 : 14,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      SizedBox(height: isGridLayout ? 4 : 8),

                      // Información adicional
                      _buildPropiedadInfo(propiedad, isGridLayout),
                    ],
                  ),
                ),
              ],
            ),
            // Badge de calificación en estrellas (esquina superior derecha)
            if (propiedad.calificacionPromedio != null &&
                propiedad.numeroResenas != null &&
                propiedad.numeroResenas! > 0)
              _StarRatingBadge(rating: propiedad.calificacionPromedio!),
          ],
        ),
      ),
    );
  }

  Widget _buildPropiedadInfo(Propiedad propiedad, bool isGridLayout) {
    final iconSize = isGridLayout ? 14.0 : 16.0;
    final fontSize = isGridLayout ? 12.0 : 14.0;

    return Column(
      children: [
        // Primera fila: Capacidad y Habitaciones
        Row(
          children: [
            // Capacidad
            Icon(Icons.people, size: iconSize, color: const Color(0xFF4DB6AC)),
            const SizedBox(width: 4),
            Text(
              '${propiedad.capacidadPersonas} personas',
              style: TextStyle(fontSize: fontSize, color: Colors.grey[700]),
            ),

            if (propiedad.numeroHabitaciones != null) ...[
              const SizedBox(width: 12),
              Icon(Icons.bed, size: iconSize, color: const Color(0xFF4DB6AC)),
              const SizedBox(width: 4),
              Text(
                '${propiedad.numeroHabitaciones} hab.',
                style: TextStyle(fontSize: fontSize, color: Colors.grey[700]),
              ),
            ],
          ],
        ),

        if (!isGridLayout) ...[
          const SizedBox(height: 4),
          // Segunda fila: Baños y Garaje (solo en vista de lista)
          Row(
            children: [
              if (propiedad.numeroBanos != null) ...[
                Icon(
                  Icons.bathtub,
                  size: iconSize,
                  color: const Color(0xFF4DB6AC),
                ),
                const SizedBox(width: 4),
                Text(
                  '${propiedad.numeroBanos} baño${propiedad.numeroBanos! > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: fontSize, color: Colors.grey[700]),
                ),
              ],

              if (propiedad.tieneGaraje) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.garage,
                  size: iconSize,
                  color: const Color(0xFF4DB6AC),
                ),
                const SizedBox(width: 4),
                Text(
                  'Garaje',
                  style: TextStyle(fontSize: fontSize, color: Colors.grey[700]),
                ),
              ],
            ],
          ),
        ] else if (propiedad.tieneGaraje) ...[
          // En vista de cuadrícula, solo mostrar garaje si existe
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.garage,
                size: iconSize,
                color: const Color(0xFF4DB6AC),
              ),
              const SizedBox(width: 4),
              Text(
                'Garaje',
                style: TextStyle(fontSize: fontSize, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StarRatingBadge extends StatelessWidget {
  final double rating;

  const _StarRatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0x88000000),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _getStarString(rating),
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  String _getStarString(double rating) {
    int starCount;
    if (rating <= 1.0) {
      starCount = 1;
    } else if (rating <= 2.0) {
      starCount = 2;
    } else if (rating <= 3.0) {
      starCount = 3;
    } else if (rating <= 4.0) {
      starCount = 4;
    } else {
      starCount = 5;
    }
    return '⭐' * starCount;
  }
}

class _HostInfoRow extends StatelessWidget {
  final String nombreAnfitrion;
  final double? calificacionAnfitrion;

  const _HostInfoRow({
    required this.nombreAnfitrion,
    this.calificacionAnfitrion,
  });

  @override
  Widget build(BuildContext context) {
    final performanceLabel = calificacionAnfitrion != null
        ? _getPerformanceLabel(calificacionAnfitrion!)
        : null;

    return Row(
      children: [
        const Icon(Icons.person, size: 16, color: Color(0xFF4DB6AC)),
        const SizedBox(width: 4),
        Flexible(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: Colors.grey[800]),
              children: [
                TextSpan(text: 'Anfitrión: '),
                TextSpan(
                  text: nombreAnfitrion,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (performanceLabel != null) ...[
                  const TextSpan(text: ' • '),
                  TextSpan(
                    text: performanceLabel,
                    style: const TextStyle(
                      color: Color(0xFF4DB6AC),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String? _getPerformanceLabel(double rating) {
    if (rating <= 1.0) return null; // 0-20%
    if (rating <= 2.0) return 'Básico'; // 21-40%
    if (rating <= 3.0) return 'Regular'; // 41-60%
    if (rating <= 4.0) return 'Bueno'; // 61-80%
    return 'Excelente'; // 81-100%
  }
}
