class SolicitudAnfitrion {
  final String id;
  final String usuarioId;
  final String fotoSelfieUrl;
  final String fotoPropiedadUrl;
  final String? mensaje;
  final String estado; // pendiente, aprobada, rechazada
  final DateTime fechaSolicitud;
  final DateTime? fechaRespuesta;
  final String? adminRevisorId;
  final String? comentarioAdmin;

  // Datos adicionales del usuario (para mostrar en la lista)
  final String? nombreUsuario;
  final String? emailUsuario;

  SolicitudAnfitrion({
    required this.id,
    required this.usuarioId,
    required this.fotoSelfieUrl,
    required this.fotoPropiedadUrl,
    this.mensaje,
    required this.estado,
    required this.fechaSolicitud,
    this.fechaRespuesta,
    this.adminRevisorId,
    this.comentarioAdmin,
    this.nombreUsuario,
    this.emailUsuario,
  });

  factory SolicitudAnfitrion.fromJson(Map<String, dynamic> json) {
    return SolicitudAnfitrion(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      fotoSelfieUrl: json['foto_selfie_url'] as String,
      fotoPropiedadUrl: json['foto_propiedad_url'] as String,
      mensaje: json['mensaje'] as String?,
      estado: json['estado'] as String,
      fechaSolicitud: DateTime.parse(json['fecha_solicitud'] as String),
      fechaRespuesta: json['fecha_respuesta'] != null
          ? DateTime.parse(json['fecha_respuesta'] as String)
          : null,
      adminRevisorId: json['admin_revisor_id'] as String?,
      comentarioAdmin: json['comentario_admin'] as String?,
      nombreUsuario: json['nombre_usuario'] as String?,
      emailUsuario: json['email_usuario'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'foto_selfie_url': fotoSelfieUrl,
      'foto_propiedad_url': fotoPropiedadUrl,
      'mensaje': mensaje,
      'estado': estado,
      'fecha_solicitud': fechaSolicitud.toIso8601String(),
      'fecha_respuesta': fechaRespuesta?.toIso8601String(),
      'admin_revisor_id': adminRevisorId,
      'comentario_admin': comentarioAdmin,
    };
  }
}
