# Sistema de Recuperación de Contraseña - Supabase Nativo

## Descripción General

Hemos migrado del sistema personalizado de códigos de verificación al sistema nativo de recuperación de contraseña de Supabase. Este nuevo enfoque es más seguro, confiable y requiere menos código personalizado.

## Ventajas del Sistema Nativo

### ✅ Beneficios
- **Más seguro**: Mantenido y auditado por Supabase
- **Menos código**: No necesitamos manejar códigos, expiración, etc.
- **Mejor UX**: Enlace directo en email, sin códigos manuales
- **Confiable**: Sistema probado en producción
- **Automático**: Detección automática del enlace

### ❌ Sistema Anterior (Eliminado)
- Códigos de 6 dígitos manuales
- Tabla personalizada `password_reset_codes`
- Funciones SQL personalizadas
- Manejo manual de expiración
- Más puntos de falla

## Flujo del Nuevo Sistema

### 1. Usuario Olvida Contraseña
```
Usuario → Pantalla "Olvidé mi contraseña" → Ingresa email → Supabase envía email
```

### 2. Usuario Recibe Email
```
Email de Supabase → Enlace seguro → Click en enlace → App detecta automáticamente
```

### 3. Cambio de Contraseña
```
App redirige → Pantalla "Nueva Contraseña" → Usuario ingresa nueva contraseña → Actualización exitosa
```

## Archivos Modificados

### Nuevos Archivos
- `lib/features/auth/presentation/screens/update_password_screen.dart` - Nueva pantalla para cambiar contraseña
- `docs/limpiar_sistema_recuperacion_personalizado.sql` - Script para limpiar BD

### Archivos Modificados
- `lib/features/auth/presentation/screens/forgot_password_screen.dart` - Simplificado para usar Supabase
- `lib/main.dart` - Agregado listener para detectar recuperación de contraseña

### Archivos Eliminados
- `lib/features/auth/presentation/screens/verify_reset_code_screen.dart`
- `lib/features/auth/data/repositories/password_reset_repository.dart`
- `lib/features/auth/data/models/password_reset.dart`
- `lib/features/auth/presentation/screens/reset_password_screen.dart`

## Configuración Requerida

### 1. Ejecutar Script de Limpieza
```sql
-- Ejecutar en Supabase SQL Editor
-- Archivo: docs/limpiar_sistema_recuperacion_personalizado.sql
```

### 2. Configurar URL de Redirección en Supabase
1. Ir a Supabase Dashboard
2. Authentication → URL Configuration
3. Agregar: `io.supabase.dondecaigav2://reset-password`

### 3. Configurar Deep Links (Android)
En `android/app/src/main/AndroidManifest.xml`:
```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme">
    
    <!-- Intent filter existente -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>
    
    <!-- Nuevo intent filter para deep links -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="io.supabase.dondecaigav2" />
    </intent-filter>
</activity>
```

## Código Clave

### Envío de Email de Recuperación
```dart
await supabase.auth.resetPasswordForEmail(
  email,
  redirectTo: 'io.supabase.dondecaigav2://reset-password',
);
```

### Detección Automática del Enlace
```dart
supabase.auth.onAuthStateChange.listen((data) {
  if (data.event == AuthChangeEvent.passwordRecovery) {
    // Redirigir automáticamente a pantalla de nueva contraseña
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => UpdatePasswordScreen()),
    );
  }
});
```

### Actualización de Contraseña
```dart
await supabase.auth.updateUser(
  UserAttributes(password: newPassword),
);
```

## Experiencia de Usuario

### Antes (Sistema Personalizado)
1. Usuario ingresa email
2. Recibe código de 6 dígitos
3. Debe copiar/escribir código manualmente
4. Código expira en 15 minutos
5. Posibles errores de tipeo

### Ahora (Sistema Nativo)
1. Usuario ingresa email
2. Recibe enlace en email
3. Hace clic en enlace
4. App se abre automáticamente
5. Pantalla de nueva contraseña lista
6. Proceso más fluido y seguro

## Pruebas

### Cómo Probar
1. Ir a pantalla de login
2. Tocar "¿Olvidaste tu contraseña?"
3. Ingresar email válido
4. Revisar email (incluyendo spam)
5. Hacer clic en enlace del email
6. Verificar que la app se abre automáticamente
7. Ingresar nueva contraseña
8. Verificar que se puede hacer login con nueva contraseña

### Casos de Prueba
- ✅ Email válido registrado
- ✅ Email no registrado (debe mostrar error)
- ✅ Enlace funciona en dispositivo
- ✅ Nueva contraseña se guarda correctamente
- ✅ Login con nueva contraseña funciona

## Troubleshooting

### Problema: El enlace no abre la app
**Solución**: Verificar configuración de deep links en AndroidManifest.xml

### Problema: Error al actualizar contraseña
**Solución**: Verificar que el usuario esté autenticado después del enlace

### Problema: Email no llega
**Solución**: 
1. Verificar configuración SMTP en Supabase
2. Revisar carpeta de spam
3. Verificar que el email esté registrado

## Configuración de Email (Opcional)

Para emails personalizados, configurar en Supabase:
1. Authentication → Email Templates
2. Personalizar template "Reset Password"
3. Usar variables: `{{ .ConfirmationURL }}`

## Seguridad

### Características de Seguridad
- Enlaces únicos y seguros
- Expiración automática
- No reutilización de enlaces
- Validación del lado del servidor
- Protección contra ataques de fuerza bruta

### Mejores Prácticas
- Usar HTTPS siempre
- Validar entrada del usuario
- Mostrar mensajes de error genéricos
- Logging de intentos de recuperación
- Rate limiting automático por Supabase

## Conclusión

El nuevo sistema es más simple, seguro y ofrece mejor experiencia de usuario. La migración elimina código personalizado complejo y aprovecha la infraestructura robusta de Supabase.