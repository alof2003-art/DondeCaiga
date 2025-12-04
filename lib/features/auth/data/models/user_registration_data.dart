import 'dart:io';

class UserRegistrationData {
  final String email;
  final String password;
  final String nombre;
  final String? telefono;
  final File? profilePhoto;
  final File? idDocument;

  UserRegistrationData({
    required this.email,
    required this.password,
    required this.nombre,
    this.telefono,
    this.profilePhoto,
    this.idDocument,
  });

  @override
  String toString() {
    return 'UserRegistrationData(email: $email, nombre: $nombre, telefono: $telefono, hasProfilePhoto: ${profilePhoto != null}, hasIdDocument: ${idDocument != null})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserRegistrationData &&
        other.email == email &&
        other.password == password &&
        other.nombre == nombre &&
        other.telefono == telefono &&
        other.profilePhoto?.path == profilePhoto?.path &&
        other.idDocument?.path == idDocument?.path;
  }

  @override
  int get hashCode {
    return email.hashCode ^
        password.hashCode ^
        nombre.hashCode ^
        telefono.hashCode ^
        profilePhoto.hashCode ^
        idDocument.hashCode;
  }
}
