import 'package:flutter/material.dart';
import '../../../../main.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/storage_service.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthService _authService;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(
      supabase,
      StorageService(supabase),
      UserRepository(supabase),
    );
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      setState(() {
        _userEmail = user.email;
      });
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
        title: const Text('Donde Caiga'),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 100,
                color: Color(0xFF4DB6AC),
              ),
              const SizedBox(height: 24),
              const Text(
                '¡Bienvenido!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
              const SizedBox(height: 16),
              if (_userEmail != null)
                Text(
                  _userEmail!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF78909C),
                  ),
                ),
              const SizedBox(height: 32),
              const Text(
                'Has iniciado sesión exitosamente',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Color(0xFF263238)),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DB6AC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
