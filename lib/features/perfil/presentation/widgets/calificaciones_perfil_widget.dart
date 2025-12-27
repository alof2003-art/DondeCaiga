import 'package:flutter/material.dart';

class CalificacionesPerfilWidget extends StatelessWidget {
  final double? promedioAnfitrion;
  final int? totalResenasAnfitrion;
  final double? promedioViajero;
  final int? totalResenasViajero;
  final bool esCompacto;

  const CalificacionesPerfilWidget({
    super.key,
    this.promedioAnfitrion,
    this.totalResenasAnfitrion,
    this.promedioViajero,
    this.totalResenasViajero,
    this.esCompacto = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Si no hay calificaciones, no mostrar nada
    final hayAnfitrion = (totalResenasAnfitrion ?? 0) > 0;
    final hayViajero = (totalResenasViajero ?? 0) > 0;

    // Debug: Imprimir valores para verificar
    print('=== DEBUG CALIFICACIONES WIDGET ===');
    print(
      'Anfitrión: promedio=$promedioAnfitrion, total=$totalResenasAnfitrion, hay=$hayAnfitrion',
    );
    print(
      'Viajero: promedio=$promedioViajero, total=$totalResenasViajero, hay=$hayViajero',
    );

    if (!hayAnfitrion && !hayViajero) {
      print('No hay calificaciones, ocultando widget');
      return const SizedBox.shrink();
    }

    print('Mostrando widget de calificaciones');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey[800]?.withValues(alpha: 0.5)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.grey[600]!.withValues(alpha: 0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Calificación como anfitrión
          if (hayAnfitrion) ...[
            _buildCalificacionItem(
              context,
              Icons.home,
              promedioAnfitrion ?? 0.0,
              totalResenasAnfitrion ?? 0,
              Colors.green,
              'Anfitrión',
            ),
            if (hayViajero) ...[
              Container(
                height: 20,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ],
          ],

          // Calificación como viajero
          if (hayViajero)
            _buildCalificacionItem(
              context,
              Icons.luggage,
              promedioViajero ?? 0.0,
              totalResenasViajero ?? 0,
              Colors.blue,
              'Viajero',
            ),
        ],
      ),
    );
  }

  Widget _buildCalificacionItem(
    BuildContext context,
    IconData icono,
    double promedio,
    int total,
    Color color,
    String tipo,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 4),
        Icon(Icons.star, size: 14, color: Colors.amber[600]),
        const SizedBox(width: 2),
        Text(
          promedio.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '($total)',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
