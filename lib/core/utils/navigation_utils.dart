import 'package:flutter/material.dart';

/// Utilidades para navegación optimizada
class NavigationUtils {
  /// Transición de página optimizada para mejor rendimiento
  static Route<T> createOptimizedRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Usar SlideTransition que es más eficiente que otras animaciones
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  /// Navegación push optimizada
  static Future<T?> pushOptimized<T extends Object?>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    return Navigator.of(
      context,
    ).push<T>(createOptimizedRoute<T>(page, duration: duration, curve: curve));
  }

  /// Navegación push replacement optimizada
  static Future<T?>
  pushReplacementOptimized<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
    TO? result,
  }) {
    return Navigator.of(context).pushReplacement<T, TO>(
      createOptimizedRoute<T>(page, duration: duration, curve: curve),
      result: result,
    );
  }

  /// Navegación push and remove until optimizada
  static Future<T?> pushAndRemoveUntilOptimized<T extends Object?>(
    BuildContext context,
    Widget page,
    RoutePredicate predicate, {
    Duration duration = const Duration(milliseconds: 250),
    Curve curve = Curves.easeInOut,
  }) {
    return Navigator.of(context).pushAndRemoveUntil<T>(
      createOptimizedRoute<T>(page, duration: duration, curve: curve),
      predicate,
    );
  }
}

/// Widget optimizado para Hero animations
class OptimizedHero extends StatelessWidget {
  final String tag;
  final Widget child;
  final Duration transitionDuration;

  const OptimizedHero({
    super.key,
    required this.tag,
    required this.child,
    this.transitionDuration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true, // Mejora las transiciones con gestos
      child: child,
    );
  }
}

/// Mixin para optimizar el rendimiento de widgets con animaciones
mixin AnimationOptimizationMixin<T extends StatefulWidget> on State<T> {
  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Evitar reconstrucciones innecesarias durante animaciones
    if (ModalRoute.of(context)?.animation?.status == AnimationStatus.forward ||
        ModalRoute.of(context)?.animation?.status == AnimationStatus.reverse) {
      return;
    }
  }
}
