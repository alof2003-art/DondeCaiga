import 'package:flutter/material.dart';
import '../../data/models/resena.dart';
import '../../data/models/resena_viajero.dart';
import '../../data/repositories/resenas_repository.dart';
import 'resena_card.dart';
import 'resena_viajero_card.dart';
import 'rating_visual_widget.dart';
import 'titulo_usuario_widget.dart';

class SeccionResenasPerfil extends StatefulWidget {
  final String userId;
  final ResenasRepository resenasRepository;
  final bool esPerfilPropio;

  const SeccionResenasPerfil({
    super.key,
    required this.userId,
    required this.resenasRepository,
    this.esPerfilPropio = false,
  });

  @override
  State<SeccionResenasPerfil> createState() => _SeccionResenasPerfilState();
}

class _SeccionResenasPerfilState extends State<SeccionResenasPerfil> {
  List<Resena> _resenasRecibidas = [];
  List<Resena> _resenasHechas = [];
  List<ResenaViajero> _resenasViajerosRecibidas = [];
  List<ResenaViajero> _resenasViajerosHechas = [];
  Map<String, dynamic> _estadisticas = {};
  bool _isLoading = true;
  String _filtroActual =
      'propiedades_recibidas'; // Siempre empezar con reseñas recibidas

  @override
  void initState() {
    super.initState();
    _cargarResenas();
  }

