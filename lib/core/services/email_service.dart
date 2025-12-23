import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

/// Servicio para envío de emails usando Resend
class EmailService {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Envía un email de código de recuperación
  static Future<EmailResult> sendPasswordResetCode({
    required String email,
    required String code,
  }) async {
    try {
      // Verificar configuración
      if (!AppConfig.isResendConfigured) {
        return EmailResult.error('Servicio de email no configurado');
      }

      // Construir contenido HTML
      final htmlContent = _buildPasswordResetTemplate(code);

      // Intentar envío con reintentos
      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          final response = await _sendEmail(
            to: email,
            subject: 'Código de Recuperación - DondeCaiga',
            html: htmlContent,
          );

          if (response.success) {
            return response;
          }

          // Si no es el último intento, esperar antes de reintentar
          if (attempt < _maxRetries) {
            await Future.delayed(_retryDelay);
          }
        } catch (e) {
          if (attempt == _maxRetries) {
            return EmailResult.error(
              'Error después de $_maxRetries intentos: $e',
            );
          }
        }
      }

      return EmailResult.error(
        'No se pudo enviar el email después de $_maxRetries intentos',
      );
    } catch (e) {
      return EmailResult.error('Error general: $e');
    }
  }

  /// Envía un email usando la API de Resend
  static Future<EmailResult> _sendEmail({
    required String to,
    required String subject,
    required String html,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.resendBaseUrl}/emails'),
            headers: {
              'Authorization': 'Bearer ${AppConfig.resendApiKey}',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'from': AppConfig.emailFromAddress,
              'to': [to],
              'subject': subject,
              'html': html,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return EmailResult.success(
          emailId: responseData['id'] as String?,
          message: 'Email enviado exitosamente',
        );
      } else {
        final errorData = json.decode(response.body);
        return EmailResult.error(
          'Error ${response.statusCode}: ${errorData['message'] ?? 'Error desconocido'}',
        );
      }
    } catch (e) {
      return EmailResult.error('Error de conexión: $e');
    }
  }

  /// Construye la plantilla HTML para recuperación de contraseña
  static String _buildPasswordResetTemplate(String code) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Código de Recuperación</title>
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
        <div style="background: linear-gradient(135deg, #4DB6AC 0%, #26A69A 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 28px;">🏠 DondeCaiga</h1>
            <p style="color: white; margin: 10px 0 0 0; opacity: 0.9;">Recuperación de Contraseña</p>
        </div>
        
        <div style="background: white; padding: 40px; border-radius: 0 0 10px 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
            <h2 style="color: #4DB6AC; margin-top: 0;">¡Hola!</h2>
            
            <p>Recibimos una solicitud para restablecer la contraseña de tu cuenta en DondeCaiga.</p>
            
            <p>Tu código de verificación es:</p>
            
            <div style="background: #f8f9fa; border: 2px dashed #4DB6AC; padding: 25px; text-align: center; margin: 30px 0; border-radius: 8px;">
                <div style="font-size: 36px; font-weight: bold; color: #4DB6AC; letter-spacing: 8px; font-family: 'Courier New', monospace;">
                    $code
                </div>
            </div>
            
            <div style="background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; border-radius: 4px;">
                <p style="margin: 0; color: #856404;">
                    <strong>⏰ Este código expira en 15 minutos.</strong>
                </p>
            </div>
            
            <p>Si no solicitaste este cambio, puedes ignorar este email de forma segura.</p>
            
            <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
            
            <div style="text-align: center; color: #666; font-size: 14px;">
                <p>Este es un email automático, por favor no respondas a este mensaje.</p>
                <p style="margin: 5px 0;">
                    <strong>DondeCaiga</strong> - Tu plataforma de alojamientos de confianza
                </p>
            </div>
        </div>
    </body>
    </html>
    ''';
  }
}

/// Resultado del envío de email
class EmailResult {
  final bool success;
  final String message;
  final String? emailId;

  EmailResult._({required this.success, required this.message, this.emailId});

  factory EmailResult.success({String? emailId, String? message}) {
    return EmailResult._(
      success: true,
      message: message ?? 'Email enviado exitosamente',
      emailId: emailId,
    );
  }

  factory EmailResult.error(String message) {
    return EmailResult._(success: false, message: message);
  }

  @override
  String toString() {
    return 'EmailResult(success: $success, message: $message, emailId: $emailId)';
  }
}
