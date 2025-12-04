import 'package:flutter/material.dart';
import '../../data/models/resena.dart';
import '../../data/repositories/resena_repository.dart';

class ResenasListWidget extends StatefulWidget {
  final String propiedadId;

  const ResenasListWidget({super.key, required this.propiedadId});

  @override
  State<ResenasListWidget> createState() => _ResenasListWidgetState();
}

class _ResenasListWidgetState extends State<ResenasListWidget> {
  final ResenaRepository _resenaRepository = ResenaRepository();
  List<Resena> _resenas = [];
  bool _isLoading = true;
  double _promedioCalificacion = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarResenas();
  }

  Future<void> _cargarResenas() async {
    try {
      setState(() => _isLoading = true);

      final resenas = await _resenaRepository.obtenerResenasPorPropiedad(
        widget.propiedadId,
      );

      // Calcular promedio de calificación
      double promedio = 0.0;
      if (resenas.isNotEmpty) {
        final suma = resenas.fold<int>(
          0,
          (sum, resena) => sum + resena.calificacion,
        );
        promedio = suma / resenas.length;
      }

      setState(() {
        _resenas = resenas;
        _promedioCalificacion = promedio;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar reseñas: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con título y promedio
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Reseñas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              if (_resenas.isNotEmpty) ...[
                Icon(Icons.star, color: Colors.amber[700], size: 24),
                const SizedBox(width: 4),
                Text(
                  _promedioCalificacion.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  ' (${_resenas.length})',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),

        // Lista de reseñas
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_resenas.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no hay reseñas',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sé el primero en dejar una reseña',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _resenas.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final resena = _resenas[index];
              return _ResenaCard(resena: resena);
            },
          ),
      ],
    );
  }
}

class _ResenaCard extends StatelessWidget {
  final Resena resena;

  const _ResenaCard({required this.resena});

  @override
  Widget build(BuildContext context) {
    final nombreViajero = resena.nombreViajero ?? 'Usuario';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con nombre y fecha
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.teal[100],
                child: Text(
                  nombreViajero.isNotEmpty
                      ? nombreViajero[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: Colors.teal[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Nombre y fecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreViajero,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatearFecha(resena.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Calificación
              _buildEstrellas(resena.calificacion),
            ],
          ),

          // Comentario
          if (resena.comentario != null && resena.comentario!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              resena.comentario!,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstrellas(int calificacion) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < calificacion ? Icons.star : Icons.star_border,
          color: Colors.amber[700],
          size: 18,
        );
      }),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) {
      return 'Hoy';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else if (diferencia.inDays < 30) {
      final semanas = (diferencia.inDays / 7).floor();
      return 'Hace $semanas ${semanas == 1 ? 'semana' : 'semanas'}';
    } else if (diferencia.inDays < 365) {
      final meses = (diferencia.inDays / 30).floor();
      return 'Hace $meses ${meses == 1 ? 'mes' : 'meses'}';
    } else {
      final anos = (diferencia.inDays / 365).floor();
      return 'Hace $anos ${anos == 1 ? 'año' : 'años'}';
    }
  }
}
