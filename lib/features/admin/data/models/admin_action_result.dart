class AdminActionResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String? errorCode;

  AdminActionResult({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
  });

  // Factory methods para crear resultados específicos
  factory AdminActionResult.success({
    required String message,
    Map<String, dynamic>? data,
  }) {
    return AdminActionResult(
      success: true,
      message: message,
      data: data,
      errorCode: null,
    );
  }

  factory AdminActionResult.failure({
    required String message,
    String? errorCode,
    Map<String, dynamic>? data,
  }) {
    return AdminActionResult(
      success: false,
      message: message,
      data: data,
      errorCode: errorCode,
    );
  }

  // Factory methods para errores específicos
  factory AdminActionResult.permissionDenied() {
    return AdminActionResult.failure(
      message: "No tienes permisos para realizar esta acción",
      errorCode: "PERMISSION_DENIED",
    );
  }

  factory AdminActionResult.userNotFound() {
    return AdminActionResult.failure(
      message: "El usuario seleccionado no existe o fue eliminado",
      errorCode: "USER_NOT_FOUND",
    );
  }

  factory AdminActionResult.networkError() {
    return AdminActionResult.failure(
      message: "Error de conexión. Verifica tu internet e intenta nuevamente",
      errorCode: "NETWORK_ERROR",
    );
  }

  factory AdminActionResult.adminTargetError() {
    return AdminActionResult.failure(
      message: "No tienes permisos para gestionar esta cuenta",
      errorCode: "ADMIN_TARGET_ERROR",
    );
  }

  factory AdminActionResult.selfManagementError() {
    return AdminActionResult.failure(
      message: "No puedes gestionar tu propia cuenta",
      errorCode: "SELF_MANAGEMENT_ERROR",
    );
  }

  factory AdminActionResult.viajeroPromotionError() {
    return AdminActionResult.failure(
      message:
          "Los viajeros deben usar el proceso de verificación normal para ser anfitriones",
      errorCode: "VIAJERO_PROMOTION_DENIED",
    );
  }

  factory AdminActionResult.userAlreadyBlocked() {
    return AdminActionResult.failure(
      message: "El usuario ya está bloqueado",
      errorCode: "USER_ALREADY_BLOCKED",
    );
  }

  factory AdminActionResult.userAlreadyActive() {
    return AdminActionResult.failure(
      message: "El usuario ya está activo",
      errorCode: "USER_ALREADY_ACTIVE",
    );
  }

  factory AdminActionResult.userAlreadyViajero() {
    return AdminActionResult.failure(
      message: "El usuario ya es viajero",
      errorCode: "USER_ALREADY_VIAJERO",
    );
  }

  factory AdminActionResult.missingReason() {
    return AdminActionResult.failure(
      message: "Debes proporcionar un motivo para esta acción",
      errorCode: "MISSING_REASON",
    );
  }

  factory AdminActionResult.unknownError([String? details]) {
    return AdminActionResult.failure(
      message: details != null
          ? "Ocurrió un error inesperado: $details"
          : "Ocurrió un error inesperado. Intenta nuevamente",
      errorCode: "UNKNOWN_ERROR",
    );
  }

  // Getters para facilitar el uso
  bool get isSuccess => success;
  bool get isFailure => !success;
  bool get hasErrorCode => errorCode != null;
  bool get hasData => data != null && data!.isNotEmpty;

  // Método para obtener datos específicos
  T? getData<T>(String key) {
    if (data == null) return null;
    return data![key] as T?;
  }

  @override
  String toString() {
    return 'AdminActionResult(success: $success, message: $message, errorCode: $errorCode)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminActionResult &&
        other.success == success &&
        other.message == message &&
        other.errorCode == errorCode;
  }

  @override
  int get hashCode {
    return success.hashCode ^ message.hashCode ^ errorCode.hashCode;
  }
}
