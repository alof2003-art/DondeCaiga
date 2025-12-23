import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../main.dart';
import 'login_screen.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newPassword = _passwordController.text.trim();

      // Verificar si hay una sesión activa
      final session = supabase.auth.currentSession;
      if (session?.user == null) {
        throw Exception(
          'No hay una sesión activa. Debes hacer clic en el enlace del email primero.',
        );
      }

      // Actualizar contraseña usando Supabase
      await supabase.auth.updateUser(UserAttributes(password: newPassword));

      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña actualizada exitosamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navegar al login y limpiar el stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    final hasValidSession = session?.user != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Contraseña'),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // No mostrar botón de volver
      ),
      body: Column(
        children: [
          // Indicador de estado de sesión
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: hasValidSession ? Colors.green[100] : Colors.red[100],
            child: Row(
              children: [
                Icon(
                  hasValidSession ? Icons.check_circle : Icons.error,
                  color: hasValidSession ? Colors.green[700] : Colors.red[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasValidSession
                        ? '✅ Sesión activa - Puedes cambiar tu contraseña'
                        : '❌ Sin sesión - Debes hacer clic en el enlace del email primero',
                    style: TextStyle(
                      color: hasValidSession
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // Icono
                    Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),

                    const SizedBox(height: 32),

                    // Título
                    Text(
                      'Crear Nueva Contraseña',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    // Descripción
                    Text(
                      hasValidSession
                          ? 'Ingresa tu nueva contraseña. Asegúrate de que sea segura y fácil de recordar.'
                          : 'Para cambiar tu contraseña, primero debes hacer clic en el enlace que recibiste por email.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasValidSession
                            ? Colors.grey[600]
                            : Colors.red[600],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Campo de nueva contraseña
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_isLoading && hasValidSession,
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                        hintText: 'Mínimo 6 caracteres',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4DB6AC),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa una contraseña';
                        }

                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Campo de confirmar contraseña
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      enabled: !_isLoading && hasValidSession,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        hintText: 'Repite la contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4DB6AC),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor confirma tu contraseña';
                        }

                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Botón de actualizar contraseña
                    ElevatedButton(
                      onPressed: (_isLoading || !hasValidSession)
                          ? null
                          : _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasValidSession
                            ? const Color(0xFF4DB6AC)
                            : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              hasValidSession
                                  ? 'Actualizar Contraseña'
                                  : 'Sesión Requerida',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),

                    const SizedBox(height: 32),

                    // Información de seguridad
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: hasValidSession
                            ? Colors.green[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasValidSession
                              ? Colors.green[200]!
                              : Colors.orange[200]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            hasValidSession ? Icons.security : Icons.info,
                            color: hasValidSession
                                ? Colors.green[600]
                                : Colors.orange[600],
                            size: 20,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasValidSession
                                ? 'Consejos para una contraseña segura:'
                                : 'Instrucciones:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: hasValidSession
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasValidSession
                                ? '• Usa al menos 8 caracteres\n'
                                      '• Combina letras, números y símbolos\n'
                                      '• Evita información personal\n'
                                      '• No uses la misma contraseña en otros sitios'
                                : '1. Ve a tu email\n'
                                      '2. Busca el email de recuperación\n'
                                      '3. Haz clic en el enlace del email\n'
                                      '4. Regresa aquí para cambiar tu contraseña',
                            style: TextStyle(
                              fontSize: 12,
                              color: hasValidSession
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24), // Padding final
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