  Future<void> _cargarResenas() async {
    try {
      if (widget.esPerfilPropio) {
        // Si es el perfil propio, cargar todas las reseñas
        final futures = await Future.wait([
          widget.resenasRepository.getResenasRecibidas(widget.userId),
          widget.resenasRepository.getResenasHechas(widget.userId),
          widget.resenasRepository.getResenasViajerosRecibidas(widget.userId),
          widget.resenasRepository.getResenasViajerosHechas(widget.userId),
          widget.resenasRepository.getEstadisticasCompletasResenas(
            widget.userId,
          ),
        ]);

        if (mounted) {
          setState(() {
            _resenasRecibidas = futures[0] as List<Resena>;
            _resenasHechas = futures[1] as List<Resena>;
            _resenasViajerosRecibidas = futures[2] as List<ResenaViajero>;
            _resenasViajerosHechas = futures[3] as List<ResenaViajero>;
            _estadisticas = futures[4] as Map<String, dynamic>;
            _isLoading = false;
          });
        }
      } else {
        // Si es el perfil de otro usuario, solo cargar reseñas recibidas
        final futures = await Future.wait([
          widget.resenasRepository.getResenasRecibidas(widget.userId),
          widget.resenasRepository.getResenasViajerosRecibidas(widget.userId),
          widget.resenasRepository.getEstadisticasCompletasResenas(
            widget.userId,
          ),
        ]);

        if (mounted) {
          setState(() {
            _resenasRecibidas = futures[0] as List<Resena>;
            _resenasHechas = []; // No cargar reseñas hechas
            _resenasViajerosRecibidas = futures[1] as List<ResenaViajero>;
            _resenasViajerosHechas = []; // No cargar reseñas hechas
            _estadisticas = futures[2] as Map<String, dynamic>;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reseñas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de la sección
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Reseñas',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),

        const SizedBox(height: 16),

        // Títulos de usuario (si aplica)
        TituloUsuarioWidget(
          promedioAnfitrion:
              _estadisticas['promedioRecibidas'] as double? ?? 0.0,
          totalResenasAnfitrion:
              _estadisticas['totalResenasRecibidas'] as int? ?? 0,
          promedioViajero:
              _estadisticas['promedioComoViajero'] as double? ?? 0.0,
          totalResenasViajero:
              _estadisticas['totalResenasComoViajero'] as int? ?? 0,
        ),

        const SizedBox(height: 16),

        // Estadísticas visuales (siempre mostrar)
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: _buildEstadisticasVisuales(),
        ),

        const SizedBox(height: 16),

        // Filtros
        _buildFiltros(),

        const SizedBox(height: 16),

        // Lista de reseñas
        _buildListaResenas(),
      ],
    );
  }

  Widget _buildEstadisticasVisuales() {
    // Calcular estadísticas localmente como respaldo
    final estadisticasLocales = _calcularEstadisticasLocales();

    final promedioAnfitrion =
        estadisticasLocales['promedioAnfitrion'] as double;
    final totalAnfitrion = estadisticasLocales['totalAnfitrion'] as int;
    final distribucionAnfitrion =
        estadisticasLocales['distribucionAnfitrion'] as Map<String, dynamic>;

    final promedioViajero = estadisticasLocales['promedioViajero'] as double;
    final totalViajero = estadisticasLocales['totalViajero'] as int;
    final distribucionViajero =
        estadisticasLocales['distribucionViajero'] as Map<String, dynamic>;

    // Mostrar siempre al menos una sección
    final hayResenasAnfitrion = totalAnfitrion > 0;
    final hayResenasViajero = totalViajero > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Si hay reseñas en ambas categorías, mostrar en fila
          if (hayResenasAnfitrion && hayResenasViajero)
            Row(
              children: [
                Expanded(
                  child: RatingVisualWidget(
                    promedio: promedioAnfitrion,
                    totalResenas: totalAnfitrion,
                    distribucion: distribucionAnfitrion,
                    colorTema: Colors.green,
                    tipo: 'anfitrion',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RatingVisualWidget(
                    promedio: promedioViajero,
                    totalResenas: totalViajero,
                    distribucion: distribucionViajero,
                    colorTema: Colors.blue,
                    tipo: 'viajero',
                  ),
                ),
              ],
            )
          // Si solo hay reseñas de anfitrión
          else if (hayResenasAnfitrion)
            RatingVisualWidget(
              promedio: promedioAnfitrion,
              totalResenas: totalAnfitrion,
              distribucion: distribucionAnfitrion,
              colorTema: Colors.green,
              tipo: 'anfitrion',
            )
          // Si solo hay reseñas de viajero
          else if (hayResenasViajero)
            RatingVisualWidget(
              promedio: promedioViajero,
              totalResenas: totalViajero,
              distribucion: distribucionViajero,
              colorTema: Colors.blue,
              tipo: 'viajero',
            )
          // Si no hay reseñas, mostrar estado vacío para anfitrión
          else
            RatingVisualWidget(
              promedio: 0.0,
              totalResenas: 0,
              distribucion: {},
              colorTema: Colors.green,
              tipo: 'anfitrion',
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calcularEstadisticasLocales() {
    // Calcular estadísticas de propiedades (como anfitrión)
    double promedioAnfitrion = 0.0;
    int totalAnfitrion = _resenasRecibidas.length;
    Map<String, dynamic> distribucionAnfitrion = {};

    if (totalAnfitrion > 0) {
      final suma = _resenasRecibidas
          .map((r) => r.calificacion)
          .reduce((a, b) => a + b);
      promedioAnfitrion = suma / totalAnfitrion;

      // Calcular distribución
      for (int i = 1; i <= 5; i++) {
        distribucionAnfitrion[i.toString()] = _resenasRecibidas
            .where((r) => r.calificacion.round() == i)
            .length;
      }
    }

    // Calcular estadísticas de viajero
    double promedioViajero = 0.0;
    int totalViajero = _resenasViajerosRecibidas.length;
    Map<String, dynamic> distribucionViajero = {};

    if (totalViajero > 0) {
      final suma = _resenasViajerosRecibidas
          .map((r) => r.calificacionMostrar)
          .reduce((a, b) => a + b);
      promedioViajero = suma / totalViajero;

      // Calcular distribución
      for (int i = 1; i <= 5; i++) {
        distribucionViajero[i.toString()] = _resenasViajerosRecibidas
            .where((r) => r.calificacionMostrar.round() == i)
            .length;
      }
    }

    return {
      'promedioAnfitrion': promedioAnfitrion,
      'totalAnfitrion': totalAnfitrion,
      'distribucionAnfitrion': distribucionAnfitrion,
      'promedioViajero': promedioViajero,
      'totalViajero': totalViajero,
      'distribucionViajero': distribucionViajero,
    };
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Contenedor para filtros de propiedades
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.home, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Reseñas de Propiedades',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                widget.esPerfilPropio
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildBotonFiltro(
                              'propiedades_recibidas',
                              'Recibidas (${_resenasRecibidas.length})',
                              _filtroActual == 'propiedades_recibidas',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildBotonFiltro(
                              'propiedades_hechas',
                              'Hechas (${_resenasHechas.length})',
                              _filtroActual == 'propiedades_hechas',
                              Colors.green,
                            ),
                          ),
                        ],
                      )
                    : Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 200,
                          child: _buildBotonFiltro(
                            'propiedades_recibidas',
                            'Reseñas Recibidas (${_resenasRecibidas.length})',
                            _filtroActual == 'propiedades_recibidas',
                            Colors.green,
                          ),
                        ),
                      ),
              ],
            ),
          ),

          SizedBox(height: widget.esPerfilPropio ? 12 : 8),

          // Contenedor para filtros de viajero
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.luggage, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Reseñas como Viajero',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                widget.esPerfilPropio
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildBotonFiltro(
                              'viajero_recibidas',
                              'Recibidas (${_resenasViajerosRecibidas.length})',
                              _filtroActual == 'viajero_recibidas',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildBotonFiltro(
                              'viajero_hechas',
                              'Hechas (${_resenasViajerosHechas.length})',
                              _filtroActual == 'viajero_hechas',
                              Colors.blue,
                            ),
                          ),
                        ],
                      )
                    : Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 200,
                          child: _buildBotonFiltro(
                            'viajero_recibidas',
                            'Reseñas Recibidas (${_resenasViajerosRecibidas.length})',
                            _filtroActual == 'viajero_recibidas',
                            Colors.blue,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonFiltro(
    String filtro,
    String texto,
    bool activo,
    Color color,
  ) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _filtroActual = filtro;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: activo ? color : Theme.of(context).colorScheme.surface,
        foregroundColor: activo
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface,
        elevation: activo ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      child: Text(texto, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildListaResenas() {
    List<Widget> widgets = [];
    String mensajeVacio = '';
    String tituloSeccion = '';
    Color colorSeccion = Colors.grey;
    IconData iconoSeccion = Icons.rate_review;

    switch (_filtroActual) {
      case 'propiedades_recibidas':
        widgets = _resenasRecibidas
            .map((resena) => ResenaCard(resena: resena, esRecibida: true))
            .toList();
        mensajeVacio = widget.esPerfilPropio
            ? 'Aún no has recibido reseñas en tus propiedades'
            : 'Este usuario aún no ha recibido reseñas en sus propiedades';
        tituloSeccion = 'Reseñas Recibidas de Propiedades';
        colorSeccion = Colors.green;
        iconoSeccion = Icons.home;
        break;
      case 'propiedades_hechas':
        // Solo mostrar si es perfil propio
        if (widget.esPerfilPropio) {
          widgets = _resenasHechas
              .map((resena) => ResenaCard(resena: resena, esRecibida: false))
              .toList();
          mensajeVacio = 'Aún no has hecho reseñas de propiedades';
          tituloSeccion = 'Reseñas Hechas de Propiedades';
          colorSeccion = Colors.green;
          iconoSeccion = Icons.home;
        }
        break;
      case 'viajero_recibidas':
        widgets = _resenasViajerosRecibidas
            .map(
              (resena) =>
                  ResenaViajeroCard(resena: resena, mostrarViajero: true),
            )
            .toList();
        mensajeVacio = widget.esPerfilPropio
            ? 'Aún no has recibido reseñas como viajero'
            : 'Este usuario aún no ha recibido reseñas como viajero';
        tituloSeccion = 'Reseñas Recibidas como Viajero';
        colorSeccion = Colors.blue;
        iconoSeccion = Icons.luggage;
        break;
      case 'viajero_hechas':
        // Solo mostrar si es perfil propio
        if (widget.esPerfilPropio) {
          widgets = _resenasViajerosHechas
              .map(
                (resena) =>
                    ResenaViajeroCard(resena: resena, mostrarViajero: true),
              )
              .toList();
          mensajeVacio = 'Aún no has hecho reseñas de viajeros';
          tituloSeccion = 'Reseñas Hechas de Viajeros';
          colorSeccion = Colors.blue;
          iconoSeccion = Icons.luggage;
        }
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de la sección actual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorSeccion.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorSeccion.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(iconoSeccion, color: colorSeccion, size: 18),
                const SizedBox(width: 8),
                Text(
                  tituloSeccion,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorSeccion,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widgets.length} reseña${widgets.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: colorSeccion,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Lista de reseñas o mensaje vacío
          if (widgets.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      mensajeVacio,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...widgets,
        ],
      ),
    );
  }
}
