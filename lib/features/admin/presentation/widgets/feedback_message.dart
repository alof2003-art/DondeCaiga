import 'package:flutter/material.dart';
import '../../data/models/admin_action_result.dart';
import '../../data/utils/user_management_error_handler.dart';

class FeedbackMessage {
  /// Muestra un SnackBar con el resultado de una acción administrativa
  static void show(
    BuildContext context,
    AdminActionResult result, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final message = UserManagementErrorHandler.getFriendlyMessage(result);
    final color = UserManagementErrorHandler.getMessageColor(result);
    final icon = UserManagementErrorHandler.getMessageIcon(result);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: action,
      ),
    );
  }

  /// Muestra un mensaje de éxito
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context,
      AdminActionResult.success(message: message),
      duration: duration,
      action: action,
    );
  }

  /// Muestra un mensaje de error
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
    SnackBarAction? action,
  }) {
    show(
      context,
      AdminActionResult.failure(message: message),
      duration: duration,
      action: action,
    );
  }

  /// Muestra un mensaje de advertencia
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF9800), // Naranja
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: action,
      ),
    );
  }

  /// Muestra un mensaje informativo
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2196F3), // Azul
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: action,
      ),
    );
  }

  /// Muestra un diálogo de resultado detallado
  static Future<void> showDetailedResult(
    BuildContext context,
    AdminActionResult result, {
    String? title,
    Widget? additionalContent,
  }) async {
    final isSuccess = result.isSuccess;
    final message = UserManagementErrorHandler.getFriendlyMessage(result);
    final color = UserManagementErrorHandler.getMessageColor(result);
    final icon = UserManagementErrorHandler.getMessageIcon(result);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title ?? (isSuccess ? 'Éxito' : 'Error'),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 16)),
            if (result.hasData &&
                result.getData<String>('user_name') != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usuario afectado:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.getData<String>('user_name') ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
            if (additionalContent != null) ...[
              const SizedBox(height: 16),
              additionalContent,
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  /// Muestra un indicador de carga con mensaje
  static void showLoading(
    BuildContext context,
    String message, {
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  /// Oculta el diálogo de carga actual
  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Muestra un mensaje con opción de reintentar
  static void showWithRetry(
    BuildContext context,
    AdminActionResult result,
    VoidCallback onRetry, {
    Duration duration = const Duration(seconds: 6),
  }) {
    if (UserManagementErrorHandler.isRecoverableError(result)) {
      show(
        context,
        result,
        duration: duration,
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      );
    } else {
      show(context, result, duration: duration);
    }
  }
}
