// =====================================================
// EDGE FUNCTION PARA ENVIAR NOTIFICACIONES PUSH
// =====================================================
// Archivo: supabase/functions/send-push-notification/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const FIREBASE_SERVER_KEY = Deno.env.get('FIREBASE_SERVER_KEY')
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')

serve(async (req) => {
  try {
    // Solo permitir POST requests
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    const { fcm_token, title, body, data = {} } = await req.json()

    // Validar parámetros requeridos
    if (!fcm_token || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: fcm_token, title, body' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Preparar el payload para Firebase
    const firebasePayload = {
      to: fcm_token,
      notification: {
        title: title,
        body: body,
        icon: '/icon-192x192.png', // Ícono de tu app
        badge: '/icon-192x192.png',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        sound: 'default'
      },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        notification: {
          channel_id: 'donde_caiga_notifications',
          priority: 'high',
          default_sound: true,
          default_vibrate_timings: true
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    }

    // Enviar a Firebase Cloud Messaging
    const firebaseResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${FIREBASE_SERVER_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(firebasePayload)
    })

    const firebaseResult = await firebaseResponse.json()

    // Verificar si fue exitoso
    if (firebaseResponse.ok && firebaseResult.success === 1) {
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'Push notification sent successfully',
          firebase_response: firebaseResult
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    } else {
      console.error('Firebase error:', firebaseResult)
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Failed to send push notification',
          firebase_error: firebaseResult
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

  } catch (error) {
    console.error('Edge function error:', error)
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: 'Internal server error',
        details: error.message
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})

/* 
INSTRUCCIONES PARA CONFIGURAR:

1. En Supabase Dashboard > Edge Functions, crear nueva función llamada "send-push-notification"

2. Copiar este código al archivo index.ts

3. Configurar las variables de entorno en Supabase:
   - FIREBASE_SERVER_KEY: Tu clave del servidor de Firebase
   - FIREBASE_PROJECT_ID: Tu ID del proyecto de Firebase

4. Desplegar la función:
   supabase functions deploy send-push-notification

5. Probar la función:
   curl -X POST 'https://tu-proyecto.supabase.co/functions/v1/send-push-notification' \
   -H 'Authorization: Bearer tu-anon-key' \
   -H 'Content-Type: application/json' \
   -d '{
     "fcm_token": "tu-fcm-token",
     "title": "Prueba",
     "body": "Mensaje de prueba"
   }'
*/