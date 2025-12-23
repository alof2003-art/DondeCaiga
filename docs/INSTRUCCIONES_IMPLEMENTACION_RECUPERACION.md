# 🚀 Instrucciones de Implementación - Sistema de Recuperación de Contraseña

## ✅ Lo que se ha implementado

### 📁 Archivos Creados

#### Base de Datos
- `docs/sistema_recuperacion_contrasena.sql` - Script SQL completo para Supabase

#### Modelos
- `lib/features/auth/data/models/password_reset.dart` - Modelos de datos

#### Repositorio
- `lib/features/auth/data/repositories/password_reset_repository.dart` - Lógica de negocio

#### Pantallas
- `lib/features/auth/presentation/screens/forgot_password_screen.dart` - Solicitar recuperación
- `lib/features/auth/presentation/screens/verify_reset_code_screen.dart` - Verificar código
- `lib/features/auth/presentation/screens/reset_password_screen.dart` - Nueva contraseña

#### Modificaciones
- `lib/features/auth/presentation/screens/login_screen.dart` - Añadido botón "Olvidé mi contraseña"

#### Documentación
- `docs/SISTEMA_RECUPERACION_CONTRASENA_COMPLETO.md` - Documentación técnica completa

## 🗄️ Paso 1: Configurar Base de Datos en Supabase

### Ejecutar Script SQL
1. Ve a tu proyecto en Supabase Dashboard
2. Navega a **SQL Editor**
3. Crea una nueva query
4. Copia y pega el contenido completo de `docs/sistema_recuperacion_contrasena.sql`
5. Ejecuta el script (botón **Run**)

### Verificar Instalación
```sql
-- Verificar que la tabla se creó
SELECT * FROM password_reset_codes LIMIT 1;

-- Probar función de generación
SELECT * FROM generate_password_reset_code('test@ejemplo.com');

-- Probar función de validación
SELECT * FROM validate_password_reset_code('test@ejemplo.com', '123456');
```

## 📱 Paso 2: Probar el Sistema

### Flujo de Prueba
1. **Abrir la app** y ir a la pantalla de login
2. **Tocar "¿Olvidaste tu contraseña?"**
3. **Ingresar un email** registrado en tu sistema
4. **Ver el código** en la consola (por ahora se imprime ahí)
5. **Ingresar el código** en la pantalla de verificación
6. **Establecer nueva contraseña**
7. **Verificar que puedes hacer login** con la nueva contraseña

### Datos de Prueba
- Usa un email que ya esté registrado en tu sistema
- El código se imprimirá en la consola de Flutter por ahora
- La contraseña debe tener: 8+ caracteres, mayúscula, minúscula, número

## 📧 Paso 3: Configurar Envío de Emails (Futuro)

### Opciones Recomendadas

#### Opción 1: SendGrid (Recomendado)
```dart
// Añadir dependencia
dependencies:
  sendgrid_mailer: ^0.2.0

// Configurar en password_reset_repository.dart
Future<void> sendResetCodeEmail(String email, String code) async {
  final mailer = Mailer('your-sendgrid-api-key');
  
  await mailer.send(Email(
    from: Address('noreply@dondecaiga.com', 'DondeCaiga'),
    to: [Address(email)],
    subject: 'Código de Recuperación - DondeCaiga',
    html: '''
      <h2>Recuperación de Contraseña</h2>
      <p>Tu código de verificación es:</p>
      <h1 style="color: #4DB6AC; font-size: 32px;">$code</h1>
      <p>Este código expira en 15 minutos.</p>
    ''',
  ));
}
```

#### Opción 2: Supabase Edge Functions
```javascript
// Crear función en Supabase
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { email, code } = await req.json()
  
  // Enviar email usando tu servicio preferido
  // Retornar respuesta
})
```

## 🔧 Paso 4: Personalización Opcional

### Cambiar Tiempo de Expiración
```sql
-- En la función generate_password_reset_code
-- Cambiar esta línea:
expiry_time := NOW() + INTERVAL '15 minutes';
-- Por ejemplo, para 30 minutos:
expiry_time := NOW() + INTERVAL '30 minutes';
```

