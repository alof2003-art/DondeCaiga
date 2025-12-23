import 'package:flutter/material.dart';
import 'package:donde_caigav2/main.dart';
import 'package:donde_caigav2/features/auth/data/repositories/user_repository.dart';
import 'package:donde_caigav2/features/propiedades/presentation/screens/crear_propiedad_screen.dart';
import 'package:donde_caigav2/features/propiedades/presentation/screens/editar_propiedad_screen.dart';
import 'package:donde_caigav2/features/propiedades/data/repositories/propiedad_repository.dart';
import 'package:donde_caigav2/features/propiedades/data/models/propiedad.dart';
import 'package:donde_caigav2/features/reservas/presentation/screens/mis_reservas_anfitrion_screen.dart';
import 'package:donde_caigav2/features/anfitrion/presentation/screens/solicitud_anfitrion_screen.dart';
import 'package:donde_caigav2/core/widgets/custom_app_bar_header.dart';

class AnfitrionScreen extends StatefulWidget {
  const AnfitrionScreen({super.key});

  @override
  State<AnfitrionScreen> createState() => _AnfitrionScreenState();
}

class _AnfitrionScreenState extends State<AnfitrionScreen> {
  late final UserRepository _userRepository;
  int? _userRolId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userRepository = UserRepository(supabase);
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final perfil = await _userRepository.getUserProfile(user.id);
        if (perfil != null && mounted) {
          setState(() {
            _userRolId = perfil.rolId;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error cargando rol: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomAppBarHeader(supabase: supabase, screenTitle: 'Anfitrión'),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContentByRole(),
    );
  }

  Widget _buildContentByRole() {
    // Rol 1 = Viajero
    if (_userRolId == 1) {
      return _buildViajeroView();
    }
    // Rol 2 = Anfitrión o Rol 3 = Admin (ambos ven lo mismo)
    else if (_userRolId == 2 || _userRolId == 3) {
      return _buildAnfitrionView();
    }
    // Por defecto
    return _buildViajeroView();
  }

  // Vista para Viajeros: Solicitar ser anfitrión
  Widget _buildViajeroView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work, size: 100, color: const Color(0xFF757575)),
            const SizedBox(height: 24),
            Text(
              '¿Quieres ser Anfitrión?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Comparte tu espacio y ofrece alojamiento gratuito a viajeros de todo el mundo',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Color(0xFF424242)),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SolicitudAnfitrionScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.send),
              label: const Text('Solicitar ser Anfitrión'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DB6AC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Vista para Anfitriones: Gestionar alojamientos
  Widget _buildAnfitrionView() {
    return Column(
      children: [
        // Botón de Reservas
        Container(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MisReservasAnfitrionScreen(),
                ),
              );
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('Ver Mis Reservas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DB6AC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
        // Lista de propiedades
        Expanded(child: _MisPropiedadesView()),
      ],
    );
  }
}

// Widget para mostrar las propiedades del anfitrión
class _MisPropiedadesView extends StatefulWidget {
  @override
  State<_MisPropiedadesView> createState() => _MisPropiedadesViewState();
}

class _MisPropiedadesViewState extends State<_MisPropiedadesView> {
  late final PropiedadRepository _propiedadRepository;
  List<Propiedad> _propiedades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _propiedadRepository = PropiedadRepository(supabase);
    _cargarPropiedades();
  }

  Future<void> _cargarPropiedades() async {
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final propiedades = await _propiedadRepository
            .obtenerPropiedadesAnfitrion(user.id);
        if (mounted) {
          setState(() {
            _propiedades = propiedades;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header con botón crear
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mis Alojamientos',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CrearPropiedadScreen(),
                    ),
                  );
                  _cargarPropiedades(); // Recargar después de crear
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DB6AC),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Lista de propiedades
        Expanded(
          child: _propiedades.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_outlined,
                        size: 80,
                        color: const Color(0xFF757575),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes alojamientos',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFF424242),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea tu primer alojamiento',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarPropiedades,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(), // Física más suave
                    cacheExtent: 200, // Cache para mejor rendimiento
                    itemCount: _propiedades.length,
                    itemBuilder: (context, index) {
                      final propiedad = _propiedades[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () async {
                            // Navegar a editar
                            final resultado = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditarPropiedadScreen(propiedad: propiedad),
                              ),
                            );
                            if (resultado == true) {
                              _cargarPropiedades();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: propiedad.fotoPrincipalUrl != null
                                      ? Image.network(
                                          propiedad.fotoPrincipalUrl!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return Container(
                                                  width: 60,
                                                  height: 60,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.home),
                                                );
                                              },
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.home),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        propiedad.titulo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      if (propiedad.ciudad != null)
                                        Text(
                                          propiedad.ciudad!,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF424242),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${propiedad.capacidadPersonas} personas',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF424242),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Chip(
                                      label: Text(
                                        propiedad.estado,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor:
                                          propiedad.estado == 'activo'
                                          ? Colors.green[100]
                                          : const Color(0xFFE0E0E0),
                                    ),
                                    const SizedBox(height: 4),
                                    Icon(
                                      Icons.edit,
                                      color: const Color(0xFF757575),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
