class AppConstants {
  // Duración del splash screen
  static const int splashDurationSeconds = 2;

  // Validación
  static const int minPasswordLength = 6;

  // Storage buckets
  static const String profilePhotosBucket = 'profile-photos';
  static const String idDocumentsBucket = 'id-documents';

  // Tamaños máximos de archivo (en bytes)
  static const int maxProfilePhotoSize = 5 * 1024 * 1024; // 5MB
  static const int maxIdDocumentSize = 10 * 1024 * 1024; // 10MB

  // Mensajes de error
  static const String errorNoInternet = 'Sin conexión a internet';
  static const String errorConnection =
      'Error de conexión. Verifica tu internet e intenta nuevamente';
  static const String errorUnexpected =
      'Ocurrió un error inesperado. Intenta nuevamente';
  static const String errorInvalidCredentials =
      'Email o contraseña incorrectos';
  static const String errorEmailExists = 'Este email ya está registrado';
  static const String errorEmailNotVerified =
      'Por favor verifica tu email antes de iniciar sesión';
  static const String errorInvalidEmail = 'Ingrese un email válido';
  static const String errorPasswordTooShort =
      'La contraseña debe tener al menos 6 caracteres';
  static const String errorFileTooLarge =
      'La imagen es demasiado grande (máx 5MB para fotos, 10MB para documentos)';
  static const String errorInvalidFileType = 'Formato de archivo no válido';
  static const String errorUploadFailed =
      'Error al subir la imagen. Intenta nuevamente';

  // Mensajes de éxito
  static const String successRegistration =
      'Cuenta creada exitosamente. Por favor verifica tu email.';
}
