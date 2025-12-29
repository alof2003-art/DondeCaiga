import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'core/config/app_config.dart';
import 'core/config/performance_config.dart';
import 'core/services/theme_service.dart';
import 'core/services/font_size_service.dart';
import 'core/widgets/font_scale_wrapper.dart';
import 'core/theme/app_theme.dart';
import 'features/notificaciones/presentation/providers/notificaciones_provider.dart';

// ✅ Background Handler para notificaciones
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Notificación en background: ${message.messageId}');
  debugPrint('📱 Título: ${message.notification?.title}');
  debugPrint('📝 Cuerpo: ${message.notification?.body}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar optimizaciones de rendimiento
  PerformanceConfig.configureApp();

  // Inicializar Firebase
  await Firebase.initializeApp();

  // Configurar handler para notificaciones en background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializar configuración de la app
  await AppConfig.initialize();

  // Verificar que la configuración esté completa
  if (!AppConfig.isFullyConfigured) {
    debugPrint('⚠️ Configuración incompleta: ${AppConfig.getConfigStatus()}');
  }

  // Inicializar Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Inicializar servicios
  final themeService = ThemeService();
  await themeService.initialize();

  final fontSizeService = FontSizeService();
  final notificacionesProvider = NotificacionesProvider();

  runApp(
    MyApp(
      themeService: themeService,
      fontSizeService: fontSizeService,
      notificacionesProvider: notificacionesProvider,
    ),
  );
}

// Getter global para acceder al cliente de Supabase
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  final ThemeService themeService;
  final FontSizeService fontSizeService;
  final NotificacionesProvider notificacionesProvider;

  const MyApp({
    super.key,
    required this.themeService,
    required this.fontSizeService,
    required this.notificacionesProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: fontSizeService),
        ChangeNotifierProvider.value(value: notificacionesProvider),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Donde Caiga',
            debugShowCheckedModeBanner: false,
            themeMode: themeService.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const FontScaleWrapper(child: SplashScreen()),
          );
        },
      ),
    );
  }
}
