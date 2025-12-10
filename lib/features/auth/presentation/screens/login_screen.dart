import 'package:flutter/material.dart';
import '../../../../main.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/validation_service.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../../../core/utils/error_handler.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/blocked_account_dialog.dart';
import 'register_screen.dart';
import '../../../main/presentation/screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService(
      supabase,
      StorageService(supabase),
      UserRepository(supabase),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validar campos
    setState(() {
      _emailError = ValidationService.validateEmail(_emailController.text);
      _passwordError = ValidationService.validatePassword(
        _passwordController.text,
      );
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Navegar a MainScreen
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    } catch (e) {
      if (!mounted) return;

      // Manejar cuenta bloqueada con diálogo especial
      if (e is AccountBlockedException) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => BlockedAccountDialog(message: e.message),
        );
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                ),
              ),

              const SizedBox(height: 16),

              // Bienvenido
              const Center(
                child: Text(
                  'Bienvenido',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4DB6AC),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Título
              const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),

              const SizedBox(height: 32),

              // Campo de email
              CustomTextField(
                controller: _emailController,
                hintText: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Campo de contraseña
              CustomTextField(
                controller: _passwordController,
                hintText: 'Contraseña',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                errorText: _passwordError,
                onChanged: (_) {
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
              ),

              const SizedBox(height: 32),

              // Botón de login
              CustomButton(
                text: 'ENTRAR',
                onPressed: _handleLogin,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 24),

              // Link de registro
              Center(
                child: TextButton(
                  onPressed: _navigateToRegister,
                  child: const Text(
                    '¿No tienes cuenta? Regístrate aquí',
                    style: TextStyle(
                      color: Color(0xFF4DB6AC),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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
