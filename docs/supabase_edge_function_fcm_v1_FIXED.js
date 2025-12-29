// =====================================================
// EDGE FUNCTION PARA FIREBASE CLOUD MESSAGING API V1 - SIMPLE
// =====================================================
// Archivo: supabase/functions/send-push-notification/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    // Solo permitir POST
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    const { fcm_token, title, body } = await req.json()

    // Validar parámetros requeridos
    if (!fcm_token || !title || !body) {
      return new Response(JSON.stringify({ 
        error: 'Missing required fields: fcm_token, title, body' 
      }), {
        status: 400, 
        headers: { 'Content-Type': 'application/json' } 
      })
    }

    // 1. Obtener el JSON desde el Secret
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable not found')
    }

    const serviceAccount = JSON.parse(serviceAccountJson)

    // 2. Usar la librería JWT compatible con Deno
    const { create, getNumericDate } = await import("https://deno.land/x/djwt@v3.0.1/mod.ts")

    // 3. Crear JWT payload
    const payload = {
      iss: serviceAccount.client_email,
      scope: 'https://www.googleapis.com/auth/cloud-platform',
      aud: 'https://oauth2.googleapis.com/token',
      exp: getNumericDate(60 * 60), // 1 hora
      iat: getNumericDate(0)
    }

    // 4. Crear JWT
    const jwt = await create(
      { alg: "RS256", typ: "JWT" },
      payload,
      serviceAccount.private_key
    )

    // 5. Obtener access token
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt
      })
    })

    const tokenData = await tokenResponse.json()
    
    if (!tokenResponse.ok) {
      throw new Error(`Token error: ${JSON.stringify(tokenData)}`)
    }

    // 6. Preparar mensaje optimizado para bandeja del sistema
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
            notification_priority: 'PRIORITY_HIGH',
            visibility: 'PUBLIC'
          },
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

    // 7. Enviar a Firebase FCM v1
    const firebaseResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/donde-caiga-notifications/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${tokenData.access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(message)
      }
    )

    const result = await firebaseResponse.json()

    if (firebaseResponse.ok) {
      return new Response(JSON.stringify({ 
        success: true, 
        message: 'Push notification sent successfully',
        firebase_response: result
      }), {
        status: 200, 
        headers: { 'Content-Type': 'application/json' } 
      })
    } else {
      console.error('Firebase error:', result)
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'Failed to send push notification',
        firebase_error: result
      }), {
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      })
    }

  } catch (error) {
    console.error('Edge function error:', error)
    return new Response(JSON.stringify({ 
      success: false, 
      error: 'Internal server error',
      details: error.message
    }), {
      status: 500, 
      headers: { 'Content-Type': 'application/json' } 
    })
  }
})