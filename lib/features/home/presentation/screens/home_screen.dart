import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../main.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/storage_service.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../core/widgets/user_name_widget.dart';
import '../../../notificaciones/presentation/providers/notificaciones_provider.dart';
import '../../../notificaciones/services/notifications_service.dart';
import '../../../main/presentation/screens/main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthService _authService;
  String? _userEmail;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(
      supabase,
      StorageService(supabase),
      UserRepository(supabase),
    );
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _userEmail = user.email;
        });

        // Inicializar servicio de notificaciones
        final notificationsService = NotificationsService();
        await notificationsService.initialize();

        // Inicializar provider de notificaciones
        if (mounted) {
          final notificacionesProvider = Provider.of<NotificacionesProvider>(
            context,
            listen: false,
          );
          await notificacionesProvider.inicializar();
          debugPrint('✅ Sistema de notificaciones inicializado');
        }

        // Navegar a la pantalla principal
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error al inicializar app: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
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
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4DB6AC)),
              ),
              SizedBox(height: 16),
              Text(
                'Inicializando...',
                style: TextStyle(fontSize: 16, color: Color(0xFF78909C)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donde Caiga'),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
        actions: [
          UserNameWidget(supabase: supabase),
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
                'Redirigiendo a la aplicación...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Color(0xFF263238)),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar'),
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
