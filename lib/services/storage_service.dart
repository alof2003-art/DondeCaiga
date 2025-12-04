import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  final SupabaseClient _supabase;

  StorageService(this._supabase);

  /// Sube una foto de perfil al storage de Supabase
  /// Retorna la URL pública del archivo subido
  Future<String> uploadProfilePhoto(File image, String userId) async {
    print('📸 [STORAGE] Iniciando subida de foto de perfil...');

    // Validar tamaño del archivo
    final fileSize = await image.length();
    print('📏 [STORAGE] Tamaño del archivo: ${fileSize / 1024} KB');

    if (fileSize > AppConstants.maxProfilePhotoSize) {
      throw Exception(AppConstants.errorFileTooLarge);
    }

    // Generar nombre único para el archivo
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = image.path.split('.').last;
    final fileName = '$userId/profile_$timestamp.$extension';
    print('📝 [STORAGE] Nombre del archivo: $fileName');

    // Subir archivo
    print(
      '⬆️ [STORAGE] Subiendo a bucket: ${AppConstants.profilePhotosBucket}',
    );
    await _supabase.storage
        .from(AppConstants.profilePhotosBucket)
        .upload(fileName, image);
    print('✅ [STORAGE] Archivo subido exitosamente');

    // Obtener URL pública
    final url = _supabase.storage
        .from(AppConstants.profilePhotosBucket)
        .getPublicUrl(fileName);
    print('🔗 [STORAGE] URL pública generada: $url');

    return url;
  }

  /// Sube un documento de identidad al storage de Supabase
  /// Retorna la URL pública del archivo subido
  Future<String> uploadIdDocument(File image, String userId) async {
    // Validar tamaño del archivo
    final fileSize = await image.length();
    if (fileSize > AppConstants.maxIdDocumentSize) {
      throw Exception(AppConstants.errorFileTooLarge);
    }

    // Generar nombre único para el archivo
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = image.path.split('.').last;
    final fileName = '$userId/id_document_$timestamp.$extension';

    // Subir archivo
    await _supabase.storage
        .from(AppConstants.idDocumentsBucket)
        .upload(fileName, image);

    // Obtener URL pública
    final url = _supabase.storage
        .from(AppConstants.idDocumentsBucket)
        .getPublicUrl(fileName);

    return url;
  }

  /// Elimina un archivo del storage
  Future<void> deleteFile(String bucket, String path) async {
    await _supabase.storage.from(bucket).remove([path]);
  }

  /// Elimina la foto de perfil de un usuario
  Future<void> deleteProfilePhoto(String userId, String photoUrl) async {
    // Extraer el path del archivo de la URL
    final uri = Uri.parse(photoUrl);
    final path = uri.pathSegments.last;
    await deleteFile(AppConstants.profilePhotosBucket, '$userId/$path');
  }

  /// Elimina el documento de identidad de un usuario
  Future<void> deleteIdDocument(String userId, String documentUrl) async {
    // Extraer el path del archivo de la URL
    final uri = Uri.parse(documentUrl);
    final path = uri.pathSegments.last;
    await deleteFile(AppConstants.idDocumentsBucket, '$userId/$path');
  }

  /// Sube una foto de solicitud de anfitrión al storage
  /// Retorna la URL pública del archivo subido
  Future<String> uploadSolicitudPhoto(
    File image,
    String userId,
    String tipo,
  ) async {
    // tipo puede ser 'selfie' o 'propiedad'
    final fileSize = await image.length();
    if (fileSize > AppConstants.maxProfilePhotoSize) {
      throw Exception(AppConstants.errorFileTooLarge);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = image.path.split('.').last;
    final fileName = '$userId/${tipo}_$timestamp.$extension';

    await _supabase.storage
        .from('solicitudes-anfitrion')
        .upload(fileName, image);

    final url = _supabase.storage
        .from('solicitudes-anfitrion')
        .getPublicUrl(fileName);

    return url;
  }

  /// Sube una foto de propiedad al storage
  /// Retorna la URL pública del archivo subido
  Future<String> uploadPropiedadPhoto(File image, String propiedadId) async {
    final fileSize = await image.length();
    if (fileSize > AppConstants.maxProfilePhotoSize) {
      throw Exception(AppConstants.errorFileTooLarge);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = image.path.split('.').last;
    final fileName = '$propiedadId/foto_$timestamp.$extension';

    await _supabase.storage.from('propiedades-fotos').upload(fileName, image);

    final url = _supabase.storage
        .from('propiedades-fotos')
        .getPublicUrl(fileName);

    return url;
  }

  /// Lista todos los archivos de un usuario en un bucket
  Future<List<FileObject>> listUserFiles(String bucket, String userId) async {
    final files = await _supabase.storage.from(bucket).list(path: userId);
    return files;
  }
}
