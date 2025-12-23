import 'package:flutter/material.dart';
import 'reserva_chat_info.dart';

/// Enum que define los tipos de apartados disponibles en el chat
enum TipoApartado { misViajes, misReservas }

/// Modelo que representa un apartado del chat con su configuración visual y datos
class ChatApartado {
  final TipoApartado tipo;
  final String titulo;
  final Color colorPrimario;
  final Color colorSecundario;
  final Color colorAcento;
  final IconData icono;
  final List<ReservaChatInfo> reservasVigentes;
  final List<ReservaChatInfo> reservasPasadas;

  const ChatApartado({
    required this.tipo,
    required this.titulo,
    required this.colorPrimario,
    required this.colorSecundario,
    required this.colorAcento,
    required this.icono,
    required this.reservasVigentes,
    required this.reservasPasadas,
  });

  /// Factory constructor para crear apartado "Mis Viajes"
  factory ChatApartado.misViajes({
    required List<ReservaChatInfo> reservasVigentes,
    required List<ReservaChatInfo> reservasPasadas,
  }) {
    return ChatApartado(
      tipo: TipoApartado.misViajes,
      titulo: 'Mis Viajes',
      colorPrimario: const Color(0xFF2196F3), // Blue
      colorSecundario: const Color(0xFFE3F2FD), // Light Blue
      colorAcento: const Color(0xFF1976D2), // Dark Blue
      icono: Icons.luggage,
      reservasVigentes: reservasVigentes,
      reservasPasadas: reservasPasadas,
    );
  }

  /// Factory constructor para crear apartado "Mis Reservas"
  factory ChatApartado.misReservas({
    required List<ReservaChatInfo> reservasVigentes,
    required List<ReservaChatInfo> reservasPasadas,
  }) {
    return ChatApartado(
      tipo: TipoApartado.misReservas,
      titulo: 'Mis Reservas',
      colorPrimario: const Color(0xFF4CAF50), // Green
      colorSecundario: const Color(0xFFE8F5E8), // Light Green
      colorAcento: const Color(0xFF388E3C), // Dark Green
      icono: Icons.home_work,
      reservasVigentes: reservasVigentes,
      reservasPasadas: reservasPasadas,
    );
  }

  /// Obtiene el color para reservas vigentes (más intenso)
  Color get colorReservaVigente => colorAcento;

  /// Obtiene el color para reservas pasadas (más tenue)
  Color get colorReservaPasada => colorPrimario.withValues(alpha: 0.7);

  /// Obtiene el color de fondo para el apartado
  Color get colorFondo => colorSecundario;

  /// Obtiene el total de reservas en este apartado
  int get totalReservas => reservasVigentes.length + reservasPasadas.length;

  /// Verifica si el apartado tiene contenido
  bool get tieneContenido => totalReservas > 0;

  /// Verifica si hay reservas vigentes
  bool get tieneReservasVigentes => reservasVigentes.isNotEmpty;

  /// Verifica si hay reservas pasadas
  bool get tieneReservasPasadas => reservasPasadas.isNotEmpty;

  /// Crea una copia del apartado con nuevos datos
  ChatApartado copyWith({
    List<ReservaChatInfo>? reservasVigentes,
    List<ReservaChatInfo>? reservasPasadas,
  }) {
    return ChatApartado(
      tipo: tipo,
      titulo: titulo,
      colorPrimario: colorPrimario,
      colorSecundario: colorSecundario,
      colorAcento: colorAcento,
      icono: icono,
      reservasVigentes: reservasVigentes ?? this.reservasVigentes,
      reservasPasadas: reservasPasadas ?? this.reservasPasadas,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatApartado &&
        other.tipo == tipo &&
        other.titulo == titulo &&
        other.colorPrimario == colorPrimario &&
        other.colorSecundario == colorSecundario &&
        other.colorAcento == colorAcento &&
        other.icono == icono;
  }

  @override
  int get hashCode {
    return tipo.hashCode ^
        titulo.hashCode ^
        colorPrimario.hashCode ^
        colorSecundario.hashCode ^
        colorAcento.hashCode ^
        icono.hashCode;
  }

  @override
  String toString() {
    return 'ChatApartado(tipo: $tipo, titulo: $titulo, reservasVigentes: ${reservasVigentes.length}, reservasPasadas: ${reservasPasadas.length})';
  }
}

/// Extensión para obtener configuraciones de color por tipo de apartado
extension TipoApartadoExtension on TipoApartado {
  /// Obtiene el color primario para este tipo de apartado
  Color get colorPrimario {
    switch (this) {
      case TipoApartado.misViajes:
        return const Color(0xFF2196F3); // Blue
      case TipoApartado.misReservas:
        return const Color(0xFF4CAF50); // Green
    }
  }

  /// Obtiene el color secundario para este tipo de apartado
  Color get colorSecundario {
    switch (this) {
      case TipoApartado.misViajes:
        return const Color(0xFFE3F2FD); // Light Blue
      case TipoApartado.misReservas:
        return const Color(0xFFE8F5E8); // Light Green
    }
  }

  /// Obtiene el color de acento para este tipo de apartado
  Color get colorAcento {
    switch (this) {
      case TipoApartado.misViajes:
        return const Color(0xFF1976D2); // Dark Blue
      case TipoApartado.misReservas:
        return const Color(0xFF388E3C); // Dark Green
    }
  }

  /// Obtiene el icono para este tipo de apartado
  IconData get icono {
    switch (this) {
      case TipoApartado.misViajes:
        return Icons.luggage;
      case TipoApartado.misReservas:
        return Icons.home_work;
    }
  }

  /// Obtiene el título para este tipo de apartado
  String get titulo {
    switch (this) {
      case TipoApartado.misViajes:
        return 'Mis Viajes';
      case TipoApartado.misReservas:
        return 'Mis Reservas';
    }
  }
}
