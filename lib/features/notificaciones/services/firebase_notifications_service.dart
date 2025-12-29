import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 🔥 SERVICIO COMPLETO DE NOTIFICACIONES FIREBASE
/// Basado en las mejores prácticas y la guía de tu amigo
class FirebaseNotificationsService {
  static final FirebaseNotificationsService _instance =
      FirebaseNotificationsService._internal();
  factory FirebaseNotificationsService() => _instance;
  FirebaseNotificationsService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Callbacks para manejar eventos
  Function(RemoteMessage)? onMessageReceived;
  Function(RemoteMessage)? onMessageOpened;
  Function(String)? onTokenReceived;

  /// ✅ INICIALIZAR SERVICIO COMPLETO
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 Inicializando FirebaseNotificationsService...');

      // 1. Configurar notificaciones locales
      await _setupLocalNotifications();

      // 2. Solicitar permisos
      await _requestPermissions();

      // 3. Configurar Firebase Messaging
      await _setupFirebaseMessaging();

      // 4. Configurar handlers
      _setupMessageHandlers();

      // 5. Obtener y guardar token
      await _handleTokenRefresh();

      _isInitialized = true;
      debugPrint('✅ FirebaseNotificationsService inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error al inicializar FirebaseNotificationsService: $e');
    }
  }

  /// 📱 CONFIGURAR NOTIFICACIONES LOCALES
  Future<void> _setupLocalNotifications() async {
    // Configuración para Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon', // Usar el ícono del launcher que ya existe
    );

    // Configuración para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // ✅ CREAR CANAL DE NOTIFICACIONES PARA ANDROID
    if (defaultTargetPlatform == TargetPlatform.android) {
      const androidChannel = AndroidNotificationChannel(
        'donde_caiga_notifications', // ID del canal
        'Notificaciones de Donde Caiga', // Nombre del canal
        description: 'Notificaciones de reservas, mensajes y actualizaciones',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      debugPrint('✅ Canal de notificaciones Android creado');
    }
  }

  /// 🔔 SOLICITAR PERMISOS
  Future<void> _requestPermissions() async {
    // Permisos de Firebase
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
      announcement: false,
    );

    debugPrint(
      '🔔 Estado de permisos Firebase: ${settings.authorizationStatus}',
    );

    // Permisos adicionales para Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      final granted = await androidImplementation
          ?.requestNotificationsPermission();
      debugPrint(
        '🔔 Permisos Android locales: ${granted == true ? "Concedidos" : "Denegados"}',
      );
    }
  }

  /// 🔥 CONFIGURAR FIREBASE MESSAGING
  Future<void> _setupFirebaseMessaging() async {
    // ✅ CONFIGURAR PRESENTACIÓN EN PRIMER PLANO
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true, // Mostrar alerta
          badge: true, // Mostrar badge
          sound: true, // Reproducir sonido
        );

    debugPrint(
      '✅ Firebase configurado para mostrar notificaciones en primer plano',
    );
  }

  /// 📨 CONFIGURAR HANDLERS DE MENSAJES
  void _setupMessageHandlers() {
    // ✅ MENSAJES EN PRIMER PLANO (app abierta)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Mensaje recibido en primer plano: ${message.messageId}');
      debugPrint('📱 Título: ${message.notification?.title}');
      debugPrint('📝 Cuerpo: ${message.notification?.body}');

      // Mostrar notificación local personalizada
      _showLocalNotification(message);

      // Llamar callback
      onMessageReceived?.call(message);
    });

    // ✅ CUANDO EL USUARIO TOCA UNA NOTIFICACIÓN
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 Notificación abierta: ${message.messageId}');
      onMessageOpened?.call(message);
    });

    // ✅ VERIFICAR SI LA APP SE ABRIÓ DESDE UNA NOTIFICACIÓN
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        debugPrint('🚀 App abierta desde notificación: ${message.messageId}');
        onMessageOpened?.call(message);
      }
    });

    // ✅ ESCUCHAR CAMBIOS EN EL TOKEN
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
      debugPrint('🔄 Token FCM actualizado: ${token.substring(0, 20)}...');
      _saveTokenToSupabase(token);
      onTokenReceived?.call(token);
    });
  }

  /// 🔑 MANEJAR TOKEN FCM
  Future<void> _handleTokenRefresh() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('🔑 Token FCM obtenido: ${token.substring(0, 20)}...');
        await _saveTokenToSupabase(token);
        onTokenReceived?.call(token);
      }
    } catch (e) {
      debugPrint('❌ Error al obtener token FCM: $e');
    }
  }

  /// 💾 GUARDAR TOKEN EN SUPABASE
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        debugPrint('💾 Guardando token FCM en Supabase...');
        debugPrint('👤 Usuario ID: ${user.id}');
        debugPrint('📧 Usuario Email: ${user.email}');
        debugPrint('🔑 Token: ${token.substring(0, 30)}...');

        // ✅ VERIFICAR SI YA EXISTE ESTE TOKEN EN OTRO USUARIO
        final existingTokenCheck = await Supabase.instance.client
            .from('users_profiles')
            .select('id, email')
            .eq('fcm_token', token)
            .neq('id', user.id);

        if (existingTokenCheck.isNotEmpty) {
          debugPrint(
            '⚠️ TOKEN DUPLICADO DETECTADO! Limpiando tokens antiguos...',
          );

          // Limpiar token de otros usuarios
          await Supabase.instance.client
              .from('users_profiles')
              .update({'fcm_token': null})
              .eq('fcm_token', token)
              .neq('id', user.id);

          debugPrint('✅ Tokens duplicados limpiados');
        }

        // Usar la función SQL universal para guardar el token
        try {
          final response = await Supabase.instance.client.rpc(
            'save_user_fcm_token',
            params: {'user_uuid': user.id, 'new_token': token},
          );

          debugPrint('✅ Respuesta de save_user_fcm_token: $response');

          // Verificar que se guardó correctamente
          final verification = await Supabase.instance.client
              .from('users_profiles')
              .select('fcm_token, email')
              .eq('id', user.id)
              .single();

          if (verification['fcm_token'] == token) {
            debugPrint('✅ Token FCM verificado para ${verification['email']}');
          } else {
            debugPrint(
              '⚠️ Token FCM no coincide para ${verification['email']}',
            );
          }
        } catch (rpcError) {
          debugPrint(
            '⚠️ Error con función RPC, intentando método directo: $rpcError',
          );

          // Método alternativo directo
          await Supabase.instance.client
              .from('users_profiles')
              .update({'fcm_token': token})
              .eq('id', user.id);

          debugPrint(
            '✅ Token FCM guardado con método directo para ${user.email}',
          );
        }
      } else {
        debugPrint('⚠️ Usuario no autenticado, no se puede guardar token');
      }
    } catch (e) {
      debugPrint('❌ Error al guardar token FCM: $e');
      debugPrint('📋 Detalles del error: ${e.toString()}');
    }
  }

  /// 📱 MOSTRAR NOTIFICACIÓN LOCAL
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      const androidDetails = AndroidNotificationDetails(
        'donde_caiga_notifications',
        'Notificaciones de Donde Caiga',
        channelDescription:
            'Notificaciones de reservas, mensajes y actualizaciones',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: 'ic_notification', // Cambiar de @mipmap/ic_launcher
        color: Color(0xFF4DB6AC), // Color de tu app
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        message.hashCode, // ID único basado en el mensaje
        notification.title ?? 'Nueva notificación',
        notification.body ?? '',
        notificationDetails,
        payload: message.data.toString(),
      );

      debugPrint('✅ Notificación local mostrada');
    } catch (e) {
      debugPrint('❌ Error al mostrar notificación local: $e');
    }
  }

  /// 👆 MANEJAR TAP EN NOTIFICACIÓN LOCAL
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Notificación local tocada: ${response.payload}');

    // Aquí puedes manejar la navegación basada en el payload
    if (response.payload != null) {
      // Parsear payload y navegar a la pantalla correspondiente
    }
  }

  /// 🔑 OBTENER TOKEN FCM ACTUAL
  Future<String?> getCurrentToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('❌ Error al obtener token actual: $e');
      return null;
    }
  }

  /// 📊 VERIFICAR ESTADO DE PERMISOS
  Future<bool> areNotificationsEnabled() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// 🎯 SUSCRIBIRSE A TÓPICO
  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('✅ Suscrito al tópico: $topic');
    } catch (e) {
      debugPrint('❌ Error al suscribirse al tópico $topic: $e');
    }
  }

  /// 🚫 DESUSCRIBIRSE DE TÓPICO
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      debugPrint('✅ Desuscrito del tópico: $topic');
    } catch (e) {
      debugPrint('❌ Error al desuscribirse del tópico $topic: $e');
    }
  }

  /// 🔧 CONFIGURAR CALLBACKS
  void setCallbacks({
    Function(RemoteMessage)? onMessageReceived,
    Function(RemoteMessage)? onMessageOpened,
    Function(String)? onTokenReceived,
  }) {
    this.onMessageReceived = onMessageReceived;
    this.onMessageOpened = onMessageOpened;
    this.onTokenReceived = onTokenReceived;
  }

  /// 🧹 LIMPIAR SERVICIO
  void dispose() {
    _isInitialized = false;
    onMessageReceived = null;
    onMessageOpened = null;
    onTokenReceived = null;
  }

  /// 🚪 LIMPIAR TOKEN AL HACER LOGOUT
  Future<void> clearTokenOnLogout() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        debugPrint('🚪 Limpiando FCM token al hacer logout...');

        // Limpiar token en Supabase
        await Supabase.instance.client
            .from('users_profiles')
            .update({'fcm_token': null})
            .eq('id', user.id);

        debugPrint('✅ Token FCM limpiado para ${user.email}');
      }

      // Limpiar token local de Firebase
      await FirebaseMessaging.instance.deleteToken();
      debugPrint('✅ Token FCM local eliminado');
    } catch (e) {
      debugPrint('❌ Error al limpiar token FCM: $e');
    }
  }

  /// 🔄 FORZAR REGENERACIÓN DE TOKEN
  Future<void> forceTokenRegeneration() async {
    try {
      debugPrint('🔄 Forzando regeneración de token FCM...');

      // Eliminar token actual
      await FirebaseMessaging.instance.deleteToken();

      // Esperar un momento
      await Future.delayed(const Duration(seconds: 1));

      // Obtener nuevo token
      final newToken = await FirebaseMessaging.instance.getToken();

      if (newToken != null) {
        debugPrint(
          '✅ Nuevo token FCM generado: ${newToken.substring(0, 30)}...',
        );
        await _saveTokenToSupabase(newToken);
        onTokenReceived?.call(newToken);
      }
    } catch (e) {
      debugPrint('❌ Error al regenerar token FCM: $e');
    }
  }

  /// ✅ GETTER PARA VERIFICAR INICIALIZACIÓN
  bool get isInitialized => _isInitialized;
}
