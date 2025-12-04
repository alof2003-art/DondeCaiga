import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../../main.dart';
import '../../../../services/storage_service.dart';
import '../../data/repositories/propiedad_repository.dart';
import 'location_picker_screen.dart';

class CrearPropiedadScreen extends StatefulWidget {
  const CrearPropiedadScreen({super.key});

  @override
  State<CrearPropiedadScreen> createState() => _CrearPropiedadScreenState();
}

class _CrearPropiedadScreenState extends State<CrearPropiedadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _paisController = TextEditingController();
  int _capacidadPersonas = 1;
  int _numeroHabitaciones = 1;
  int _numeroBanos = 1;

  File? _fotoPrincipal;
  bool _isLoading = false;
  bool _tieneGaraje = false;

  // Ubicación en el mapa
  double? _latitud;
  double? _longitud;

  late final StorageService _storageService;
  late final PropiedadRepository _propiedadRepository;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService(supabase);
    _propiedadRepository = PropiedadRepository(supabase);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _paisController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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
        _fotoPrincipal = File(pickedFile.path);
      });
    }
  }

  Future<void> _abrirMapa() async {
    final LatLng? ubicacionInicial = _latitud != null && _longitud != null
        ? LatLng(_latitud!, _longitud!)
        : null;

    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) =>
            LocationPickerScreen(initialLocation: ubicacionInicial),
      ),
    );

    if (result != null) {
      setState(() {
        _latitud = result.latitude;
        _longitud = result.longitude;
      });
    }
  }

  Future<void> _crearPropiedad() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fotoPrincipal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes subir una foto del alojamiento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // 1. Crear la propiedad primero (sin foto)
      final propiedadId = await _propiedadRepository.crearPropiedad(
        anfitrionId: user.id,
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        direccion: _direccionController.text.trim(),
        ciudad: _ciudadController.text.trim().isEmpty
            ? null
            : _ciudadController.text.trim(),
        pais: _paisController.text.trim().isEmpty
            ? null
            : _paisController.text.trim(),
        capacidadPersonas: _capacidadPersonas,
        numeroHabitaciones: _numeroHabitaciones,
        numeroBanos: _numeroBanos,
        tieneGaraje: _tieneGaraje,
        latitud: _latitud,
        longitud: _longitud,
      );

      // 2. Subir foto
      final fotoUrl = await _storageService.uploadPropiedadPhoto(
        _fotoPrincipal!,
        propiedadId,
      );

      // 3. Actualizar propiedad con la URL de la foto
      await _propiedadRepository.actualizarPropiedad(propiedadId, {
        'foto_principal_url': fotoUrl,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Alojamiento creado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
        title: const Text('Crear Alojamiento'),
        backgroundColor: const Color(0xFF4DB6AC),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Foto principal
              Text(
                'Foto Principal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4DB6AC),
                      width: 2,
                    ),
                  ),
                  child: _fotoPrincipal != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_fotoPrincipal!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toca para subir foto',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Título
              TextFormField(
                controller: _tituloController,
                decoration: InputDecoration(
                  labelText: 'Título del alojamiento *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Dirección
              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                  labelText: 'Dirección completa *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La dirección es obligatoria';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Botón para seleccionar ubicación en el mapa
              OutlinedButton.icon(
                onPressed: _abrirMapa,
                icon: const Icon(Icons.map),
                label: Text(
                  _latitud != null && _longitud != null
                      ? 'Ubicación seleccionada en el mapa'
                      : 'Seleccionar ubicación en el mapa (opcional)',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4DB6AC),
                  side: const BorderSide(color: Color(0xFF4DB6AC)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              if (_latitud != null && _longitud != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF4DB6AC),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${_latitud!.toStringAsFixed(6)}, Lng: ${_longitud!.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Ciudad y País
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ciudadController,
                      decoration: InputDecoration(
                        labelText: 'Ciudad',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _paisController,
                      decoration: InputDecoration(
                        labelText: 'País',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Capacidad de personas
              DropdownButtonFormField<int>(
                initialValue: _capacidadPersonas,
                decoration: InputDecoration(
                  labelText: 'Capacidad de personas *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: List.generate(25, (index) => index + 1)
                    .map(
                      (numero) => DropdownMenuItem(
                        value: numero,
                        child: Text(
                          '$numero ${numero == 1 ? 'persona' : 'personas'}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _capacidadPersonas = value ?? 1;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Habitaciones y Baños
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _numeroHabitaciones,
                      decoration: InputDecoration(
                        labelText: 'Habitaciones',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: List.generate(10, (index) => index + 1)
                          .map(
                            (numero) => DropdownMenuItem(
                              value: numero,
                              child: Text('$numero'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _numeroHabitaciones = value ?? 1;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _numeroBanos,
                      decoration: InputDecoration(
                        labelText: 'Baños',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: List.generate(5, (index) => index + 1)
                          .map(
                            (numero) => DropdownMenuItem(
                              value: numero,
                              child: Text('$numero'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _numeroBanos = value ?? 1;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Garaje
              CheckboxListTile(
                title: const Text('¿Tiene garaje?'),
                value: _tieneGaraje,
                onChanged: (value) {
                  setState(() {
                    _tieneGaraje = value ?? false;
                  });
                },
                activeColor: const Color(0xFF4DB6AC),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 32),

              // Botón crear
              ElevatedButton(
                onPressed: _isLoading ? null : _crearPropiedad,
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
                        'Crear Alojamiento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
