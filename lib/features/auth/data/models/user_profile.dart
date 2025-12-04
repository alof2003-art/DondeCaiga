class UserProfile {
  final String id;
  final String email;
  final String nombre;
  final String? telefono;
  final String? fotoPerfilUrl;
  final String? cedulaUrl;
  final DateTime createdAt;
  final bool emailVerified;
  final int rolId; // 1=viajero, 2=anfitrion, 3=admin
  final String estadoCuenta;

  UserProfile({
    required this.id,
    required this.email,
    required this.nombre,
    this.telefono,
    this.fotoPerfilUrl,
    this.cedulaUrl,
    required this.createdAt,
    required this.emailVerified,
    this.rolId = 1, // Por defecto viajero
    this.estadoCuenta = 'activo',
  });

  // Helpers para verificar roles
  bool get esViajero => rolId == 1;
  bool get esAnfitrion => rolId == 2;
  bool get esAdmin => rolId == 3;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      fotoPerfilUrl: json['foto_perfil_url'] as String?,
      cedulaUrl: json['cedula_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      emailVerified: json['email_verified'] as bool? ?? false,
      rolId: json['rol_id'] as int? ?? 1,
      estadoCuenta: json['estado_cuenta'] as String? ?? 'activo',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'telefono': telefono,
      'foto_perfil_url': fotoPerfilUrl,
      'cedula_url': cedulaUrl,
      'created_at': createdAt.toIso8601String(),
      'email_verified': emailVerified,
      'rol_id': rolId,
      'estado_cuenta': estadoCuenta,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? nombre,
    String? telefono,
    String? fotoPerfilUrl,
    String? cedulaUrl,
    DateTime? createdAt,
    bool? emailVerified,
    int? rolId,
    String? estadoCuenta,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      cedulaUrl: cedulaUrl ?? this.cedulaUrl,
      createdAt: createdAt ?? this.createdAt,
      emailVerified: emailVerified ?? this.emailVerified,
      rolId: rolId ?? this.rolId,
      estadoCuenta: estadoCuenta ?? this.estadoCuenta,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, nombre: $nombre, telefono: $telefono, emailVerified: $emailVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProfile &&
        other.id == id &&
        other.email == email &&
        other.nombre == nombre &&
        other.telefono == telefono &&
        other.fotoPerfilUrl == fotoPerfilUrl &&
        other.cedulaUrl == cedulaUrl &&
        other.createdAt == createdAt &&
        other.emailVerified == emailVerified &&
        other.rolId == rolId &&
        other.estadoCuenta == estadoCuenta;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        nombre.hashCode ^
        telefono.hashCode ^
        fotoPerfilUrl.hashCode ^
        cedulaUrl.hashCode ^
        createdAt.hashCode ^
        emailVerified.hashCode ^
        rolId.hashCode ^
        estadoCuenta.hashCode;
  }
}
