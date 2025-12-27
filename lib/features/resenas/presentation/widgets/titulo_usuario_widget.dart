import 'package:flutter/material.dart';

class TituloUsuarioWidget extends StatefulWidget {
  final double promedioAnfitrion;
  final int totalResenasAnfitrion;
  final double promedioViajero;
  final int totalResenasViajero;

  const TituloUsuarioWidget({
    super.key,
    required this.promedioAnfitrion,
    required this.totalResenasAnfitrion,
    required this.promedioViajero,
    required this.totalResenasViajero,
  });

  @override
  State<TituloUsuarioWidget> createState() => _TituloUsuarioWidgetState();
}

class _TituloUsuarioWidgetState extends State<TituloUsuarioWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _colorAnimation = ColorTween(begin: Colors.grey, end: Colors.amber).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Iniciar animación después de un pequeño delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tituloAnfitrion = _obtenerTituloAnfitrion();
    final tituloViajero = _obtenerTituloViajero();

    // Si no hay títulos, no mostrar nada
    if (tituloAnfitrion == null && tituloViajero == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  if (tituloAnfitrion != null)
                    _buildTituloCard(
                      tituloAnfitrion,
                      Icons.home,
                      Colors.green,
                      'anfitrion',
                    ),
                  if (tituloAnfitrion != null && tituloViajero != null)
                    const SizedBox(height: 8),
                  if (tituloViajero != null)
                    _buildTituloCard(
                      tituloViajero,
                      Icons.luggage,
                      Colors.blue,
                      'viajero',
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTituloCard(
    Map<String, dynamic> titulo,
    IconData icono,
    Color colorBase,
    String tipo,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nivel = titulo['nivel'] as String;
    final nombre = titulo['nombre'] as String;
    final descripcion = titulo['descripcion'] as String;

    // Colores según el nivel
    Color colorMarco;
    Color colorFondo;
    Color colorTexto;
    List<Color> gradientColors;

    switch (nivel) {
      case 'oro':
        colorMarco = const Color(0xFFFFD700); // Dorado
        colorFondo = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFFFFDF5);
        colorTexto = isDark ? Colors.white : const Color(0xFF8B4513);
        gradientColors = [
          const Color(0xFFFFD700),
          const Color(0xFFFFA500),
          const Color(0xFFFFD700),
        ];
        break;
      case 'plata':
        colorMarco = const Color(0xFFC0C0C0); // Plateado
        colorFondo = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F8FF);
        colorTexto = isDark ? Colors.white : const Color(0xFF4A4A4A);
        gradientColors = [
          const Color(0xFFC0C0C0),
          const Color(0xFFE6E6FA),
          const Color(0xFFC0C0C0),
        ];
        break;
      case 'bronce':
        colorMarco = const Color(0xFFCD7F32); // Bronce
        colorFondo = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFFFF8DC);
        colorTexto = isDark ? Colors.white : const Color(0xFF8B4513);
        gradientColors = [
          const Color(0xFFCD7F32),
          const Color(0xFFDEB887),
          const Color(0xFFCD7F32),
        ];
        break;
      default:
        colorMarco = colorBase;
        colorFondo = isDark ? const Color(0xFF2D2D2D) : Colors.white;
        colorTexto = isDark ? Colors.white : Colors.black87;
        gradientColors = [
          colorBase,
          colorBase.withValues(alpha: 0.7),
          colorBase,
        ];
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorMarco.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3), // Grosor del marco
      child: Container(
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icono con animación de brillo
            AnimatedBuilder(
              animation: _colorAnimation,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _colorAnimation.value?.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icono, color: colorMarco, size: 24),
                );
              },
            ),

            const SizedBox(width: 12),

            // Información del título
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del título con efecto brillante
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: gradientColors,
                    ).createShader(bounds),
                    child: Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Necesario para ShaderMask
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Descripción
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorTexto.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Medalla o corona según el nivel
            _buildMedalla(nivel),
          ],
        ),
      ),
    );
  }

  Widget _buildMedalla(String nivel) {
    IconData icono;
    Color color;

    switch (nivel) {
      case 'oro':
        icono = Icons.emoji_events;
        color = const Color(0xFFFFD700);
        break;
      case 'plata':
        icono = Icons.military_tech;
        color = const Color(0xFFC0C0C0);
        break;
      case 'bronce':
        icono = Icons.workspace_premium;
        color = const Color(0xFFCD7F32);
        break;
      default:
        icono = Icons.star;
        color = Colors.amber;
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2,
          child: Icon(icono, color: color, size: 28),
        );
      },
    );
  }

  Map<String, dynamic>? _obtenerTituloAnfitrion() {
    if (widget.totalResenasAnfitrion == 0) return null;

    final promedio = widget.promedioAnfitrion;
    final total = widget.totalResenasAnfitrion;

    if (promedio >= 4.8 && total >= 50) {
      return {
        'nivel': 'oro',
        'nombre': 'Anfitrión Legendario',
        'descripcion': 'Excelencia excepcional en hospitalidad',
      };
    } else if (promedio >= 4.7 && total >= 30) {
      return {
        'nivel': 'oro',
        'nombre': 'Anfitrión Excepcional',
        'descripcion': 'Calidad superior garantizada',
      };
    } else if (promedio >= 4.5 && total >= 20) {
      return {
        'nivel': 'plata',
        'nombre': 'Anfitrión Destacado',
        'descripcion': 'Servicio de alta calidad',
      };
    } else if (promedio >= 4.3 && total >= 10) {
      return {
        'nivel': 'plata',
        'nombre': 'Anfitrión Confiable',
        'descripcion': 'Experiencia consistente',
      };
    } else if (promedio >= 4.0 && total >= 5) {
      return {
        'nivel': 'bronce',
        'nombre': 'Anfitrión Prometedor',
        'descripcion': 'En camino a la excelencia',
      };
    }

    return null;
  }

  Map<String, dynamic>? _obtenerTituloViajero() {
    if (widget.totalResenasViajero == 0) return null;

    final promedio = widget.promedioViajero;
    final total = widget.totalResenasViajero;

    if (promedio >= 4.8 && total >= 30) {
      return {
        'nivel': 'oro',
        'nombre': 'Viajero Ejemplar',
        'descripcion': 'Respeto y cortesía excepcionales',
      };
    } else if (promedio >= 4.7 && total >= 20) {
      return {
        'nivel': 'oro',
        'nombre': 'Viajero Distinguido',
        'descripcion': 'Comportamiento impecable',
      };
    } else if (promedio >= 4.5 && total >= 15) {
      return {
        'nivel': 'plata',
        'nombre': 'Viajero Respetuoso',
        'descripcion': 'Huésped de confianza',
      };
    } else if (promedio >= 4.3 && total >= 8) {
      return {
        'nivel': 'plata',
        'nombre': 'Viajero Considerado',
        'descripcion': 'Buen comportamiento',
      };
    } else if (promedio >= 4.0 && total >= 3) {
      return {
        'nivel': 'bronce',
        'nombre': 'Viajero Novato',
        'descripcion': 'Comenzando su reputación',
      };
    }

    return null;
  }
}
