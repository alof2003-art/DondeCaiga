import 'package:flutter/material.dart';

class RatingVisualWidget extends StatelessWidget {
  final double promedio;
  final int totalResenas;
  final Map<String, dynamic> distribucion;
  final Color colorTema;
  final String tipo; // 'anfitrion' o 'viajero'

  const RatingVisualWidget({
    super.key,
    required this.promedio,
    required this.totalResenas,
    required this.distribucion,
    required this.colorTema,
    required this.tipo,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (totalResenas == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorTema.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorTema.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              tipo == 'anfitrion' ? Icons.home : Icons.luggage,
              color: colorTema,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'Sin reseñas aún',
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorTema.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorTema.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header con icono y tipo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tipo == 'anfitrion' ? Icons.home : Icons.luggage,
                color: colorTema,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                tipo == 'anfitrion' ? 'Como Anfitrión' : 'Como Viajero',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorTema,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Rating principal
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                promedio.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Colors.amber, size: 24),
            ],
          ),

          const SizedBox(height: 4),

          // Total de reseñas
          Text(
            '$totalResenas reseña${totalResenas != 1 ? 's' : ''}',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[600],
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 16),

          // Distribución de estrellas (estilo Play Store)
          _buildDistribucionEstrellas(context),
        ],
      ),
    );
  }

  Widget _buildDistribucionEstrellas(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        for (int i = 5; i >= 1; i--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                // Número de estrella
                Text(
                  '$i',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),

                // Estrella
                Icon(Icons.star, size: 14, color: Colors.amber[600]),

                const SizedBox(width: 8),

                // Barra de progreso
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _getPorcentajeEstrella(i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorTema,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Cantidad
                SizedBox(
                  width: 20,
                  child: Text(
                    '${_getCantidadEstrella(i)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  double _getPorcentajeEstrella(int estrella) {
    if (totalResenas == 0) return 0.0;
    final cantidad = _getCantidadEstrella(estrella);
    return cantidad / totalResenas;
  }

  int _getCantidadEstrella(int estrella) {
    try {
      // Manejo robusto de diferentes tipos de datos
      if (distribucion.isEmpty) return 0;

      // Intentar con clave como string
      final claveString = estrella.toString();
      if (distribucion.containsKey(claveString)) {
        final valor = distribucion[claveString];
        return _convertirAInt(valor);
      }

      // Intentar con clave como int
      if (distribucion.containsKey(claveString)) {
        final valor = distribucion[claveString];
        return _convertirAInt(valor);
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  int _convertirAInt(dynamic valor) {
    if (valor == null) return 0;
    if (valor is int) return valor;
    if (valor is double) return valor.toInt();
    if (valor is String) return int.tryParse(valor) ?? 0;
    return 0;
  }
}
