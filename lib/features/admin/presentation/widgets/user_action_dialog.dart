import 'package:flutter/material.dart';
import '../../../auth/data/models/user_profile.dart';

enum UserActionType { degradeRole, blockAccount, unblockAccount }

class UserActionDialog extends StatefulWidget {
  final UserProfile user;
  final UserActionType actionType;
  final VoidCallback? onCancel;
  final Function(String? reason)? onConfirm;

  const UserActionDialog({
    super.key,
    required this.user,
    required this.actionType,
    this.onCancel,
    this.onConfirm,
  });

  @override
  State<UserActionDialog> createState() => _UserActionDialogState();
}

class _UserActionDialogState extends State<UserActionDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.actionType) {
      case UserActionType.degradeRole:
        return 'Degradar Anfitrión';
      case UserActionType.blockAccount:
        return 'Bloquear Cuenta';
      case UserActionType.unblockAccount:
        return 'Desbloquear Cuenta';
    }
  }

  String get _message {
    switch (widget.actionType) {
      case UserActionType.degradeRole:
        return '¿Estás seguro de degradar a ${widget.user.nombre} de Anfitrión a Viajero? Deberá solicitar verificación nuevamente.';
      case UserActionType.blockAccount:
        return '¿Estás seguro de bloquear la cuenta de ${widget.user.nombre}? El usuario no podrá acceder a la aplicación.';
      case UserActionType.unblockAccount:
        return '¿Estás seguro de desbloquear la cuenta de ${widget.user.nombre}? El usuario podrá acceder nuevamente.';
    }
  }

  bool get _requiresReason {
    return widget.actionType == UserActionType.degradeRole ||
        widget.actionType == UserActionType.blockAccount;
  }

  Color get _actionColor {
    switch (widget.actionType) {
      case UserActionType.degradeRole:
        return Colors.orange;
      case UserActionType.blockAccount:
        return Colors.red;
      case UserActionType.unblockAccount:
        return Colors.green;
    }
  }

  IconData get _actionIcon {
    switch (widget.actionType) {
      case UserActionType.degradeRole:
        return Icons.arrow_downward;
      case UserActionType.blockAccount:
        return Icons.block;
      case UserActionType.unblockAccount:
        return Icons.check_circle;
    }
  }

  void _handleConfirm() {
    setState(() {
      _errorMessage = null;
    });

    // Validar razón si es requerida
    if (_requiresReason && _reasonController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Debes proporcionar un motivo para esta acción';
      });
      return;
    }

    // Validar longitud mínima de la razón
    if (_requiresReason && _reasonController.text.trim().length < 10) {
      setState(() {
        _errorMessage = 'El motivo debe tener al menos 10 caracteres';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Llamar callback con la razón (o null si no es requerida)
    final reason = _requiresReason ? _reasonController.text.trim() : null;
    widget.onConfirm?.call(reason);
  }

  void _handleCancel() {
    if (_isLoading) return; // No permitir cancelar durante carga
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_actionIcon, color: _actionColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _title,
              style: TextStyle(
                color: _actionColor,
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
            // Información del usuario
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _actionColor.withValues(alpha: 0.2),
                    backgroundImage: widget.user.fotoPerfilUrl != null
                        ? NetworkImage(widget.user.fotoPerfilUrl!)
                        : null,
                    child: widget.user.fotoPerfilUrl == null
                        ? Icon(Icons.person, color: _actionColor)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.user.email,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.user.esViajero ? 'Viajero' : 'Anfitrión',
                          style: TextStyle(
                            color: _actionColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Mensaje de confirmación
            Text(_message, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 16),

            // Campo de razón (si es requerido)
            if (_requiresReason) ...[
              Text(
                'Motivo *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'Describe el motivo de esta acción...',
                  border: const OutlineInputBorder(),
                  errorText: _errorMessage,
                  helperText: 'Mínimo 10 caracteres',
                ),
                onChanged: (value) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            // Advertencia adicional para acciones críticas
            if (widget.actionType == UserActionType.blockAccount) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta acción cancelará todas las reservas pendientes del usuario y desactivará sus propiedades.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (widget.actionType == UserActionType.degradeRole) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se creará automáticamente una nueva solicitud de anfitrión para que pueda re-verificarse.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Botón Cancelar
        TextButton(
          onPressed: _isLoading ? null : _handleCancel,
          child: const Text('Cancelar'),
        ),

        // Botón Confirmar
        ElevatedButton(
          onPressed: _isLoading ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: _actionColor,
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
              : const Text('Confirmar'),
        ),
      ],
    );
  }
}
