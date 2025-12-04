import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../main.dart';
import 'login_screen.dart';
import '../../../main/presentation/screens/main_screen.dart';
import 'package:donde_caigav2/services/auth_service.dart';
import 'package:donde_caigav2/services/storage_service.dart';
import 'package:donde_caigav2/features/auth/data/repositories/user_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Esperar 2-3 segundos
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Verificar si hay sesión activa
    final authService = AuthService(
      supabase,
      StorageService(supabase),
      UserRepository(supabase),
    );

    final hasSession = await authService.hasActiveSession();

    if (!mounted) return;

    if (hasSession) {
      // Si hay sesión activa, ir a main
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    } else {
      // Si no hay sesión, ir a login
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset('assets/images/logo.png', width: 200, height: 200),
            const SizedBox(height: 24),
            // Nombre de la app
            const Text(
              'Donde Caiga',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 8),
            // Tagline
            const Text(
              'Viaja. Conoce. Comparte.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF78909C),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            // Indicador de carga
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4DB6AC)),
            ),
          ],
        ),
      ),
    );
  }
}
