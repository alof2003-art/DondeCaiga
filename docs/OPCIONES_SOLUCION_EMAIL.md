# Opciones para Solucionar el Problema de Email

## Problema Actual
La API key de Resend está dando error 401 "API key is invalid". Necesitamos una solución confiable para enviar emails de recuperación de contraseña.

## Opción 1: Verificar y Corregir Resend (Recomendada)

### Pasos:
1. **Verificar tu cuenta de Resend:**
   - Ve a https://resend.com/dashboard
   - Verifica que tu cuenta esté activa
   - Revisa si hay límites excedidos

2. **Generar nueva API key:**
   - Ve a "API Keys" en tu dashboard
   - Elimina la API key actual si existe
   - Crea una nueva API key
   - Copia el token completo

3. **Verificar dominio:**
   - En Resend, ve a "Domains"
   - Si no tienes dominio propio, usa `onboarding@resend.dev`
   - Si tienes dominio, verifica que esté configurado

### Ventajas:
- ✅ Servicio profesional y confiable
- ✅ 3,000 emails gratis al mes
- ✅ Buena deliverability
- ✅ API simple

## Opción 2: EmailJS (Más Simple)

### Pasos:
1. Crear cuenta en https://www.emailjs.com/
2. Configurar servicio de email (Gmail, Outlook, etc.)
3. Crear template de email
4. Usar la librería emailjs en Flutter

### Ventajas:
- ✅ Muy fácil de configurar
- ✅ 200 emails gratis al mes
- ✅ No requiere backend
- ✅ Funciona desde el frontend

### Código ejemplo:
```dart
// Agregar dependencia: emailjs: ^4.0.0
await EmailJS.send(
  'service_id',
  'template_id',
  {
    'to_email': email,
    'reset_code': code,
  },
  const Options(
    publicKey: 'tu_public_key',
    privateKey: 'tu_private_key',
  ),
);
```

## Opción 3: Supabase Edge Functions

### Pasos:
1. Crear Edge Function en Supabase
2. Configurar Resend dentro de la función
3. Llamar la función desde Flutter

### Ventajas:
- ✅ Integrado con Supabase
- ✅ Más seguro (API keys en servidor)
- ✅ Escalable

## Opción 4: Gmail SMTP (Para desarrollo)

### Pasos:
1. Configurar contraseña de aplicación en Gmail
2. Usar paquete `mailer` de Flutter
3. Configurar SMTP

### Ventajas:
- ✅ Gratis
- ✅ Fácil para desarrollo
- ❌ No recomendado para producción

## Recomendación

**Para resolver rápido:** Usar EmailJS (Opción 2)
**Para producción:** Corregir Resend (Opción 1) o usar Supabase Edge Functions (Opción 3)

¿Cuál prefieres implementar?