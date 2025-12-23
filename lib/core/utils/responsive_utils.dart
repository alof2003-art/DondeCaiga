import 'package:flutter/material.dart';

class ResponsiveUtils {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Padding responsivo
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  // Espaciado responsivo
  static double getResponsiveSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 16;
    } else if (isTablet(context)) {
      return 24;
    } else {
      return 32;
    }
  }

  // Tamaño de fuente responsivo
  static double getResponsiveFontSize(
    BuildContext context,
    double baseFontSize,
  ) {
    if (isMobile(context)) {
      return baseFontSize;
    } else if (isTablet(context)) {
      return baseFontSize * 1.1;
    } else {
      return baseFontSize * 1.2;
    }
  }

  // Ancho máximo para contenido
  static double getMaxContentWidth(BuildContext context) {
    final screenWidth = getScreenWidth(context);
    if (isMobile(context)) {
      return screenWidth;
    } else if (isTablet(context)) {
      return screenWidth * 0.8;
    } else {
      return 1200; // Máximo para desktop
    }
  }

  // Número de columnas para grids
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  // Aspect ratio para cards
  static double getCardAspectRatio(BuildContext context) {
    if (isMobile(context)) {
      return 1.2;
    } else if (isTablet(context)) {
      return 1.3;
    } else {
      return 1.4;
    }
  }
}

// Widget wrapper para contenido responsivo
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: maxWidth ?? ResponsiveUtils.getMaxContentWidth(context),
        padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
        child: child,
      ),
    );
  }
}

// Widget para texto responsivo
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium!;
    final responsiveFontSize = ResponsiveUtils.getResponsiveFontSize(
      context,
      baseStyle.fontSize ?? 14,
    );

    return Text(
      text,
      style: baseStyle.copyWith(fontSize: responsiveFontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
