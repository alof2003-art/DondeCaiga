import 'package:flutter/material.dart';
import 'package:donde_caigav2/main.dart';
import 'package:donde_caigav2/services/auth_service.dart';
import 'package:donde_caigav2/services/storage_service.dart';
import 'package:donde_caigav2/features/auth/data/repositories/user_repository.dart';
import 'package:donde_caigav2/features/auth/presentation/screens/login_screen.dart';
import 'package:donde_caigav2/features/anfitrion/presentation/screens/admin_solicitudes_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late final AuthService _authService;
  late final UserRepository _userRepository;
  String? _userEmail;
  String? _userName;
  String? _fotoPerfilUrl;
  int? _userRolId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(
      supabase,
      StorageService(supabase),
      UserRepository(supabase),
    );
    _userRepository = UserRepository(supabase);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        // Obtener el perfil completo desde la base de datos
        final perfil = await _userRepository.getUserProfile(user.id);

        if (perfil != null && mounted) {
          setState(() {
            _userEmail = perfil.email;
            _userName = perfil.nombre;
            _fotoPerfilUrl = perfil.fotoPerfilUrl;
            _userRolId = perfil.rolId;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error cargando perfil: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            _isLoading
                ? const CircularProgressIndicator()
                : CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFF4DB6AC),
                    backgroundImage: _fotoPerfilUrl != null
                        ? NetworkImage(_fotoPerfilUrl!)
                        : null,
                    child: _fotoPerfilUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                        : null,
                  ),
            const SizedBox(height: 24),
            // Nombre
            Text(
              _userName ?? 'Cargando...',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 8),
            // Email
            Text(
              _userEmail ?? '',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),

            // Botón de Admin (solo para rol_id = 3)
            if (_userRolId == 3) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ADMINISTRADOR',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminSolicitudesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.pending_actions),
                  label: const Text('Solicitudes Pendientes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4DB6AC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botón de cerrar sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
