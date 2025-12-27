import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:donde_caigav2/main.dart';
import 'package:donde_caigav2/features/auth/data/models/user_profile.dart';
import 'package:donde_caigav2/features/auth/data/repositories/user_repository.dart';
import 'package:donde_caigav2/features/propiedades/data/models/propiedad.dart';
import 'package:donde_caigav2/features/propiedades/data/repositories/propiedad_repository.dart';
import 'package:donde_caigav2/features/reservas/presentation/screens/reserva_calendario_screen.dart';
import 'package:donde_caigav2/features/resenas/presentation/widgets/resenas_list_widget.dart';
import 'package:donde_caigav2/features/perfil/presentation/widgets/boton_ver_perfil.dart';

class DetallePropiedadScreen extends StatefulWidget {
  final String propiedadId;

  const DetallePropiedadScreen({super.key, required this.propiedadId});

  @override
  State<DetallePropiedadScreen> createState() => _DetallePropiedadScreenState();
}

class _DetallePropiedadScreenState extends State<DetallePropiedadScreen> {
  late final PropiedadRepository _propiedadRepository;
  late final UserRepository _userRepository;

  Propiedad? _propiedad;
  UserProfile? _anfitrion;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _propiedadRepository = PropiedadRepository(supabase);
    _userRepository = UserRepository(supabase);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final propiedad = await _propiedadRepository.obtenerPropiedadPorId(
        widget.propiedadId,
      );
      final anfitrion = await _userRepository.getUserProfile(
        propiedad.anfitrionId,
      );

      setState(() {
        _propiedad = propiedad;
        _anfitrion = anfitrion;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _mostrarReserva() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para reservar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Verificar que el usuario no sea el anfitrión
    if (user.id == _propiedad!.anfitrionId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes reservar tu propio alojamiento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navegar a la pantalla de reserva
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservaCalendarioScreen(propiedad: _propiedad!),
      ),
    );

    // Si se creó la reserva, mostrar mensaje
    if (resultado == true && mounted) {
      // La reserva se creó exitosamente
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _propiedad == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF4DB6AC),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error al cargar el alojamiento',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargarDatos,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // AppBar con imagen
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: const Color(0xFF4DB6AC),
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: _propiedad!.fotoPrincipalUrl != null
                ? Image.network(
                    _propiedad!.fotoPrincipalUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.home,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.home, size: 80, color: Colors.grey),
                  ),
          ),
        ),

        // Contenido
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  _propiedad!.titulo,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Anfitrión
                if (_anfitrion != null)
                  Row(
                    children: [
                      // Avatar del anfitrión clickeable
                      BotonVerPerfil.icono(
                        userId: _anfitrion!.id,
                        nombreUsuario: _anfitrion!.nombre,
                        fotoUsuario: _anfitrion!.fotoPerfilUrl,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Anfitrión',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          // Nombre del anfitrión clickeable
                          BotonVerPerfil.texto(
                            userId: _anfitrion!.id,
                            nombreUsuario: _anfitrion!.nombre,
                          ),
                        ],
                      ),
                    ],
                  ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // Información básica
                _InfoRow(
                  icon: Icons.people,
                  label: 'Capacidad',
                  value: '${_propiedad!.capacidadPersonas} personas',
                ),

                if (_propiedad!.numeroHabitaciones != null) ...[
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.bed,
                    label: 'Habitaciones',
                    value: '${_propiedad!.numeroHabitaciones}',
                  ),
                ],

                if (_propiedad!.numeroBanos != null) ...[
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.bathroom,
                    label: 'Baños',
                    value: '${_propiedad!.numeroBanos}',
                  ),
                ],

                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.garage,
                  label: 'Garaje',
                  value: _propiedad!.tieneGaraje ? 'Sí' : 'No',
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // Ubicación
                const Text(
                  'Ubicación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF4DB6AC),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _propiedad!.direccion,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),

                if (_propiedad!.ciudad != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 28),
                      Text(
                        '${_propiedad!.ciudad}${_propiedad!.pais != null ? ', ${_propiedad!.pais}' : ''}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],

                // Mapa (si tiene coordenadas)
                if (_propiedad!.latitud != null &&
                    _propiedad!.longitud != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          _propiedad!.latitud!,
                          _propiedad!.longitud!,
                        ),
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.donde_caigav2',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _propiedad!.latitud!,
                                _propiedad!.longitud!,
                              ),
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.location_on,
                                size: 50,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // Descripción
                if (_propiedad!.descripcion != null) ...[
                  const Text(
                    'Descripción',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _propiedad!.descripcion!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Botón de reserva
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _mostrarReserva,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4DB6AC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reservar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 8),

                // Widget de reseñas
                ResenasListWidget(propiedadId: widget.propiedadId),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4DB6AC), size: 24),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
