import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🚀 PROCESADOR DE COLA DE NOTIFICACIONES PUSH
/// Este servicio procesa las notificaciones pendientes llamando directamente a la Edge Function
class PushQueueProcessor {
  static final PushQueueProcessor _instance = PushQueueProcessor._internal();
  factory PushQueueProcessor() => _instance;
  PushQueueProcessor._internal();

  Timer? _processingTimer;
  bool _isProcessing = false;

  /// ✅ INICIAR PROCESAMIENTO AUTOMÁTICO
  void startProcessing() {
    if (_processingTimer != null) return;

    debugPrint('🚀 Iniciando procesador de cola push...');

    // Procesar cada 10 segundos
    _processingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _processQueue(),
    );

    // Procesar inmediatamente
    _processQueue();
  }

  /// 🛑 DETENER PROCESAMIENTO
  void stopProcessing() {
    _processingTimer?.cancel();
    _processingTimer = null;
    debugPrint('🛑 Procesador de cola push detenido');
  }

  /// 📋 PROCESAR COLA DE NOTIFICACIONES
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Obtener notificaciones pendientes directamente de la tabla
      final response = await Supabase.instance.client
          .from('push_notification_queue')
          .select('id, user_id, fcm_token, title, body, data, created_at')
          .eq('status', 'pending')
          .order('created_at', ascending: true)
          .limit(10);

      if (response.isNotEmpty) {
        debugPrint(
          '📋 Procesando ${response.length} notificaciones pendientes',
        );

        for (final notification in response) {
          await _processNotification(notification);
        }
      } else {
        // Si no hay notificaciones pendientes, no hacer nada
        // debugPrint('📋 No hay notificaciones pendientes');
      }
    } catch (e) {
      debugPrint('❌ Error al procesar cola push: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// 📱 PROCESAR UNA NOTIFICACIÓN
  Future<void> _processNotification(Map<String, dynamic> notification) async {
    try {
      final id = notification['id'];
      final fcmToken = notification['fcm_token'];
      final title = notification['title'];
      final body = notification['body'];

      debugPrint('📱 Procesando notificación: $title');

      // Llamar a la Edge Function
      final success = await _callEdgeFunction(
        fcmToken: fcmToken,
        title: title,
        body: body,
      );

      if (success) {
        // Marcar como enviada directamente en la tabla
        await Supabase.instance.client
            .from('push_notification_queue')
            .update({
              'status': 'sent',
              'sent_at': DateTime.now().toIso8601String(),
              'attempts': (notification['attempts'] ?? 0) + 1,
            })
            .eq('id', id);

        debugPrint('✅ Notificación enviada: $title');
      } else {
        // Marcar como fallida
        await Supabase.instance.client
            .from('push_notification_queue')
            .update({
              'status': 'failed',
              'attempts': (notification['attempts'] ?? 0) + 1,
              'error_message': 'Edge Function returned false',
            })
            .eq('id', id);

        debugPrint('❌ Error al enviar notificación: $title');
      }
    } catch (e) {
      debugPrint('❌ Error al procesar notificación: $e');
    }
  }

  /// 🔥 LLAMAR A EDGE FUNCTION
  Future<bool> _callEdgeFunction({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    try {
      // Obtener URL y key de Supabase correctamente
      final supabaseUrl = 'https://louehuwimvwsoqesjjau.supabase.co';
      final anonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvdWVodXdpbXZ3c29xZXNqamF1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3OTQ4MTYsImV4cCI6MjA4MDM3MDgxNn0.vhqclBtgt-o_GTNFGsU-pKYK68coeemIjl_CTQl8Rz8';

      final url = '$supabaseUrl/functions/v1/send-push-notification';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $anonKey',
        },
        body: jsonEncode({'fcm_token': fcmToken, 'title': title, 'body': body}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Edge Function response: ${result['success']}');
        return result['success'] == true;
      } else {
        debugPrint('❌ Edge Function error: ${response.statusCode}');
        debugPrint('❌ Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error calling Edge Function: $e');
      return false;
    }
  }

  /// 🔧 PROCESAR MANUALMENTE (para testing)
  Future<void> processManually() async {
    debugPrint('🔧 Procesamiento manual iniciado');
    await _processQueue();
  }

  /// 📊 OBTENER ESTADÍSTICAS
  Future<Map<String, int>> getQueueStats() async {
    try {
      final response = await Supabase.instance.client
          .from('push_notification_queue')
          .select('status')
          .gte(
            'created_at',
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .toIso8601String(),
          );

      final stats = <String, int>{};

      for (final item in response) {
        final status = item['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      debugPrint('❌ Error getting queue stats: $e');
      return {};
    }
  }

  /// 🧹 LIMPIAR SERVICIO
  void dispose() {
    stopProcessing();
  }
}
