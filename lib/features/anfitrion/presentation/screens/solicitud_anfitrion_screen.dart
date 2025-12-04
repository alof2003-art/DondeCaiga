import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../main.dart';
import '../../../../services/storage_service.dart';
import '../../data/repositories/solicitud_repository.dart';

class SolicitudAnfitrionScreen extends StatefulWidget {
  const SolicitudAnfitrionScreen({super.key});

  @override
  State<SolicitudAnfitrionScreen> createState() =>
      _SolicitudAnfitrionScreenState();
}

class _SolicitudAnfitrionScreenState extends State<SolicitudAnfitrionScreen> {
  final _mensajeController = TextEditingController();
  File? _fotoSelfie;
  File? _fotoPropiedad;
  bool _isLoading = false;

  late final StorageService _storageService;
  late final SolicitudRepository _solicitudRepository;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService(supabase);
    _solicitudRepository = SolicitudRepository(supabase);
  }

  @override
  void dispose() {
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String tipo) async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        if (tipo == 'selfie') {
          _fotoSelfie = File(pickedFile.path);
        } else {
          _fotoPropiedad = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _enviarSolicitud() async {
    // Validar que se hayan subido ambas fotos
    if (_fotoSelfie == null || _fotoPropiedad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes subir ambas fotos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // 1. Subir foto selfie
      final fotoSelfieUrl = await _storageService.uploadSolicitudPhoto(
        _fotoSelfie!,
        user.id,
        'selfie',
      );

      // 2. Subir foto propiedad
      final fotoPropiedadUrl = await _storageService.uploadSolicitudPhoto(
        _fotoPropiedad!,
        user.id,
        'propiedad',
      );

      // 3. Crear solicitud en la BD
      await _solicitudRepository.crearSolicitud(
        usuarioId: user.id,
        fotoSelfieUrl: fotoSelfieUrl,
        fotoPropiedadUrl: fotoPropiedadUrl,
        mensaje: _mensajeController.text.trim().isEmpty
            ? null
            : _mensajeController.text.trim(),
      );

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Solicitud enviada! Espera la aprobación del admin'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Volver a la pantalla anterior
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar ser Anfitrión'),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instrucciones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Requisitos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Una foto tuya (selfie)\n'
                    '• Una foto del establecimiento que ofrecerás\n'
                    '• Un mensaje opcional explicando por qué quieres ser anfitrión',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Foto Selfie
            Text(
              '1. Tu foto (Selfie)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _pickImage('selfie'),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
                ),
                child: _fotoSelfie != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_fotoSelfie!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'Toca para subir tu foto',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 32),

            // Foto Propiedad
            Text(
              '2. Foto del establecimiento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _pickImage('propiedad'),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4DB6AC), width: 2),
                ),
                child: _fotoPropiedad != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_fotoPropiedad!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_work,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toca para subir foto del lugar',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 32),

            // Mensaje opcional
            Text(
              '3. Mensaje (Opcional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mensajeController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '¿Por qué quieres ser anfitrión?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4DB6AC),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Botón enviar
            ElevatedButton(
              onPressed: _isLoading ? null : _enviarSolicitud,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DB6AC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Enviar Solicitud',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
