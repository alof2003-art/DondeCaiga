import 'package:flutter/material.dart';
import '../../../../main.dart';
import '../../../propiedades/data/models/propiedad.dart';
import '../../../propiedades/data/repositories/propiedad_repository.dart';
import 'detalle_propiedad_screen.dart';
import '../../../../core/widgets/user_name_widget.dart';

class ExplorarScreen extends StatefulWidget {
  const ExplorarScreen({super.key});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  late final PropiedadRepository _propiedadRepository;
  List<Propiedad> _propiedades = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _propiedadRepository = PropiedadRepository(supabase);
    _cargarPropiedades();
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Alojamientos'),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
        actions: [UserNameWidget(supabase: supabase)],
      ),
      body: _buildBody(),
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _propiedades.length,
        itemBuilder: (context, index) {
          final propiedad = _propiedades[index];
          return _PropiedadCard(
            propiedad: propiedad,
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
      ),
    );
  }
}

class _PropiedadCard extends StatelessWidget {
  final Propiedad propiedad;
  final VoidCallback onTap;

  const _PropiedadCard({required this.propiedad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.home,
                                size: 60,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.home,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                ),

                // Información
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        propiedad.titulo,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Información del anfitrión
                      if (propiedad.nombreAnfitrion != null)
                        _HostInfoRow(
                          nombreAnfitrion: propiedad.nombreAnfitrion!,
                          calificacionAnfitrion:
                              propiedad.calificacionAnfitrion,
                        ),

                      if (propiedad.nombreAnfitrion != null)
                        const SizedBox(height: 8),

                      // Ciudad
                      if (propiedad.ciudad != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Color(0xFF4DB6AC),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                propiedad.ciudad!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 8),

                      // Capacidad
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 16,
                            color: Color(0xFF4DB6AC),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${propiedad.capacidadPersonas} personas',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
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
