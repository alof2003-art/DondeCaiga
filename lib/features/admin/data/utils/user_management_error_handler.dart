import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_action_result.dart';

class UserManagementErrorHandler {
  /// Maneja errores específicos de gestión de usuarios
  static AdminActionResult handleError(dynamic error) {
    // Manejar errores de Supabase
    if (error is AuthException) {
      return _handleAuthError(error);
    }

    if (error is PostgrestException) {
      return _handlePostgrestError(error);
    }

    // Manejar errores de red/conectividad
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('Connection') ||
        error.toString().contains('Network')) {
      return AdminActionResult.networkError();
    }

    // Manejar errores específicos de la aplicación
    if (error is AdminPermissionError) {
      return AdminActionResult.permissionDenied();
    }

    if (error is UserNotFoundError) {
      return AdminActionResult.userNotFound();
    }

    if (error is AdminTargetError) {
      return AdminActionResult.adminTargetError();
    }

    if (error is SelfManagementError) {
      return AdminActionResult.selfManagementError();
    }

    if (error is ViajeroPromotionError) {
      return AdminActionResult.viajeroPromotionError();
    }

    if (error is UserAlreadyBlockedError) {
      return AdminActionResult.userAlreadyBlocked();
    }

    if (error is UserAlreadyActiveError) {
      return AdminActionResult.userAlreadyActive();
    }

    if (error is UserAlreadyViajeroError) {
      return AdminActionResult.userAlreadyViajero();
    }

    if (error is MissingReasonError) {
      return AdminActionResult.missingReason();
    }

