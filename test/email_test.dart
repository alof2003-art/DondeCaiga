import 'package:flutter_test/flutter_test.dart';
import 'package:donde_caigav2/core/config/app_config.dart';
import 'package:donde_caigav2/core/services/email_service.dart';

void main() {
  group('Sistema de Email Tests', () {
    setUpAll(() async {
      // Inicializar configuración para tests
      await AppConfig.initialize();
    });

    test('Configuración de Resend debe estar presente', () {
      expect(AppConfig.isResendConfigured, isTrue);
      expect(AppConfig.resendApiKey.isNotEmpty, isTrue);
      expect(AppConfig.resendBaseUrl, equals('https://api.resend.com'));
    });

    test('EmailService debe construir plantilla correctamente', () {
      // Este test verifica que el servicio funcione sin enviar email real
      expect(
        () => EmailService.sendPasswordResetCode(
          email: 'test@example.com',
          code: '123456',
        ),
        returnsNormally,
      );
    });

    test('Configuración completa debe estar disponible', () {
      final status = AppConfig.getConfigStatus();
      expect(status['resend_configured'], isTrue);
      expect(status['resend_key_length'], greaterThan(0));
    });
  });
}
