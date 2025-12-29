import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/notificacion.dart';
import '../providers/notificaciones_provider.dart';
import '../../../reservas/presentation/screens/mis_reservas_anfitrion_screen.dart';
import '../../../perfil/presentation/screens/perfil_screen.dart';

class NotificacionCard extends StatelessWidget {
  final Notificacion notificacion;
  final VoidCallback? onTap;

  const NotificacionCard({super.key, required this.notificacion, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: notificacion.leida ? 1 : 3,
      color: notificacion.leida
          ? null
          : (isDark
                ? Colors.blue.shade900.withValues(alpha: 0.3)
                : Colors.blue.shade50),
      child: InkWell(
        onTap: () => _manejarTapNotificacion(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono de la notificación
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getColorTipo(
                    notificacion.tipo,
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconoTipo(notificacion.tipo),
                  color: _getColorTipo(notificacion.tipo),
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Contenido de la notificación
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título y tiempo
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notificacion.titulo,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: notificacion.leida
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _formatearTiempo(notificacion.fechaCreacion),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Mensaje
                    Text(
                      notificacion.mensaje,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.8,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Indicador de no leída
                    if (!notificacion.leida)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Nueva',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Menú de opciones
              PopupMenuButton<String>(
                onSelected: (value) => _manejarAccionMenu(context, value),
                itemBuilder: (context) => [
                  if (!notificacion.leida)
                    const PopupMenuItem(
                      value: 'marcar_leida',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read),
                          SizedBox(width: 8),
                          Text('Marcar como leída'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _manejarTapNotificacion(BuildContext context) {
    // Marcar como leída si no lo está
    if (!notificacion.leida) {
      context.read<NotificacionesProvider>().marcarComoLeida(notificacion.id);
    }

    // Navegar según el tipo de notificación
    switch (notificacion.tipo) {
      case TipoNotificacion.nuevoMensaje:
        // Por ahora mostrar un diálogo hasta que tengamos la navegación correcta
        _mostrarDetalleNotificacion(context);
        break;

      case TipoNotificacion.solicitudReserva:
      case TipoNotificacion.llegadaHuesped:
      case TipoNotificacion.finEstadia:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MisReservasAnfitrionScreen(),
          ),
        );
        break;

      case TipoNotificacion.reservaAceptada:
      case TipoNotificacion.reservaRechazada:
      case TipoNotificacion.recordatorioCheckin:
      case TipoNotificacion.recordatorioCheckout:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MisReservasAnfitrionScreen(),
          ),
        );
        break;

      case TipoNotificacion.nuevaResena:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PerfilScreen()),
        );
        break;

      case TipoNotificacion.anfitrionAceptado:
      case TipoNotificacion.anfitrionRechazado:
        _mostrarDetalleDecisionAnfitrion(context);
        break;

      default:
        // Para otros tipos, mostrar detalle en modal
        _mostrarDetalleNotificacion(context);
    }

    if (onTap != null) {
      onTap!();
    }
  }

  void _manejarAccionMenu(BuildContext context, String accion) {
    final provider = context.read<NotificacionesProvider>();

    switch (accion) {
      case 'marcar_leida':
        provider.marcarComoLeida(notificacion.id);
        break;
      case 'eliminar':
        _confirmarEliminacion(context, provider);
        break;
    }
  }

  void _confirmarEliminacion(
    BuildContext context,
    NotificacionesProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar notificación'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta notificación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              provider.eliminarNotificacion(notificacion.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalleNotificacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getColorTipo(notificacion.tipo).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconoTipo(notificacion.tipo),
                color: _getColorTipo(notificacion.tipo),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(notificacion.titulo)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notificacion.mensaje, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatearFechaCompleta(notificacion.fechaCreacion),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalleDecisionAnfitrion(BuildContext context) {
    final esAceptado = notificacion.tipo == TipoNotificacion.anfitrionAceptado;
    final comentario =
        notificacion.datos?['comentario_admin'] ??
        'Sin comentarios adicionales';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              esAceptado ? Icons.check_circle : Icons.cancel,
              color: esAceptado ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(notificacion.titulo)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notificacion.mensaje, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text(
              'Comentario del administrador:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(comentario),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  IconData _getIconoTipo(TipoNotificacion tipo) {
    switch (tipo) {
      case TipoNotificacion.solicitudReserva:
        return Icons.home;
      case TipoNotificacion.reservaAceptada:
        return Icons.check_circle;
      case TipoNotificacion.reservaRechazada:
        return Icons.cancel;
      case TipoNotificacion.nuevaResena:
        return Icons.star;
      case TipoNotificacion.solicitudAnfitrion:
        return Icons.person_add;
      case TipoNotificacion.anfitrionAceptado:
        return Icons.verified_user;
      case TipoNotificacion.anfitrionRechazado:
        return Icons.person_remove;
      case TipoNotificacion.nuevoMensaje:
        return Icons.message;
      case TipoNotificacion.llegadaHuesped:
        return Icons.login;
      case TipoNotificacion.finEstadia:
        return Icons.logout;
      case TipoNotificacion.recordatorioCheckin:
        return Icons.schedule;
      case TipoNotificacion.recordatorioCheckout:
        return Icons.schedule_send;
      case TipoNotificacion.general:
        return Icons.info;
    }
  }

  Color _getColorTipo(TipoNotificacion tipo) {
    switch (tipo) {
      case TipoNotificacion.solicitudReserva:
        return Colors.blue;
      case TipoNotificacion.reservaAceptada:
      case TipoNotificacion.anfitrionAceptado:
        return Colors.green;
      case TipoNotificacion.reservaRechazada:
      case TipoNotificacion.anfitrionRechazado:
        return Colors.red;
      case TipoNotificacion.nuevaResena:
        return Colors.amber;
      case TipoNotificacion.solicitudAnfitrion:
        return Colors.purple;
      case TipoNotificacion.nuevoMensaje:
        return Colors.teal;
      case TipoNotificacion.llegadaHuesped:
        return Colors.indigo;
      case TipoNotificacion.finEstadia:
        return Colors.orange;
      case TipoNotificacion.recordatorioCheckin:
      case TipoNotificacion.recordatorioCheckout:
        return Colors.brown;
      case TipoNotificacion.general:
        return Colors.grey;
    }
  }

  String _formatearTiempo(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Ahora';
    } else if (diferencia.inHours < 1) {
      return '${diferencia.inMinutes}m';
    } else if (diferencia.inDays < 1) {
      return '${diferencia.inHours}h';
    } else if (diferencia.inDays < 7) {
      return '${diferencia.inDays}d';
    } else {
      return '${fecha.day}/${fecha.month}';
    }
  }
}

String _formatearFechaCompleta(DateTime fecha) {
  final meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  final mes = meses[fecha.month - 1];

  return '${fecha.day} de $mes a las $hora:$minuto';
}
