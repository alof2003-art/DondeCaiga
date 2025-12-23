import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSizeLevel {
  pequeno(0.85, 'Pequeño'),
  normal(1.0, 'Normal'),
  grande(1.15, 'Grande'),
  extraGrande(1.3, 'Extra Grande');

  const FontSizeLevel(this.scale, this.label);
  final double scale;
  final String label;
}

class FontSizeService extends ChangeNotifier {
  static const String _fontSizeKey = 'font_size_level';
  FontSizeLevel _currentLevel = FontSizeLevel.normal;

  FontSizeLevel get currentLevel => _currentLevel;
  double get currentScale => _currentLevel.scale;

  FontSizeService() {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_fontSizeKey) ?? 1; // Default: normal

      if (savedIndex >= 0 && savedIndex < FontSizeLevel.values.length) {
        _currentLevel = FontSizeLevel.values[savedIndex];
        notifyListeners();
      }
    } catch (e) {
      print('Error loading font size: $e');
    }
  }

  Future<void> setFontSize(FontSizeLevel level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_fontSizeKey, level.index);
      _currentLevel = level;
      notifyListeners();
    } catch (e) {
      print('Error saving font size: $e');
    }
  }

  // Helper methods para aplicar el escalado
  TextStyle scaleTextStyle(TextStyle? style) {
    if (style == null) return TextStyle(fontSize: 14 * currentScale);
    return style.copyWith(fontSize: (style.fontSize ?? 14) * currentScale);
  }

  double scaleFontSize(double fontSize) {
    return fontSize * currentScale;
  }
}
