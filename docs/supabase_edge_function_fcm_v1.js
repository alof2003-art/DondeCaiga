// =====================================================
// EDGE FUNCTION PARA FIREBASE CLOUD MESSAGING API V1
// =====================================================
// Archivo: supabase/functions/send-push-notification/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { JWT } from "https://esm.sh/google-auth-library@9.0.0"

serve(async (req) => {
  try {
    // Solo permitir POST
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    const { fcm_token, title, body } = await req.json()

    // Validar parámetros requeridos
    if (!fcm_token || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: fcm_token, title, body' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 1. Obtener el JSON desde el Secret
    const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '{}')

    // 2. Generar el Token de acceso automático de Google
    const jwtClient = new JWT(
      serviceAccount.client_email,
      null,
      serviceAccount.private_key,
      ['https://www.googleapis.com/auth/cloud-platform']
    )
    const credentials = await jwtClient.authorize()

    // 3. Preparar mensaje optimizado para bandeja del sistema
    const message = {
      message: {
        token: fcm_token,
        notification: {
          title: title,
          body: body,
        },
        data: {
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          sound: 'default'
        },
        android: {
          notification: {
            channel_id: 'donde_caiga_notifications',
            priority: 'HIGH',
            default_sound: true,
            default_vibrate_timings: true,
            icon: 'ic_notification',
            color: '#4CAF50',
            // IMPORTANTE: Estas configuraciones hacen que aparezca en la bandeja
            notification_priority: 'PRIORITY_HIGH',
            visibility: 'PUBLIC'
          },
          // Configuración para que funcione en background
          priority: 'HIGH',
          data: {
            click_action: 'FLUTTER_NOTIFICATION_CLICK'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              alert: {
                title: title,
                body: body
              },
              'content-available': 1
            }
          }
        }
      }
    }

    // 4. Enviar a Firebase FCM v1
    const firebaseResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/donde-caiga-notifications/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${credentials.access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(message)
      }
    )

    const result = await firebaseResponse.json()

    if (firebaseResponse.ok) {
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'Push notification sent successfully',
          firebase_response: result
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    } else {
      console.error('Firebase error:', result)
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Failed to send push notification',
          firebase_error: result
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