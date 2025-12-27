import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/resena_viajero.dart';
import '../../data/repositories/resenas_repository.dart';
import '../../../../core/theme/app_theme.dart';

class CrearResenaViajeroScreen extends StatefulWidget {
  final String reservaId;
  final String viajeroId;
  final String nombreViajero;
  final String? fotoViajero;
  final String tituloPropiedad;

  const CrearResenaViajeroScreen({
    super.key,
    required this.reservaId,
    required this.viajeroId,
    required this.nombreViajero,
    this.fotoViajero,
    required this.tituloPropiedad,
  });

  @override
  State<CrearResenaViajeroScreen> createState() =>
      _CrearResenaViajeroScreenState();
}

class _CrearResenaViajeroScreenState extends State<CrearResenaViajeroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _comentarioController = TextEditingController();
  final _resenasRepository = ResenasRepository(Supabase.instance.client);

  double _calificacionGeneral = 5.0;
  final Map<String, int> _aspectos = {
    'limpieza': 5,
    'comunicacion': 5,
    'respeto_normas': 5,
    'cuidado_propiedad': 5,
    'puntualidad': 5,
  };

  bool _isLoading = false;

  final Map<String, String> _aspectosLegibles = {
    'limpieza': 'Limpieza',
    'comunicacion': 'Comunicación',
    'respeto_normas': 'Respeto a las normas',
    'cuidado_propiedad': 'Cuidado de la propiedad',
    'puntualidad': 'Puntualidad',
  };

  @override
  void initState() {
    super.initState();
    _calcularCalificacionGeneral();
  }

  void _calcularCalificacionGeneral() {
    final valores = _aspectos.values.toList();
    final suma = valores.reduce((a, b) => a + b);
    final promedio = suma / valores.length;

    setState(() {
      // Mantener el promedio exacto con decimales
      _calificacionGeneral = promedio.clamp(1.0, 5.0);
    });
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviarResena() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado');
      }

      final resena = ResenaViajero(
        id: '',
        reservaId: widget.reservaId,
        viajeroId: widget.viajeroId,
        anfitrionId: currentUser.id,
        calificacion: _calificacionGeneral,
        comentario: _comentarioController.text.trim().isEmpty
            ? null
            : _comentarioController.text.trim(),
        aspectos: _aspectos,
        fechaCreacion: DateTime.now(),
        nombreViajero: widget.nombreViajero,
        fotoViajero: widget.fotoViajero,
        nombreAnfitrion: '',
        fotoAnfitrion: null,
        tituloPropiedad: widget.tituloPropiedad,
      );

      final success = await _resenasRepository.crearResenaViajero(resena);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reseña enviada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('Error al enviar la reseña');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar la reseña: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Reseñar Viajero'),
        backgroundColor: isDark
            ? AppTheme.primaryDarkColor
            : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del viajero
              Card(
                color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: isDark
                            ? Colors.grey[700]
                            : Colors.grey[300],
                        backgroundImage: widget.fotoViajero != null
                            ? NetworkImage(widget.fotoViajero!)
                            : null,
                        child: widget.fotoViajero == null
                            ? Icon(
                                Icons.person,
                                size: 30,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.nombreViajero,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Propiedad: ${widget.tituloPropiedad}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Calificación general
              Text(
                'Calificación general (calculada automáticamente)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Promedio de los aspectos evaluados',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: index < _calificacionGeneral.floor()
                          ? Colors.amber
                          : (index < _calificacionGeneral
                                ? Colors.amber.withValues(alpha: 0.5)
                                : (isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[300])),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '${_calificacionGeneral.toStringAsFixed(1)} estrellas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Aspectos específicos
              Text(
                'Aspectos específicos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              ..._aspectos.keys.map(
                (aspecto) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _aspectosLegibles[aspecto] ?? aspecto,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _aspectos[aspecto] = index + 1;
                              });
                              _calcularCalificacionGeneral();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: Icon(
                                Icons.star,
                                size: 28,
                                color: index < _aspectos[aspecto]!
                                    ? Colors.amber
                                    : (isDark
                                          ? Colors.grey[600]
                                          : Colors.grey[300]),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Comentario
              Text(
                'Comentario (opcional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _comentarioController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Comparte tu experiencia con este viajero...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppTheme.primaryDarkColor
                          : AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                ),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),

              const SizedBox(height: 32),

              // Botón enviar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enviarResena,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppTheme.primaryDarkColor
                        : AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Enviar Reseña',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
