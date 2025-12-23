import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

/// Botón toggle para cambiar entre modo claro y oscuro
class ThemeToggleButton extends StatelessWidget {
  final double size;
  final bool showLabel;

  const ThemeToggleButton({
    super.key,
    this.size = 24.0,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200), // Reducido de 300ms
          curve: Curves.easeInOut, // Curva más suave
          decoration: BoxDecoration(
            color: themeService.isDarkMode
                ? Colors.grey.shade800
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: themeService.toggleTheme,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Simplificamos la animación - solo cambio de ícono sin rotación
                    Icon(
                      themeService.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      size: size,
                      color: themeService.isDarkMode
                          ? Colors.yellow.shade300
                          : Colors.orange.shade600,
                    ),
                    if (showLabel) ...[
                      const SizedBox(width: 8),
                      Text(
                        themeService.isDarkMode ? 'Oscuro' : 'Claro',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Botón flotante para el toggle de tema - Optimizado
class FloatingThemeToggle extends StatelessWidget {
  const FloatingThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Positioned(
          top: 16,
          right: 16,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: themeService.isDarkMode
                  ? Colors.grey.shade800
                  : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: themeService.toggleTheme,
                child: Center(
                  child: Icon(
                    themeService.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    size: 28,
                    color: themeService.isDarkMode
                        ? Colors.yellow.shade300
                        : Colors.orange.shade600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
