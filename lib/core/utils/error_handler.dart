import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class ErrorHandler {
  /// Obtiene un mensaje de error amigable para el usuario
  static String getErrorMessage(dynamic error) {
    if (error is AuthException) {
      return _handleAuthError(error);
    } else if (error is StorageException) {
      return _handleStorageError(error);
    } else if (error is SocketException) {
      return AppConstants.errorNoInternet;
    } else if (error is PostgrestException) {
      return _handlePostgrestError(error);
    } else {
      return AppConstants.errorUnexpected;
    }
  }

  /// Maneja errores de autenticación de Supabase
  static String _handleAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    // Email ya existe
    if (message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('duplicate')) {
      return AppConstants.errorEmailExists;
    }

    // Credenciales inválidas
    if (message.contains('invalid') ||
        message.contains('incorrect') ||
        message.contains('wrong')) {
      return AppConstants.errorInvalidCredentials;
    }

    // Email no verificado
    if (message.contains('email not confirmed') ||
        message.contains('not verified')) {
      return AppConstants.errorEmailNotVerified;
    }

    // Error de red
    if (message.contains('network') || message.contains('connection')) {
      return AppConstants.errorConnection;
    }

    // Error genérico de autenticación
    return 'Error de autenticación: ${error.message}';
  }

  /// Maneja errores de storage de Supabase
  static String _handleStorageError(StorageException error) {
    final message = error.message.toLowerCase();

    // Archivo muy grande
    if (message.contains('size') ||
        message.contains('too large') ||
        message.contains('exceeded')) {
      return AppConstants.errorFileTooLarge;
    }

    // Tipo de archivo inválido
    if (message.contains('type') ||
        message.contains('format') ||
        message.contains('invalid')) {
      return AppConstants.errorInvalidFileType;
    }

    // Error genérico de subida
    return AppConstants.errorUploadFailed;
  }

  /// Maneja errores de base de datos (Postgrest)
  static String _handlePostgrestError(PostgrestException error) {
    final message = error.message.toLowerCase();

    // Violación de constraint único (email duplicado)
    if (message.contains('unique') || message.contains('duplicate')) {
      return AppConstants.errorEmailExists;
    }

    // Error de permisos
    if (message.contains('permission') ||
        message.contains('denied') ||
        message.contains('unauthorized')) {
      return 'No tienes permisos para realizar esta acción';
    }

    // Error genérico de base de datos
    return 'Error al procesar la solicitud. Intenta nuevamente';
  }

  /// Registra el error en consola para debugging
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    print('❌ Error: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
}
