import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración de la aplicación
/// Maneja todas las variables de entorno y configuraciones sensibles
class AppConfig {
  // Singleton pattern
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  /// Inicializa la configuración cargando las variables de entorno
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
  }

  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Resend Configuration
  static String get resendApiKey => dotenv.env['RESEND_API_KEY'] ?? '';
  static String get resendBaseUrl => 'https://api.resend.com';

  // Email Configuration
  static String get emailFromAddress => 'DondeCaiga <noreply@resend.dev>';
  static String get emailFromName => 'DondeCaiga';

  // Validation methods
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isResendConfigured => resendApiKey.isNotEmpty;

  /// Verifica que todas las configuraciones críticas estén presentes
  static bool get isFullyConfigured =>
      isSupabaseConfigured && isResendConfigured;

  /// Obtiene información de configuración para debug (sin exponer keys)
  static Map<String, dynamic> getConfigStatus() {
    return {
      'supabase_configured': isSupabaseConfigured,
      'resend_configured': isResendConfigured,
      'fully_configured': isFullyConfigured,
      'supabase_url_length': supabaseUrl.length,
      'resend_key_length': resendApiKey.length,
    };
  }
}
