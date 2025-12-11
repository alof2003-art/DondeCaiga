import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/filtro_chat.dart';
import '../models/chat_apartado.dart';

/// Servicio para persistir filtros del chat en almacenamiento local
class FilterStorage {
  static const String _keyPrefix = 'chat_filtros_';

  /// Guardar filtros para un apartado específico
  Future<void> guardarFiltros(TipoApartado apartado, FiltroChat filtro) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + apartado.name;
      final json = jsonEncode(filtro.toJson());
      await prefs.setString(key, json);
    } catch (e) {
      // En caso de error, no hacer nada (filtros no se persisten)
    }
  }

  /// Cargar filtros para un apartado específico
  Future<FiltroChat> cargarFiltros(TipoApartado apartado) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + apartado.name;
      final jsonString = prefs.getString(key);

      if (jsonString == null) {
        return FiltroChat.vacio();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return FiltroChat.fromJson(json);
    } catch (e) {
      // En caso de error, devolver filtros vacíos
      return FiltroChat.vacio();
    }
  }

  /// Limpiar filtros para un apartado específico
  Future<void> limpiarFiltros(TipoApartado apartado) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + apartado.name;
      await prefs.remove(key);
    } catch (e) {
      // Ignorar errores
    }
  }
}
