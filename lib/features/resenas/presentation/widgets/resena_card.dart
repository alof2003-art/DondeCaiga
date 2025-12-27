import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/resena.dart';
import '../../../perfil/presentation/widgets/boton_ver_perfil.dart';

class ResenaCard extends StatelessWidget {
  final Resena resena;
  final bool esRecibida; // true si es una reseña recibida, false si es hecha

  const ResenaCard({super.key, required this.resena, required this.esRecibida});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con usuario y fecha
              Row(
                children: [
                  // Avatar clickeable - mostrar la persona correcta según el contexto
                  BotonVerPerfil.icono(
                    userId: esRecibida ? resena.viajeroId : resena.anfitrionId,
                    nombreUsuario: esRecibida
                        ? resena.nombreViajero
                        : (resena.nombreAnfitrion ?? 'Anfitrión'),
                    fotoUsuario: esRecibida
                        ? resena.fotoViajero
                        : resena.fotoAnfitrion,
                  ),

                  const SizedBox(width: 12),

                  // Información del usuario
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre clickeable - usar ID correcto según el contexto
                        BotonVerPerfil.texto(
                          userId: esRecibida
                              ? resena.viajeroId
                              : resena.anfitrionId,
                          nombreUsuario: esRecibida
                              ? resena.nombreViajero
                              : (resena.nombreAnfitrion ?? 'Anfitrión'),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd/MM/yyyy').format(resena.fechaCreacion),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: 0.7)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Calificación
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getColorCalificacion(resena.calificacion),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          resena.calificacion.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Propiedad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2)
                      : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  resena.tituloPropiedad,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Comentario (si existe)
              if (resena.comentario != null &&
                  resena.comentario!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  resena.comentario!,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode
                        ? Theme.of(context).colorScheme.onSurface
                        : const Color(0xFF424242),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorCalificacion(double calificacion) {
    final calificacionRedondeada = calificacion.round();
    switch (calificacionRedondeada) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
