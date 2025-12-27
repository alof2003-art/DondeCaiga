import 'package:flutter/foundation.dart';

class Mensaje {
  final String id;
  final String reservaId;
  final String remitenteId;
  final String mensaje;
  final bool leido;
  final DateTime createdAt;

  Mensaje({
    required this.id,
    required this.reservaId,
    required this.remitenteId,
    required this.mensaje,
    required this.leido,
    required this.createdAt,
  });

  factory Mensaje.fromJson(Map<String, dynamic> json) {
    return Mensaje(
      id: json['id'] as String,
      reservaId: json['reserva_id'] as String,
      remitenteId: json['remitente_id'] as String,
      mensaje: json['mensaje'] as String,
      leido: json['leido'] as bool? ?? false,
      // Mejorar manejo de zona horaria
      createdAt: _parseDateTime(json['created_at'] as String),
    );
  }

  // Función helper para manejar mejor las fechas
  static DateTime _parseDateTime(String dateTimeString) {
    try {
      // Si ya viene con zona horaria, parsearlo directamente
      if (dateTimeString.contains('+') || dateTimeString.endsWith('Z')) {
        return DateTime.parse(dateTimeString).toLocal();
      }

      // Si no tiene zona horaria, asumir que es UTC y convertir a local
      final utcDateTime = DateTime.parse(dateTimeString + 'Z');
      return utcDateTime.toLocal();
    } catch (e) {
      // Fallback: usar DateTime.now() si hay error
      debugPrint('Error parsing datetime: $dateTimeString, error: $e');
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reserva_id': reservaId,
      'remitente_id': remitenteId,
      'mensaje': mensaje,
      'leido': leido,
      // Enviar siempre en UTC para consistencia
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  // Método para obtener hora formateada
  String get horaFormateada {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

  // Método para obtener hora exacta
  String get horaExacta {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }
}
