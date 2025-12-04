import 'package:flutter/material.dart';
import '../../../../main.dart';
import '../../../propiedades/data/models/propiedad.dart';
import '../../../propiedades/data/repositories/propiedad_repository.dart';
import 'detalle_propiedad_screen.dart';

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
        child: Column(
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
