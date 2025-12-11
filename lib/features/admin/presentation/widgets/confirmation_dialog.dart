import 'package:flutter/material.dart';

class ConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Widget? customContent;
  final bool showLoadingOnConfirm;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
    this.confirmColor,
    this.icon,
    this.onConfirm,
    this.onCancel,
    this.customContent,
    this.showLoadingOnConfirm = false,
  });

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  bool _isLoading = false;

  void _handleConfirm() {
    if (widget.showLoadingOnConfirm) {
      setState(() {
        _isLoading = true;
      });
    }
    widget.onConfirm?.call();
  }

  void _handleCancel() {
    if (_isLoading) return; // No permitir cancelar durante carga
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmColor = widget.confirmColor ?? theme.primaryColor;

    return AlertDialog(
      title: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: confirmColor, size: 28),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                color: confirmColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message, style: const TextStyle(fontSize: 16)),
            if (widget.customContent != null) ...[
              const SizedBox(height: 16),
              widget.customContent!,
            ],
          ],
        ),
      ),
      actions: [
        // Botón Cancelar
        TextButton(
          onPressed: _isLoading ? null : _handleCancel,
          child: Text(widget.cancelText),
        ),

        // Botón Confirmar
        ElevatedButton(
          onPressed: _isLoading ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(widget.confirmText),
        ),
      ],
    );
  }

  // Métodos estáticos para crear diálogos comunes
  // TODO: Métodos de utilidad para futuros usos
  /*
  static Future<bool?> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Aceptar',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: '',
        confirmColor: Colors.green,
        icon: Icons.check_circle,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  static Future<bool?> showError({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Aceptar',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: '',
        confirmColor: Colors.red,
        icon: Icons.error,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  static Future<bool?> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Continuar',
    String cancelText = 'Cancelar',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: Colors.orange,
        icon: Icons.warning,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  static Future<bool?> showDelete({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Eliminar',
    String cancelText = 'Cancelar',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: Colors.red,
        icon: Icons.delete,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  static Future<bool?> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Entendido',
    Widget? customContent,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: '',
        confirmColor: Colors.blue,
        icon: Icons.info,
        customContent: customContent,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }

  static Future<bool?> showCustom({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color? confirmColor,
    IconData? icon,
    Widget? customContent,
    bool showLoadingOnConfirm = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
        customContent: customContent,
        showLoadingOnConfirm: showLoadingOnConfirm,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }
  */
}
