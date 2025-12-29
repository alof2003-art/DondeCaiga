import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio principal de notificaciones
/// Maneja FCM tokens y notificaciones push
class NotificationsService {
  static final NotificationsService _instance =
      NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _currentToken;
  bool _isInitialized = false;

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔔 Inicializando NotificationsService...');

      // Solicitar permisos
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Permisos de notificaciones concedidos');

        // Obtener token FCM
        await _updateFCMToken();

        // Configurar listeners
        _setupMessageHandlers();

        _isInitialized = true;
        debugPrint('✅ NotificationsService inicializado correctamente');
      } else {
        debugPrint('❌ Permisos de notificaciones denegados');
      }
    } catch (e) {
      debugPrint('❌ Error al inicializar NotificationsService: $e');
    }
  }

  /// Actualizar token FCM en Supabase - CON LOGS ULTRA DETALLADOS
  Future<void> _updateFCMToken() async {
    debugPrint('🔄 === INICIANDO ACTUALIZACIÓN DE TOKEN FCM ===');

    try {
      // PASO 1: Verificar usuario autenticado
      final user = _supabase.auth.currentUser;
      debugPrint('👤 Usuario autenticado: ${user?.id ?? 'NULL'}');
      debugPrint('📧 Email usuario: ${user?.email ?? 'NULL'}');

      if (user == null) {
        debugPrint('❌ FALLO: Usuario no autenticado');
        return;
      }

      // PASO 2: Obtener token del dispositivo
      debugPrint('📱 Obteniendo token FCM del dispositivo...');
      final deviceToken = await _firebaseMessaging.getToken();
      debugPrint('🔑 Token obtenido: ${deviceToken != null ? 'SÍ' : 'NO'}');

      if (deviceToken == null) {
        debugPrint('❌ FALLO: No se pudo obtener token FCM del dispositivo');
        return;
      }

      // PASO 3: Mostrar token (primeros y últimos caracteres)
      final tokenPreview =
          '${deviceToken.substring(0, 20)}...${deviceToken.substring(deviceToken.length - 10)}';
      debugPrint('🔑 Token FCM: $tokenPreview');
      debugPrint('📏 Longitud del token: ${deviceToken.length} caracteres');

      // PASO 4: Guardar token actual en memoria
      _currentToken = deviceToken;
      debugPrint('💾 Token guardado en memoria local');

      // PASO 5: USAR FUNCIÓN CON LOGS DETALLADOS
      debugPrint('🔄 Usando función con logs detallados...');

      try {
        final result = await _supabase.rpc(
          'actualizar_token_fcm_con_logs',
          params: {'p_user_id': user.id, 'p_new_token': deviceToken},
        );
        debugPrint('📊 Resultado función con logs: $result');

        if (result.toString().contains('✅')) {
          debugPrint('🎉 TOKEN GUARDADO EXITOSAMENTE CON LOGS');
        } else {
          debugPrint('⚠️ Problema reportado por función: $result');
        }
      } catch (logsError) {
        debugPrint(
          '⚠️ Error en función con logs, probando método seguro: $logsError',
        );

        // Fallback 1: Función segura original
        try {
          final result = await _supabase.rpc(
            'asignar_token_seguro',
            params: {'p_user_id': user.id, 'p_token': deviceToken},
          );
          debugPrint('🧹 Resultado asignación segura: $result');

          if (result.toString().contains('✅')) {
            debugPrint('🎉 TOKEN ASIGNADO CON MÉTODO SEGURO');
          } else {
            debugPrint('⚠️ Problema en asignación segura: $result');
          }
        } catch (secureError) {
          debugPrint(
            '⚠️ Error en método seguro, usando UPDATE directo: $secureError',
          );

          // Fallback 2: UPDATE directo
          final updateResult = await _supabase
              .from('users_profiles')
              .update({'fcm_token': deviceToken})
              .eq('id', user.id)
              .select();

          debugPrint('✅ UPDATE directo ejecutado');
          debugPrint('📊 Resultado UPDATE: $updateResult');
          debugPrint('📈 Filas afectadas: ${updateResult.length}');

          if (updateResult.isNotEmpty) {
            debugPrint('🎉 TOKEN FCM GUARDADO CON UPDATE DIRECTO');
          } else {
            debugPrint(
              '⚠️ UPDATE no afectó ninguna fila - posible problema de RLS',
            );
          }
        }
      }

      // PASO 6: Verificar que el token se guardó correctamente
      debugPrint('🔍 Verificando que el token se guardó...');
      try {
        final verification = await _supabase
            .from('users_profiles')
            .select('fcm_token, updated_at')
            .eq('id', user.id)
            .single();

        if (verification['fcm_token'] == deviceToken) {
          debugPrint(
            '✅ VERIFICACIÓN EXITOSA: Token confirmado en base de datos',
          );
          debugPrint('📅 Actualizado en: ${verification['updated_at']}');
        } else {
          debugPrint('❌ VERIFICACIÓN FALLÓ: Token en BD no coincide');
          debugPrint(
            '🔍 Token en BD: ${verification['fcm_token']?.substring(0, 20) ?? 'NULL'}...',
          );
          debugPrint('🔍 Token esperado: ${deviceToken.substring(0, 20)}...');
        }
      } catch (verificationError) {
        debugPrint('❌ Error en verificación: $verificationError');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR GENERAL EN ACTUALIZACIÓN: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      // PASO 7: Último fallback con función básica
      debugPrint('🔄 Último intento con función básica...');

      try {
        final user = _supabase.auth.currentUser;
        final deviceToken = await _firebaseMessaging.getToken();

        if (user != null && deviceToken != null) {
          debugPrint('🔧 Llamando función actualizar_token_fcm_basico...');

          final result = await _supabase.rpc(
            'actualizar_token_fcm_basico',
            params: {'p_user_id': user.id, 'p_new_token': deviceToken},
          );

          debugPrint('✅ Función básica ejecutada');
          debugPrint('📊 Resultado función básica: $result');
        } else {
          debugPrint('❌ ÚLTIMO FALLBACK FALLO: user o token es null');
        }
      } catch (fallbackError, fallbackStack) {
        debugPrint('❌ ERROR EN ÚLTIMO FALLBACK: $fallbackError');
        debugPrint('📍 Fallback stack: $fallbackStack');
      }
    }

    debugPrint('🏁 === FIN ACTUALIZACIÓN TOKEN FCM ===');
  }

  /// Configurar handlers de mensajes
  void _setupMessageHandlers() {
    // Mensaje recibido cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Mensaje recibido en foreground: ${message.messageId}');
      debugPrint('📱 Título: ${message.notification?.title}');
      debugPrint('📝 Cuerpo: ${message.notification?.body}');

      // Aquí puedes mostrar una notificación local o actualizar la UI
    });

    // Mensaje tocado cuando la app está en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 Notificación tocada: ${message.messageId}');

      // Aquí puedes navegar a una pantalla específica
      _handleNotificationTap(message);
    });

    // Token actualizado
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      debugPrint('🔄 Token FCM actualizado');
      _currentToken = token;
      _updateFCMToken();
    });
  }

  /// Manejar tap en notificación
  void _handleNotificationTap(RemoteMessage message) {
    // Implementar navegación basada en el tipo de notificación
    final data = message.data;
    debugPrint('📊 Datos de notificación: $data');

    // Ejemplo de navegación basada en tipo
    switch (data['type']) {
      case 'nuevo_mensaje':
        // Navegar al chat
        break;
      case 'nueva_reserva':
        // Navegar a reservas
        break;
      case 'nueva_resena':
        // Navegar a reseñas
        break;
      default:
        // Navegar a notificaciones
        break;
    }
  }

  /// Forzar actualización de token FCM (para debugging)
  Future<void> forceUpdateToken() async {
    debugPrint('🔧 === FORZANDO ACTUALIZACIÓN DE TOKEN FCM ===');
    _isInitialized = false; // Resetear para forzar reinicialización
    await initialize();
    debugPrint('🔧 === FIN FORZAR ACTUALIZACIÓN ===');
  }

  /// Obtener información de debug del token
  Future<Map<String, dynamic>> getTokenDebugInfo() async {
    final user = _supabase.auth.currentUser;
    final token = await _firebaseMessaging.getToken();

    final debugInfo = {
      'user_authenticated': user != null,
      'user_id': user?.id,
      'user_email': user?.email,
      'token_available': token != null,
      'token_length': token?.length ?? 0,
      'token_preview': token != null
          ? '${token.substring(0, 20)}...${token.substring(token.length - 10)}'
          : 'NULL',
      'service_initialized': _isInitialized,
      'current_token_in_memory': _currentToken != null,
    };

    debugPrint('🔍 DEBUG INFO: $debugInfo');
    return debugInfo;
  }

  /// Obtener logs de debugging desde la base de datos
  Future<List<Map<String, dynamic>>> getDebugLogs({
    String? userEmail,
    int limit = 20,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      final emailToUse = userEmail ?? user?.email;

      debugPrint('📊 Obteniendo logs de debugging para: $emailToUse');

      final result = await _supabase.rpc(
        'ver_logs_fcm_debug',
        params: {'p_user_email': emailToUse, 'p_limit': limit},
      );

      debugPrint('📊 Logs obtenidos: ${result.length} registros');
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ Error obteniendo logs: $e');
      return [];
    }
  }

  /// Obtener estadísticas de tokens
  Future<Map<String, dynamic>?> getTokenStatistics() async {
    try {
      debugPrint('📈 Obteniendo estadísticas de tokens...');

      final result = await _supabase.rpc('estadisticas_tokens_fcm');

      if (result.isNotEmpty) {
        final stats = result.first;
        debugPrint('📈 Estadísticas: $stats');
        return Map<String, dynamic>.from(stats);
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas: $e');
      return null;
    }
  }

  /// Obtener monitoreo en tiempo real
  Future<List<Map<String, dynamic>>> getRealtimeMonitoring() async {
    try {
      debugPrint('⏱️ Obteniendo monitoreo en tiempo real...');

      final result = await _supabase.rpc('monitoreo_tiempo_real_tokens');

      debugPrint('⏱️ Datos de monitoreo: ${result.length} usuarios');
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ Error en monitoreo: $e');
      return [];
    }
  }

  /// Obtener token actual
  String? get currentToken => _currentToken;

  /// Verificar si está inicializado
  bool get isInitialized => _isInitialized;

  /// Limpiar datos al cerrar sesión
  Future<void> clearData() async {
    try {
      debugPrint('🧹 === LIMPIANDO DATOS AL CERRAR SESIÓN ===');

      // Limpiar token de Supabase usando función con logs
      final user = _supabase.auth.currentUser;
      if (user != null) {
        debugPrint('🔄 Limpiando token FCM del usuario: ${user.email}');

        try {
          final result = await _supabase.rpc(
            'limpiar_token_logout_con_logs',
            params: {'p_user_id': user.id},
          );
          debugPrint('🧹 Resultado limpieza con logs: $result');
        } catch (rpcError) {
          debugPrint(
            '⚠️ Error en función con logs, usando función original: $rpcError',
          );

          try {
            final result = await _supabase.rpc(
              'limpiar_token_logout',
              params: {'p_user_id': user.id},
            );
            debugPrint('🧹 Resultado limpieza original: $result');
          } catch (originalError) {
            debugPrint(
              '⚠️ Error en función original, usando UPDATE directo: $originalError',
            );

            // Fallback: UPDATE directo
            await _supabase
                .from('users_profiles')
                .update({'fcm_token': null})
                .eq('id', user.id);

            debugPrint('✅ Token limpiado con UPDATE directo');
          }
        }
      }

      _currentToken = null;
      _isInitialized = false;
      debugPrint('🧹 Datos de notificaciones limpiados completamente');
    } catch (e) {
      debugPrint('❌ Error al limpiar datos: $e');
    }
  }
}
