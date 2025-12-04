import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../main.dart';
import '../../../../services/storage_service.dart';
import '../../data/repositories/propiedad_repository.dart';
import '../../data/models/propiedad.dart';

class EditarPropiedadScreen extends StatefulWidget {
  final Propiedad propiedad;

  const EditarPropiedadScreen({super.key, required this.propiedad});

  @override
  State<EditarPropiedadScreen> createState() => _EditarPropiedadScreenState();
}

class _EditarPropiedadScreenState extends State<EditarPropiedadScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _direccionController;
  late final TextEditingController _ciudadController;
  late final TextEditingController _paisController;

  File? _nuevaFoto;
  late int _capacidadPersonas;
  late int _numeroHabitaciones;
  late int _numeroBanos;
  late bool _tieneGaraje;
  bool _isLoading = false;

  late final StorageService _storageService;
  late final PropiedadRepository _propiedadRepository;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService(supabase);
    _propiedadRepository = PropiedadRepository(supabase);

    // Inicializar con los valores actuales
    _tituloController = TextEditingController(text: widget.propiedad.titulo);
    _descripcionController = TextEditingController(
      text: widget.propiedad.descripcion ?? '',
    );
    _direccionController = TextEditingController(
      text: widget.propiedad.direccion,
    );
    _ciudadController = TextEditingController(
      text: widget.propiedad.ciudad ?? '',
    );
    _paisController = TextEditingController(text: widget.propiedad.pais ?? '');
    _capacidadPersonas = widget.propiedad.capacidadPersonas;
    _numeroHabitaciones = widget.propiedad.numeroHabitaciones ?? 1;
    _numeroBanos = widget.propiedad.numeroBanos ?? 1;
    _tieneGaraje = widget.propiedad.tieneGaraje;
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
        _nuevaFoto = File(pickedFile.path);
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? nuevaFotoUrl;

      // Si hay una nueva foto, subirla
      if (_nuevaFoto != null) {
        nuevaFotoUrl = await _storageService.uploadPropiedadPhoto(
          _nuevaFoto!,
          widget.propiedad.id,
        );
      }

      // Actualizar la propiedad
      await _propiedadRepository.actualizarPropiedad(widget.propiedad.id, {
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'ciudad': _ciudadController.text.trim().isEmpty
            ? null
            : _ciudadController.text.trim(),
        'pais': _paisController.text.trim().isEmpty
            ? null
            : _paisController.text.trim(),
        'capacidad_personas': _capacidadPersonas,
        'numero_habitaciones': _numeroHabitaciones,
        'numero_banos': _numeroBanos,
        'tiene_garaje': _tieneGaraje,
        if (nuevaFotoUrl != null) 'foto_principal_url': nuevaFotoUrl,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Alojamiento actualizado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
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
        title: const Text('Editar Alojamiento'),
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
                  child: _nuevaFoto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_nuevaFoto!, fit: BoxFit.cover),
                        )
                      : widget.propiedad.fotoPrincipalUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.propiedad.fotoPrincipalUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 60,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Toca para cambiar foto',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              );
                            },
                          ),
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

              // Botón guardar
              ElevatedButton(
                onPressed: _isLoading ? null : _guardarCambios,
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
                        'Guardar Cambios',
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