### Cambiar Longitud del Código
```sql
-- En la función generate_password_reset_code
-- Cambiar esta línea:
reset_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
-- Por ejemplo, para 8 dígitos:
reset_code := LPAD(FLOOR(RANDOM() * 100000000)::TEXT, 8, '0');
```

### Personalizar Validación de Contraseña
```dart
// En password_reset_repository.dart, método _validatePassword
void _validatePassword(String password) {
  if (password.length < 12) { // Cambiar mínimo
    throw Exception('La contraseña debe tener al menos 12 caracteres');
  }
  
  // Añadir más validaciones
  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
    throw Exception('Debe contener al menos un carácter especial');
  }
}
```

## 🧪 Paso 5: Testing Completo

### Casos de Prueba Esenciales
1. ✅ **Email válido** - Debe generar código
2. ✅ **Email inválido** - Debe mostrar error
3. ✅ **Código correcto** - Debe permitir cambio
4. ✅ **Código incorrecto** - Debe mostrar error
5. ✅ **Código expirado** - Debe mostrar error
6. ✅ **Contraseña débil** - Debe mostrar error
7. ✅ **Contraseñas no coinciden** - Debe mostrar error

### Script de Prueba SQL
```sql
-- Limpiar datos de prueba
DELETE FROM password_reset_codes WHERE email = 'test@ejemplo.com';

-- Generar código
SELECT * FROM generate_password_reset_code('test@ejemplo.com');

-- Validar código (usar el código generado)
SELECT * FROM validate_password_reset_code('test@ejemplo.com', 'CODIGO_AQUI');

-- Verificar que se marcó como usado
SELECT * FROM password_reset_codes WHERE email = 'test@ejemplo.com';
```

## 🚨 Consideraciones de Seguridad

### Implementadas ✅
- Códigos de un solo uso
- Expiración automática (15 minutos)
- Validación de formato de email
- Contraseñas fuertes requeridas
- RLS habilitado en base de datos
- Limpieza automática de códigos expirados

### Recomendaciones Futuras 🔮
- **Rate limiting**: Máximo 3 intentos por hora por IP
- **Captcha**: Para prevenir ataques automatizados
- **Logs de auditoría**: Registrar todos los intentos
- **Notificación de cambio**: Email cuando se cambie la contraseña
- **2FA opcional**: Autenticación de dos factores

## 📊 Monitoreo Sugerido

### Métricas Importantes
```sql
-- Códigos generados hoy
SELECT COUNT(*) FROM password_reset_codes 
WHERE DATE(created_at) = CURRENT_DATE;

-- Tasa de éxito (códigos usados vs generados)
SELECT 
  COUNT(CASE WHEN used = true THEN 1 END) as used_codes,
  COUNT(*) as total_codes,
  ROUND(COUNT(CASE WHEN used = true THEN 1 END) * 100.0 / COUNT(*), 2) as success_rate
FROM password_reset_codes 
WHERE DATE(created_at) = CURRENT_DATE;

-- Códigos expirados sin usar
SELECT COUNT(*) FROM password_reset_codes 
WHERE used = false AND expires_at < NOW();
```

## 🎯 Próximos Pasos Recomendados

1. **Implementar el sistema** siguiendo estos pasos
2. **Probar exhaustivamente** con diferentes escenarios
3. **Configurar envío de emails** real
4. **Añadir rate limiting** para seguridad
5. **Implementar logs de auditoría**
6. **Crear dashboard de administración** para monitoreo

---

## 🆘 Solución de Problemas

### Error: "Usuario no encontrado"
- Verificar que el email esté registrado en `auth.users`
- Verificar que el email esté en minúsculas

### Error: "Código inválido"
- Verificar que el código tenga exactamente 6 dígitos
- Verificar que no haya expirado (15 minutos)
- Verificar que no haya sido usado ya

### Error: "No se pudo actualizar contraseña"
- Verificar que la contraseña cumpla los requisitos
- Verificar conexión con Supabase
- Revisar logs de Supabase para más detalles

### Código no se imprime en consola
- Verificar que estés en modo debug
- Buscar en la consola de Flutter/VS Code
- El código aparece como: "Código de recuperación para email@ejemplo.com: 123456"

---

**¡El sistema está listo para usar!** 🎉

Solo necesitas ejecutar el script SQL en Supabase y ya podrás probar toda la funcionalidad.