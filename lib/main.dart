import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'core/config/app_config.dart';
import 'core/config/performance_config.dart';
import 'core/services/theme_service.dart';
import 'core/services/font_size_service.dart';
import 'core/widgets/font_scale_wrapper.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar optimizaciones de rendimiento
  PerformanceConfig.configureApp();

  // Inicializar configuración de la app
  await AppConfig.initialize();

  // Verificar que la configuración esté completa
  if (!AppConfig.isFullyConfigured) {
    print('⚠️ Configuración incompleta: ${AppConfig.getConfigStatus()}');
  }

  // Inicializar Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Inicializar servicio de tema
  final themeService = ThemeService();
  await themeService.initialize();

  // Inicializar servicio de tamaño de fuente
  final fontSizeService = FontSizeService();

  runApp(MyApp(themeService: themeService, fontSizeService: fontSizeService));
}

// Getter global para acceder al cliente de Supabase
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  final ThemeService themeService;
  final FontSizeService fontSizeService;

  const MyApp({
    super.key,
    required this.themeService,
    required this.fontSizeService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: fontSizeService),
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
