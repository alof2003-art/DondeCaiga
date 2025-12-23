import 'package:flutter/material.dart';
import '../../data/models/resena.dart';
import '../../data/repositories/resenas_repository.dart';
import 'resena_card.dart';

class SeccionResenasPerfil extends StatefulWidget {
  final String userId;
  final ResenasRepository resenasRepository;

  const SeccionResenasPerfil({
    super.key,
    required this.userId,
    required this.resenasRepository,
  });

  @override
  State<SeccionResenasPerfil> createState() => _SeccionResenasPerfilState();
}

class _SeccionResenasPerfilState extends State<SeccionResenasPerfil> {
  List<Resena> _resenasRecibidas = [];
  List<Resena> _resenasHechas = [];
  Map<String, dynamic> _estadisticas = {};
  bool _isLoading = true;
  String _filtroActual = 'recibidas'; // 'recibidas', 'hechas'

  @override
  void initState() {
    super.initState();
    _cargarResenas();
  }

  Future<void> _cargarResenas() async {
    try {
      final futures = await Future.wait([
        widget.resenasRepository.getResenasRecibidas(widget.userId),
        widget.resenasRepository.getResenasHechas(widget.userId),
        widget.resenasRepository.getEstadisticasResenas(widget.userId),
      ]);

      if (mounted) {
        setState(() {
          _resenasRecibidas = futures[0] as List<Resena>;
          _resenasHechas = futures[1] as List<Resena>;
          _estadisticas = futures[2] as Map<String, dynamic>;
          _isLoading = false;
        });
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

        // Estadísticas (solo si hay reseñas recibidas)
        if (_resenasRecibidas.isNotEmpty) _buildEstadisticas(),

        const SizedBox(height: 16),

        // Filtros
        _buildFiltros(),

        const SizedBox(height: 16),

        // Lista de reseñas
        _buildListaResenas(),
      ],
    );
  }

  Widget _buildEstadisticas() {
    final promedio = _estadisticas['promedioCalificacion'] as double;
    final total = _estadisticas['totalResenas'] as int;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Calificación promedio
          Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 4),
                  Text(
                    promedio.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '$total reseña${total != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),

          const SizedBox(width: 24),

          // Distribución de estrellas
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final estrellas = 5 - index;
                final distribucion =
                    _estadisticas['distribucionCalificaciones']
                        as Map<int, int>;
                final cantidad = distribucion[estrellas] ?? 0;
                final porcentaje = total > 0 ? cantidad / total : 0.0;

                return Row(
                  children: [
                    Text('$estrellas', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: porcentaje,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cantidad.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildBotonFiltro(
              'recibidas',
              'Recibidas (${_resenasRecibidas.length})',
              _filtroActual == 'recibidas',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBotonFiltro(
              'hechas',
              'Hechas (${_resenasHechas.length})',
              _filtroActual == 'hechas',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonFiltro(String filtro, String texto, bool activo) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _filtroActual = filtro;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: activo
            ? Theme.of(context).primaryColor
            : Theme.of(context).colorScheme.surface,
        foregroundColor: activo
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface,
        elevation: activo ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Text(texto, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildListaResenas() {
    final resenas = _filtroActual == 'recibidas'
        ? _resenasRecibidas
        : _resenasHechas;

    if (resenas.isEmpty) {
      return Padding(
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
                _filtroActual == 'recibidas'
                    ? 'Aún no has recibido reseñas'
                    : 'Aún no has hecho reseñas',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: resenas
            .map(
              (resena) => ResenaCard(
                resena: resena,
                esRecibida: _filtroActual == 'recibidas',
              ),
            )
            .toList(),
      ),
    );
  }
}
