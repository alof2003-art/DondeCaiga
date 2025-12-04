import '../core/constants/app_constants.dart';

class ValidationService {
  /// Valida el formato de un email
  /// Retorna null si es válido, o un mensaje de error si es inválido
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'El email es requerido';
    }

    // Regex para validar email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return AppConstants.errorInvalidEmail;
    }

    return null;
  }

  /// Valida la contraseña
  /// Retorna null si es válida, o un mensaje de error si es inválida
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (password.length < AppConstants.minPasswordLength) {
      return AppConstants.errorPasswordTooShort;
    }

    return null;
  }

  /// Valida el nombre
  /// Retorna null si es válido, o un mensaje de error si es inválido
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'El nombre es requerido';
    }

    if (name.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }

    return null;
  }

  /// Valida el teléfono (opcional)
  /// Retorna null si es válido o vacío, o un mensaje de error si es inválido
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null; // El teléfono es opcional
    }

    // Remover espacios y guiones
    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');

    // Validar que solo contenga números y tenga entre 7 y 15 dígitos
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');

    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Ingrese un número de teléfono válido';
    }

    return null;
  }

  /// Valida que dos contraseñas coincidan
  static String? validatePasswordMatch(
    String? password,
    String? confirmPassword,
  ) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirme su contraseña';
    }

    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }
}
