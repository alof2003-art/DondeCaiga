import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/notificacion.dart';

// Handler para notificaciones en background (DEBE estar fuera de la clase)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔥 Notificación recibida en background: ${message.messageId}');
  debugPrint('📱 Título: ${message.notification?.title}');
  debugPrint('📝 Cuerpo: ${message.notification?.body}');

  // Aquí Firebase automáticamente muestra la notificación en la bandeja del sistema
  // No necesitamos hacer nada más, Firebase se encarga de todo
}

class PushNotificationsService {
  static final PushNotificationsService _instance =
      PushNotificationsService._internal();
  factory PushNotificationsService() => _instance;
  PushNotificationsService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Callbacks
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onMessageOpened;

  // Getters
  bool get isInitialized => _isInitialized;

  // Inicializar el servicio
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializar notificaciones locales
      await _initializeLocalNotifications();

      // Inicializar Firebase Messaging
      await _initializeFirebaseMessaging();

      _isInitialized = true;
      debugPrint('✅ PushNotificationsService inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error al inicializar PushNotificationsService: $e');
    }
  }

  // Inicializar notificaciones locales
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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

    // Solicitar permisos en Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  // Manejar tap en notificación local
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Notificación local tocada: ${response.payload}');

    if (response.payload != null) {
      try {
        // Aquí puedes parsear el payload y navegar a la pantalla correspondiente
        onMessageOpened?.call({'payload': response.payload});
      } catch (e) {
        debugPrint('❌ Error al procesar payload de notificación: $e');
      }
    }
  }

  // Mostrar notificación local
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    int? id,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'donde_caiga_notifications',
        'Notificaciones de Donde Caiga',
        channelDescription: 'Notificaciones de la aplicación Donde Caiga',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
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
        id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        notificationDetails,
        payload: payload != null ? payload.toString() : null,
      );
    } catch (e) {
      debugPrint('❌ Error al mostrar notificación local: $e');
    }
  }

  // Mostrar notificación desde modelo Notificacion
  Future<void> showNotificationFromModel(Notificacion notificacion) async {
    await showLocalNotification(
      title: notificacion.titulo,
      body: notificacion.mensaje,
      payload: {
        'notificacion_id': notificacion.id,
        'tipo': notificacion.tipo.name,
        'datos': notificacion.datos,
      },
    );
  }

  // Cancelar notificación
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cancelar todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Verificar permisos
  Future<bool> areNotificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await iosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  // Solicitar permisos
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImplementation?.requestNotificationsPermission() ??
          false;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await iosImplementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  // Configurar callbacks
  void setCallbacks({
    Function(Map<String, dynamic>)? onMessageReceived,
    Function(Map<String, dynamic>)? onMessageOpened,
  }) {
    this.onMessageReceived = onMessageReceived;
    this.onMessageOpened = onMessageOpened;
  }

  // Inicializar Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Configurar handler para notificaciones en background
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Solicitar permisos
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint(
        '🔔 Permisos de notificación: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Obtener token FCM
        final token = await FirebaseMessaging.instance.getToken();
        debugPrint('🔑 FCM Token: $token');

        // Configurar handlers
        _setupFirebaseHandlers();

        // IMPORTANTE: NO configurar setForegroundNotificationPresentationOptions
        // Esto permite que Firebase maneje las notificaciones automáticamente
        debugPrint(
          '✅ Firebase Messaging configurado para background notifications',
        );
      }
    } catch (e) {
      debugPrint('❌ Error al inicializar Firebase Messaging: $e');
    }
  }

  // Configurar handlers de Firebase
  void _setupFirebaseHandlers() {
    // Guardar token FCM en Supabase cuando se obtenga
    _saveTokenToSupabase();

    // Escuchar cambios en el token
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 Token FCM actualizado: $newToken');
      _saveTokenToSupabase();
    });

    // Notificaciones cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Mensaje recibido en primer plano: ${message.messageId}');

      // Mostrar notificación local
      _showNotificationFromFirebase(message);

      // Llamar callback
      onMessageReceived?.call({
        'messageId': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      });
    });

    // Cuando el usuario toca una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 Notificación abierta: ${message.messageId}');

      onMessageOpened?.call({
        'messageId': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      });
    });

    // Verificar si la app se abrió desde una notificación
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        debugPrint('🚀 App abierta desde notificación: ${message.messageId}');

        onMessageOpened?.call({
          'messageId': message.messageId,
          'title': message.notification?.title,
          'body': message.notification?.body,
          'data': message.data,
        });
      }
    });
  }

  // Mostrar notificación local desde Firebase
  Future<void> _showNotificationFromFirebase(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      await showLocalNotification(
        title: notification.title ?? 'Nueva notificación',
        body: notification.body ?? '',
        payload: message.data,
      );
    }
  }

  // Obtener token FCM
  Future<String?> getFCMToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('❌ Error al obtener FCM token: $e');
      return null;
    }
  }

  // Suscribirse a un tópico
  Future<void> subscribeToTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      debugPrint('✅ Suscrito al tópico: $topic');
    } catch (e) {
      debugPrint('❌ Error al suscribirse al tópico $topic: $e');
    }
  }

  // Desuscribirse de un tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      debugPrint('✅ Desuscrito del tópico: $topic');
    } catch (e) {
      debugPrint('❌ Error al desuscribirse del tópico $topic: $e');
    }
  }

  // Guardar token FCM en Supabase
  Future<void> _saveTokenToSupabase() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      final user = Supabase.instance.client.auth.currentUser;

      debugPrint('🔍 Intentando guardar FCM token...');
      debugPrint('🔑 Token: ${token?.substring(0, 20)}...');
      debugPrint('👤 Usuario ID: ${user?.id}');

      if (token != null && user != null) {
        debugPrint('💾 Guardando token FCM en Supabase...');

        final response = await Supabase.instance.client
            .from('users_profiles')
            .update({'fcm_token': token})
            .eq('id', user.id)
            .select();

        debugPrint('✅ Token FCM guardado exitosamente: $response');
      } else {
        debugPrint('⚠️ No se pudo guardar token FCM:');
        debugPrint('   - Token: ${token != null ? "✅ Disponible" : "❌ Null"}');
        debugPrint(
          '   - Usuario: ${user != null ? "✅ Logueado" : "❌ No logueado"}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error al guardar token FCM: $e');
      debugPrint('📋 Detalles del error: ${e.toString()}');
    }
  }

  // Método público para actualizar token manualmente
  Future<void> updateTokenInSupabase() async {
    await _saveTokenToSupabase();
  }

  // Limpiar servicio
  void dispose() {
    _isInitialized = false;
    onMessageReceived = null;
    onMessageOpened = null;
  }
}
