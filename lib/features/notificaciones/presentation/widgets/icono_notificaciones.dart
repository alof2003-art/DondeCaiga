import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notificaciones_provider.dart';
import '../screens/notificaciones_screen.dart';

class IconoNotificaciones extends StatelessWidget {
  final double? size;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const IconoNotificaciones({super.key, this.size, this.color, this.padding});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificacionesProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: padding ?? const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificacionesScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.notifications_outlined,
                  size: size ?? 24,
                  color: color ?? Theme.of(context).iconTheme.color,
                ),
                tooltip: 'Notificaciones',
              ),

              // Badge con contador de notificaciones no leídas
              if (provider.hayNotificacionesNoLeidas)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      provider.contadorNoLeidas > 99
                          ? '99+'
                          : provider.contadorNoLeidas.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Widget alternativo más compacto para usar en AppBars
class IconoNotificacionesCompacto extends StatelessWidget {
  const IconoNotificacionesCompacto({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificacionesProvider>(
      builder: (context, provider, child) {
        return Badge(
          isLabelVisible: provider.hayNotificacionesNoLeidas,
          label: Text(
            provider.contadorNoLeidas > 99
                ? '99+'
                : provider.contadorNoLeidas.toString(),
          ),
          backgroundColor: Colors.red,
          textColor: Colors.white,
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificacionesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificaciones',
          ),
        );
      },
    );
  }
}