    // Error genérico
    return AdminActionResult.unknownError(error.toString());
  }

  /// Maneja errores de autenticación de Supabase
  static AdminActionResult _handleAuthError(AuthException error) {
    switch (error.statusCode) {
      case '401':
        return AdminActionResult.failure(
          message: 'No tienes permisos para realizar esta acción',
          errorCode: 'UNAUTHORIZED',
        );
      case '403':
        return AdminActionResult.failure(
          message: 'Acceso denegado',
          errorCode: 'FORBIDDEN',
        );
      case '422':
        return AdminActionResult.failure(
          message: 'Datos inválidos proporcionados',
          errorCode: 'INVALID_DATA',
        );
      default:
        return AdminActionResult.failure(
          message: 'Error de autenticación: ${error.message}',
          errorCode: 'AUTH_ERROR',
        );
    }
  }

  /// Maneja errores de base de datos de Supabase
  static AdminActionResult _handlePostgrestError(PostgrestException error) {
    // Errores específicos de RLS (Row Level Security)
    if (error.message.contains('RLS') || error.message.contains('policy')) {
      return AdminActionResult.failure(
        message: 'No tienes permisos para realizar esta acción',
        errorCode: 'RLS_VIOLATION',
      );
    }

    // Errores de clave foránea
    if (error.message.contains('foreign key') ||
        error.message.contains('violates')) {
      return AdminActionResult.failure(
        message:
            'No se puede completar la acción debido a dependencias de datos',
        errorCode: 'FOREIGN_KEY_VIOLATION',
      );
    }

    // Errores de duplicado
    if (error.message.contains('duplicate') ||
        error.message.contains('unique')) {
      return AdminActionResult.failure(
        message: 'Ya existe un registro con estos datos',
        errorCode: 'DUPLICATE_ENTRY',
      );
    }

    // Errores de no encontrado
    if (error.message.contains('not found') || error.code == 'PGRST116') {
      return AdminActionResult.userNotFound();
    }

    // Error genérico de base de datos
    return AdminActionResult.failure(
      message: 'Error en la base de datos: ${error.message}',
      errorCode: 'DATABASE_ERROR',
    );
  }

  /// Valida si un error es recuperable
  static bool isRecoverableError(dynamic error) {
    if (error is AdminActionResult) {
      return error.errorCode == 'NETWORK_ERROR' ||
          error.errorCode == 'TIMEOUT_ERROR' ||
          error.errorCode == 'DATABASE_ERROR';
    }

    return error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('Connection');
  }

  /// Obtiene un mensaje amigable para el usuario
  static String getFriendlyMessage(AdminActionResult result) {
    if (result.isSuccess) {
      return result.message;
    }

    switch (result.errorCode) {
      case 'NETWORK_ERROR':
        return 'Problema de conexión. Verifica tu internet e intenta nuevamente.';
      case 'PERMISSION_DENIED':
      case 'UNAUTHORIZED':
      case 'FORBIDDEN':
      case 'RLS_VIOLATION':
        return 'No tienes permisos para realizar esta acción.';
      case 'USER_NOT_FOUND':
        return 'El usuario seleccionado no existe o fue eliminado.';
      case 'ADMIN_TARGET_ERROR':
        return 'No puedes gestionar cuentas de otros administradores.';
      case 'SELF_MANAGEMENT_ERROR':
        return 'No puedes gestionar tu propia cuenta.';
      case 'VIAJERO_PROMOTION_DENIED':
        return 'Los viajeros deben usar el proceso de verificación normal.';
      case 'USER_ALREADY_BLOCKED':
        return 'El usuario ya está bloqueado.';
      case 'USER_ALREADY_ACTIVE':
        return 'El usuario ya está activo.';
      case 'USER_ALREADY_VIAJERO':
        return 'El usuario ya es viajero.';
      case 'MISSING_REASON':
        return 'Debes proporcionar un motivo para esta acción.';
      case 'INVALID_DATA':
        return 'Los datos proporcionados no son válidos.';
      case 'DUPLICATE_ENTRY':
        return 'Ya existe un registro con estos datos.';
      case 'FOREIGN_KEY_VIOLATION':
        return 'No se puede completar debido a dependencias de datos.';
      case 'DATABASE_ERROR':
        return 'Error en la base de datos. Intenta nuevamente.';
      default:
        return result.message.isNotEmpty
            ? result.message
            : 'Ocurrió un error inesperado. Intenta nuevamente.';
    }
  }

  /// Determina el color apropiado para mostrar el mensaje
  static Color getMessageColor(AdminActionResult result) {
    if (result.isSuccess) {
      return const Color(0xFF4CAF50); // Verde
    }

    switch (result.errorCode) {
      case 'NETWORK_ERROR':
      case 'DATABASE_ERROR':
        return const Color(0xFFFF9800); // Naranja
      case 'PERMISSION_DENIED':
      case 'UNAUTHORIZED':
      case 'FORBIDDEN':
      case 'RLS_VIOLATION':
      case 'ADMIN_TARGET_ERROR':
      case 'SELF_MANAGEMENT_ERROR':
        return const Color(0xFFF44336); // Rojo
      case 'USER_ALREADY_BLOCKED':
      case 'USER_ALREADY_ACTIVE':
      case 'USER_ALREADY_VIAJERO':
      case 'VIAJERO_PROMOTION_DENIED':
        return const Color(0xFFFF9800); // Naranja
      default:
        return const Color(0xFFF44336); // Rojo por defecto
    }
  }

  /// Determina el icono apropiado para mostrar el mensaje
  static IconData getMessageIcon(AdminActionResult result) {
    if (result.isSuccess) {
      return Icons.check_circle;
    }

    switch (result.errorCode) {
      case 'NETWORK_ERROR':
        return Icons.wifi_off;
      case 'PERMISSION_DENIED':
      case 'UNAUTHORIZED':
      case 'FORBIDDEN':
      case 'RLS_VIOLATION':
        return Icons.lock;
      case 'USER_NOT_FOUND':
        return Icons.person_off;
      case 'ADMIN_TARGET_ERROR':
      case 'SELF_MANAGEMENT_ERROR':
        return Icons.admin_panel_settings_outlined;
      case 'MISSING_REASON':
        return Icons.edit_note;
      case 'DATABASE_ERROR':
        return Icons.storage;
      default:
        return Icons.error;
    }
  }
}

// Excepciones personalizadas para la aplicación
class AdminPermissionError extends Error {}

class UserNotFoundError extends Error {}

class AdminTargetError extends Error {}

class SelfManagementError extends Error {}

class ViajeroPromotionError extends Error {}

class UserAlreadyBlockedError extends Error {}

class UserAlreadyActiveError extends Error {}

class UserAlreadyViajeroError extends Error {}

class MissingReasonError extends Error {}
