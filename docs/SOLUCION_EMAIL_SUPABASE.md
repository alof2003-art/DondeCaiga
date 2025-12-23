# Solución de Email con Supabase Edge Functions

## Problema Actual
- La API key de Resend está dando error 401 "API key is invalid"
- Necesitamos una solución confiable para enviar emails

## Solución Recomendada: Supabase Edge Functions

### Paso 1: Crear Edge Function en Supabase

1. Ve a tu proyecto en Supabase Dashboard
2. Ve a "Edge Functions" en el menú lateral
3. Crea una nueva función llamada `send-email`

### Paso 2: Código de la Edge Function

```javascript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = "re_c1tpEyD8_NKFusih9vKVQknRAQfmFcWCv"

serve(async (req) => {
  const { email, code } = await req.json()

  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${RESEND_API_KEY}`,
    },
    body: JSON.stringify({
      from: 'Acme <onboarding@resend.dev>',
      to: [email],
      subject: 'Código de Recuperación - DondeCaiga',
      html: `
        <h1>Código de Recuperación</h1>
        <p>Tu código es: <strong>${code}</strong></p>
        <p>Este código expira en 15 minutos.</p>
      `,
    }),
  })

  const data = await res.json()
  
  return new Response(
    JSON.stringify(data),
    { headers: { "Content-Type": "application/json" } },
  )
})
```

### Paso 3: Actualizar el código Flutter

Cambiar el método `sendResetCodeEmail` para usar la Edge Function en lugar de llamar directamente a Resend.

## Alternativa Más Simple: Usar Gmail SMTP

Si prefieres una solución más directa, podemos configurar Gmail SMTP:

1. Crear una contraseña de aplicación en Gmail
2. Usar el paquete `mailer` de Flutter
3. Configurar SMTP con Gmail

¿Cuál prefieres implementar?