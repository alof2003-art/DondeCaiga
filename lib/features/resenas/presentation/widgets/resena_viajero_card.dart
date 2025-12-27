import 'package:flutter/material.dart';
import '../../data/models/resena_viajero.dart';
import '../../../perfil/presentation/widgets/boton_ver_perfil.dart';

class ResenaViajeroCard extends StatelessWidget {
  final ResenaViajero resena;
  final bool mostrarViajero;

  const ResenaViajeroCard({
    super.key,
    required this.resena,
    this.mostrarViajero = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: isDark ? Colors.grey[850] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con información del usuario
            Row(
              children: [
                // Avatar clickeable
                BotonVerPerfil.icono(
                  userId: mostrarViajero
                      ? resena.viajeroId
                      : resena.anfitrionId,
                  nombreUsuario: mostrarViajero
                      ? resena.nombreViajero
                      : resena.nombreAnfitrion,
                  fotoUsuario: mostrarViajero
                      ? resena.fotoViajero
                      : resena.fotoAnfitrion,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre clickeable
                      BotonVerPerfil.texto(
                        userId: mostrarViajero
                            ? resena.viajeroId
                            : resena.anfitrionId,
                        nombreUsuario: mostrarViajero
                            ? resena.nombreViajero
                            : resena.nombreAnfitrion,
                      ),
                      Text(
                        'Propiedad: ${resena.tituloPropiedad}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          resena.calificacionMostrar.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatearFecha(resena.fechaCreacion),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Aspectos específicos si existen
            if (resena.aspectos != null && resena.aspectos!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aspectos evaluados:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...resena.aspectos!.entries
                        .where((entry) => entry.value != null)
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  resena.aspectosLegibles[entry.key] ??
                                      entry.key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    5,
                                    (index) => Icon(
                                      Icons.star,
                                      size: 12,
                                      color: index < entry.value!
                                          ? Colors.amber
                                          : (isDark
                                                ? Colors.grey[600]
                                                : Colors.grey[300]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],

            // Comentario si existe
            if (resena.comentario != null && resena.comentario!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                resena.comentario!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays > 30) {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    } else if (diferencia.inDays > 0) {
      return 'hace ${diferencia.inDays} día${diferencia.inDays > 1 ? 's' : ''}';
    } else if (diferencia.inHours > 0) {
      return 'hace ${diferencia.inHours} hora${diferencia.inHours > 1 ? 's' : ''}';
    } else {
      return 'hace unos minutos';
    }
  }
}
