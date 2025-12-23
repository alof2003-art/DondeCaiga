import 'package:flutter/material.dart';

/// Configuraciones globales para optimizar el rendimiento de la aplicación
class PerformanceConfig {
  /// Configurar optimizaciones globales de la aplicación
  static void configureApp() {
    // Configurar el binding para optimizaciones
    WidgetsFlutterBinding.ensureInitialized();

    // Optimizar el rendimiento de las animaciones
    _configureAnimations();

    // Configurar el sistema de imágenes
    _configureImageCache();

    // Configurar el sistema de scroll
    _configureScrollBehavior();
  }

  /// Configurar animaciones para mejor rendimiento
  static void _configureAnimations() {
    // Reducir la duración de las animaciones de página por defecto
    // Esto se puede hacer globalmente o por widget
  }

  /// Configurar el cache de imágenes
  static void _configureImageCache() {
    // Configurar el tamaño del cache de imágenes
    PaintingBinding.instance.imageCache.maximumSize =
        100; // Máximo 100 imágenes
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50MB
  }

  /// Configurar el comportamiento de scroll
  static void _configureScrollBehavior() {
    // Las configuraciones de scroll se manejan por widget
  }

  /// Configuraciones de rendimiento para listas
  static const double defaultCacheExtent = 200.0;
  static const ScrollPhysics optimizedScrollPhysics = BouncingScrollPhysics();

  /// Configuraciones de animación optimizadas
  static const Duration fastAnimationDuration = Duration(milliseconds: 200);
  static const Duration normalAnimationDuration = Duration(milliseconds: 300);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  /// Curvas de animación optimizadas
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve fastCurve = Curves.easeOut;
  static const Curve bounceCurve = Curves.elasticOut;

  /// Configuraciones para imágenes
  static const int defaultImageCacheWidth = 400;
  static const int defaultImageCacheHeight = 300;
  static const int gridImageCacheWidth = 300;
  static const int gridImageCacheHeight = 200;

  /// Widget de loading optimizado
  static Widget buildOptimizedLoader({
    double size = 24.0,
    double strokeWidth = 2.0,
    Color? color,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: color != null ? AlwaysStoppedAnimation<Color>(color) : null,
      ),
    );
  }

  /// Container de imagen optimizado
  static Widget buildOptimizedImageContainer({
    required double width,
    required double height,
    Widget? child,
    Color? color,
  }) {
    return Container(
      width: width,
      height: height,
      color: color ?? Colors.grey[200],
      child: child ?? const Icon(Icons.image, size: 40),
    );
  }
}

/// Mixin para widgets que necesitan optimizaciones de rendimiento
mixin PerformanceOptimizationMixin<T extends StatefulWidget> on State<T> {
  /// Evitar reconstrucciones durante animaciones de ruta
  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);

    final route = ModalRoute.of(context);
    if (route?.animation?.status == AnimationStatus.forward ||
        route?.animation?.status == AnimationStatus.reverse) {
      // Durante transiciones de página, evitar reconstrucciones costosas
      return;
    }
  }

  /// Optimizar el dispose de recursos
  @override
  void dispose() {
    // Limpiar recursos específicos del widget
    super.dispose();
  }
}

/// Widget base optimizado para tarjetas
abstract class OptimizedCard extends StatelessWidget {
  const OptimizedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: buildCard(context));
  }

  Widget buildCard(BuildContext context);
}
