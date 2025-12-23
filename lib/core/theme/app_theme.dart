import 'package:flutter/material.dart';

/// Definición de temas de la aplicación
class AppTheme {
  // Colores principales
  static const Color primaryColor = Color(0xFF4DB6AC);
  static const Color primaryDarkColor = Color(0xFF26A69A);
  static const Color accentColor = Color(0xFF80CBC4);

  // Colores para modo claro
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF263238);
  static const Color lightTextSecondary = Color(0xFF546E7A);

  // Colores para modo oscuro
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  /// Tema claro
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Esquema de colores
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: accentColor,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      // Scaffold
      scaffoldBackgroundColor: lightBackground,

      // Cards
      cardTheme: const CardThemeData(
        color: lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade600),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),

      // Texto
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: lightTextPrimary),
        bodyMedium: TextStyle(color: lightTextPrimary),
        bodySmall: TextStyle(color: lightTextSecondary),
        labelLarge: TextStyle(
          color: lightTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(color: lightTextSecondary),
        labelSmall: TextStyle(color: lightTextSecondary),
      ),

      // Iconos
      iconTheme: const IconThemeData(color: lightTextPrimary),
    );
  }

  /// Tema oscuro
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Esquema de colores
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: accentColor,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
      ),

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),

      // Scaffold
      scaffoldBackgroundColor: darkBackground,

      // Cards
      cardTheme: const CardThemeData(
        color: darkSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary),
        hintStyle: const TextStyle(color: darkTextSecondary),
      ),

      // Texto
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: darkTextPrimary),
        bodyMedium: TextStyle(color: darkTextPrimary),
        bodySmall: TextStyle(color: darkTextSecondary),
        labelLarge: TextStyle(
          color: darkTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(color: darkTextSecondary),
        labelSmall: TextStyle(color: darkTextSecondary),
      ),

      // Iconos
      iconTheme: const IconThemeData(color: darkTextPrimary),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),

      // Drawer
      drawerTheme: const DrawerThemeData(backgroundColor: darkSurface),

      // Dialog
      dialogTheme: const DialogThemeData(
        backgroundColor: darkSurface,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: darkTextPrimary, fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceVariant,
        contentTextStyle: const TextStyle(color: darkTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
