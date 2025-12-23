# 📧 Configurar Envío Real de Emails

## 🚀 Opción 1: Supabase Edge Functions + Resend (Recomendado)

### Paso 1: Crear Cuenta en Resend
1. Ve a [resend.com](https://resend.com)
2. Crea una cuenta gratuita (100 emails/día gratis)
3. Verifica tu dominio o usa el dominio de prueba
4. Obtén tu API Key

### Paso 2: Configurar Edge Function en Supabase
1. **Instalar Supabase CLI:**
```bash
npm install -g supabase
```

2. **Inicializar proyecto:**
```bash
supabase login
supabase init
```

3. **Crear la función:**
```bash
supabase functions new send-password-reset
```

4. **Copiar el código** del archivo `docs/supabase_edge_function_email.js` a:
   `supabase/functions/send-password-reset/index.ts`

5. **Configurar variables de entorno:**
```bash
supabase secrets set RESEND_API_KEY=tu_api_key_aqui
```

6. **Desplegar la función:**
```bash
supabase functions deploy send-password-reset
```

### Paso 3: Probar
Una vez desplegado, el sistema enviará emails reales automáticamente.

---

## 🚀 Opción 2: Flutter + Mailer (Más Simple)

### Paso 1: Añadir Dependencia
```yaml
# pubspec.yaml
dependencies:
  mailer: ^6.0.1
```

### Paso 2: Configurar SMTP
```dart
// En password_reset_repository.dart
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> sendResetCodeEmail(String email, String code) async {
  try {
    // Configurar servidor SMTP (ejemplo con Gmail)
    final smtpServer = gmail('tu-email@gmail.com', 'tu-app-password');
    
    // O usar otro proveedor:
    // final smtpServer = SmtpServer('smtp.tu-proveedor.com',
    //   port: 587,
    //   username: 'tu-usuario',
    //   password: 'tu-contraseña',
    // );

    final message = Message()
      ..from = Address('tu-email@gmail.com', 'DondeCaiga')
      ..recipients.add(email)
      ..subject = 'Código de Recuperación - DondeCaiga'
      ..html = '''
        <h2>Recuperación de Contraseña</h2>
        <p>Tu código de verificación es:</p>
        <h1 style="color: #4DB6AC; font-size: 32px;">$code</h1>
        <p>Este código expira en 15 minutos.</p>
      ''';

    await send(message, smtpServer);
    print('✅ Email enviado exitosamente');
    
  } catch (e) {
    print('❌ Error enviando email: $e');
    // Mostrar en consola como fallback
    print('📧 Código: $code para $email');
  }
}
```

---

## 🚀 Opción 3: SendGrid (Profesional)

### Paso 1: Crear Cuenta SendGrid
1. Ve a [sendgrid.com](https://sendgrid.com)
2. Crea cuenta (100 emails/día gratis)
3. Obtén API Key

### Paso 2: Añadir Dependencia
```yaml
dependencies:
  sendgrid_mailer: ^0.2.0
```

### Paso 3: Implementar
```dart
import 'package:sendgrid_mailer/sendgrid_mailer.dart';

Future<void> sendResetCodeEmail(String email, String code) async {
  try {
    final mailer = Mailer('TU_SENDGRID_API_KEY');
    
    await mailer.send(Email(
      from: Address('noreply@tudominio.com', 'DondeCaiga'),
      to: [Address(email)],
      subject: 'Código de Recuperación - DondeCaiga',
      html: '''
        <h2>Recuperación de Contraseña</h2>
        <p>Tu código de verificación es:</p>
        <h1 style="color: #4DB6AC;">$code</h1>
        <p>Expira en 15 minutos.</p>
      ''',
    ));
    
    print('✅ Email enviado con SendGrid');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

---

## 🎯 Recomendación

**Para tu proyecto, recomiendo la Opción 1 (Supabase + Resend)** porque:

✅ **Gratis hasta 100 emails/día**
✅ **Fácil de configurar**
✅ **Se integra perfectamente con Supabase**
✅ **Muy confiable**
✅ **No necesitas configurar SMTP**

## 🔧 Configuración Rápida (5 minutos)

1. **Crea cuenta en Resend** → Obtén API Key
2. **Instala Supabase CLI** → `npm install -g supabase`
3. **Crea la función** → Copia el código que te proporcioné
4. **Configura la API Key** → `supabase secrets set RESEND_API_KEY=tu_key`
5. **Despliega** → `supabase functions deploy send-password-reset`

¡Y listo! Tendrás emails reales funcionando.

## 🧪 Para Testing Inmediato

Si quieres probar rápido sin configurar nada, la **Opción 2 con Gmail** es la más rápida:
- Solo necesitas una cuenta Gmail
- Generas una "App Password" 
- Añades la dependencia `mailer`
- ¡Funciona en 2 minutos!

¿Cuál opción prefieres que implementemos?