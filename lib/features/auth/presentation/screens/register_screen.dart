import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../main.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/storage_service.dart';
import '../../../../services/validation_service.dart';
import '../../../auth/data/repositories/user_repository.dart';
import '../../../auth/data/models/user_registration_data.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/profile_photo_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  File? _profilePhoto;
  File? _idDocument;
  bool _isLoading = false;

  String? _nombreError;
  String? _telefonoError;
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
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickIdDocument() async {
    final picker = ImagePicker();

    // Mostrar opciones: cámara o galería
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _idDocument = File(pickedFile.path);
      });
    }
  }

  Future<void> _handleRegister() async {
    // Validar campos
    setState(() {
      _nombreError = ValidationService.validateName(_nombreController.text);
      _telefonoError = ValidationService.validatePhone(
        _telefonoController.text,
      );
      _emailError = ValidationService.validateEmail(_emailController.text);
      _passwordError = ValidationService.validatePassword(
        _passwordController.text,
      );
    });

    if (_nombreError != null ||
        _telefonoError != null ||
        _emailError != null ||
        _passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final registrationData = UserRegistrationData(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty
            ? null
            : _telefonoController.text.trim(),
        profilePhoto: _profilePhoto,
        idDocument: _idDocument,
      );

      await _authService.signUp(registrationData);

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppConstants.successRegistration),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // Volver a la pantalla de login
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      final errorMessage = ErrorHandler.getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF263238)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              const Text(
                'Crear Cuenta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),

              const SizedBox(height: 32),

              // Foto de perfil
              Center(
                child: ProfilePhotoPicker(
                  imageFile: _profilePhoto,
                  onImageSelected: (file) {
                    setState(() => _profilePhoto = file);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Campo de nombre
              CustomTextField(
                controller: _nombreController,
                hintText: 'Nombre',
                prefixIcon: Icons.person_outline,
                errorText: _nombreError,
                onChanged: (_) {
                  if (_nombreError != null) {
                    setState(() => _nombreError = null);
                  }
                },
              ),

              const SizedBox(height: 16),

              // Campo de teléfono
              CustomTextField(
                controller: _telefonoController,
                hintText: 'Teléfono',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                errorText: _telefonoError,
                onChanged: (_) {
                  if (_telefonoError != null) {
                    setState(() => _telefonoError = null);
                  }
                },
              ),

              const SizedBox(height: 16),

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

              const SizedBox(height: 24),

              // Botón de subir cédula
              OutlinedButton.icon(
                onPressed: _pickIdDocument,
                icon: Icon(
                  _idDocument != null ? Icons.check_circle : Icons.upload_file,
                  color: _idDocument != null
                      ? Colors.green
                      : const Color(0xFF4DB6AC),
                ),
                label: Text(
                  _idDocument != null ? 'Cédula cargada' : 'Subir Cédula',
                  style: TextStyle(
                    color: _idDocument != null
                        ? Colors.green
                        : const Color(0xFF4DB6AC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                    color: _idDocument != null
                        ? Colors.green
                        : const Color(0xFF4DB6AC),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botón de registro
              CustomButton(
                text: 'CREAR CUENTA',
                onPressed: _handleRegister,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
