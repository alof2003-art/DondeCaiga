import 'package:flutter/material.dart';

class TituloCompactoWidget extends StatefulWidget {
  final double promedio;
  final int totalResenas;
  final String tipo; // 'anfitrion' o 'viajero'
  final bool mostrarAnimacion;

  const TituloCompactoWidget({
    super.key,
    required this.promedio,
    required this.totalResenas,
    required this.tipo,
    this.mostrarAnimacion = true,
  });

  @override
  State<TituloCompactoWidget> createState() => _TituloCompactoWidgetState();
}

class _TituloCompactoWidgetState extends State<TituloCompactoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    if (widget.mostrarAnimacion) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _animationController.forward();
        }
      });
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _obtenerTitulo();

    if (titulo == null) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _buildTituloCompacto(titulo),
        );
      },
    );
  }

  Widget _buildTituloCompacto(Map<String, dynamic> titulo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nivel = titulo['nivel'] as String;
    final nombre = titulo['nombre'] as String;

    // Colores según el nivel
    Color colorMarco;
    Color colorFondo;
    Color colorTexto;

    switch (nivel) {
      case 'oro':
        colorMarco = const Color(0xFFFFD700);
        colorFondo = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFFFFDF5);
        colorTexto = isDark ? Colors.white : const Color(0xFF8B4513);
        break;
      case 'plata':
        colorMarco = const Color(0xFFC0C0C0);
        colorFondo = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F8FF);
        colorTexto = isDark ? Colors.white : const Color(0xFF4A4A4A);
        break;
      case 'bronce':
        colorMarco = const Color(0xFFCD7F32);
        colorFondo = isDark ? const Color(0xFF2D2D2D) : const Color(0xFFFFF8DC);
        colorTexto = isDark ? Colors.white : const Color(0xFF8B4513);
        break;
      default:
        colorMarco = widget.tipo == 'anfitrion' ? Colors.green : Colors.blue;
        colorFondo = isDark ? const Color(0xFF2D2D2D) : Colors.white;
        colorTexto = isDark ? Colors.white : Colors.black87;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorMarco, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: colorFondo,
        boxShadow: [
          BoxShadow(
            color: colorMarco.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono de medalla
          Icon(_obtenerIconoMedalla(nivel), color: colorMarco, size: 16),

          const SizedBox(width: 4),

          // Nombre del título
          Text(
            nombre,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorTexto,
            ),
          ),
        ],
      ),
    );
  }

  IconData _obtenerIconoMedalla(String nivel) {
    switch (nivel) {
      case 'oro':
        return Icons.emoji_events;
      case 'plata':
        return Icons.military_tech;
      case 'bronce':
        return Icons.workspace_premium;
      default:
        return Icons.star;
    }
  }

  Map<String, dynamic>? _obtenerTitulo() {
    if (widget.totalResenas == 0) return null;

    final promedio = widget.promedio;
    final total = widget.totalResenas;

    if (widget.tipo == 'anfitrion') {
      if (promedio >= 4.8 && total >= 50) {
        return {'nivel': 'oro', 'nombre': 'Anfitrión Legendario'};
      } else if (promedio >= 4.7 && total >= 30) {
        return {'nivel': 'oro', 'nombre': 'Anfitrión Excepcional'};
      } else if (promedio >= 4.5 && total >= 20) {
        return {'nivel': 'plata', 'nombre': 'Anfitrión Destacado'};
      } else if (promedio >= 4.3 && total >= 10) {
        return {'nivel': 'plata', 'nombre': 'Anfitrión Confiable'};
      } else if (promedio >= 4.0 && total >= 5) {
        return {'nivel': 'bronce', 'nombre': 'Anfitrión Prometedor'};
      }
    } else {
      if (promedio >= 4.8 && total >= 30) {
        return {'nivel': 'oro', 'nombre': 'Viajero Ejemplar'};
      } else if (promedio >= 4.7 && total >= 20) {
        return {'nivel': 'oro', 'nombre': 'Viajero Distinguido'};
      } else if (promedio >= 4.5 && total >= 15) {
        return {'nivel': 'plata', 'nombre': 'Viajero Respetuoso'};
      } else if (promedio >= 4.3 && total >= 8) {
        return {'nivel': 'plata', 'nombre': 'Viajero Considerado'};
      } else if (promedio >= 4.0 && total >= 3) {
        return {'nivel': 'bronce', 'nombre': 'Viajero Novato'};
      }
    }

    return null;
  }
}
