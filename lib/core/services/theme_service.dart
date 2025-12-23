import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar el tema de la aplicación (modo claro/oscuro)
class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Inicializa el servicio cargando la preferencia guardada
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Cambia entre modo claro y oscuro
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _themeMode == ThemeMode.dark);

    notifyListeners();
  }

  /// Establece un tema específico
  Future<void> setTheme(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, mode == ThemeMode.dark);

    notifyListeners();
  }
}
