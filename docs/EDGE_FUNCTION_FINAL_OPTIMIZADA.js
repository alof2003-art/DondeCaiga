// =====================================================
// EDGE FUNCTION FINAL OPTIMIZADA - SISTEMA COMPLETO
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const startTime = Date.now()
  console.log('🚀 Edge Function iniciada - Sistema completo')

  try {
    // Solo permitir POST
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    const { fcm_token, title, body, data } = await req.json()
    console.log('📨 Datos recibidos:', { 
      fcm_token: fcm_token?.substring(0, 20) + '...', 
      title, 
      body,
      data: data || 'sin datos adicionales'
    })

    // Validar parámetros requeridos
    if (!fcm_token || !title || !body) {
      console.error('❌ Faltan parámetros requeridos')
      return new Response(JSON.stringify({ 
        error: 'Missing required fields: fcm_token, title, body' 
      }), {
        status: 400, 
        headers: { 'Content-Type': 'application/json' } 
      })
    }

    // 1. Obtener Service Account
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountJson) {
      console.error('❌ FIREBASE_SERVICE_ACCOUNT no encontrado')
      throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable not found')
    }

    console.log('✅ Service Account encontrado')
    const serviceAccount = JSON.parse(serviceAccountJson)

    // 2. Crear JWT
    const header = { alg: "RS256", typ: "JWT" }
    const now = Math.floor(Date.now() / 1000)
    const payload = {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/cloud-platform",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now
    }

    // Codificar en base64url
    const base64UrlEncode = (obj) => {
      return btoa(JSON.stringify(obj))
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=/g, '')
    }

    const encodedHeader = base64UrlEncode(header)
    const encodedPayload = base64UrlEncode(payload)
    const unsignedToken = `${encodedHeader}.${encodedPayload}`

    // 3. Firmar JWT
    const privateKeyPem = serviceAccount.private_key
    const privateKeyDer = pemToDer(privateKeyPem)
    const cryptoKey = await crypto.subtle.importKey(
      "pkcs8",
      privateKeyDer,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"]
    )

    const encoder = new TextEncoder()
    const dataToSign = encoder.encode(unsignedToken)
    const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", cryptoKey, dataToSign)
    
    const base64Signature = btoa(String.fromCharCode(...new Uint8Array(signature)))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '')

    const jwt = `${unsignedToken}.${base64Signature}`
    console.log('✅ JWT creado y firmado')

    // 4. Obtener access token
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt
      })
    })

    const tokenData = await tokenResponse.json()
    if (!tokenResponse.ok) {
      console.error('❌ Error obteniendo token:', tokenData)
      throw new Error(`Token error: ${JSON.stringify(tokenData)}`)
    }

    console.log('✅ Access token obtenido')

    // 5. Preparar mensaje FCM optimizado
    const message = {
      message: {
        token: fcm_token,
        notification: {
          title: title,
          body: body,
        },
        data: data || {},
        android: {
          notification: {
            channel_id: 'donde_caiga_notifications',
            sound: 'default',
            default_sound: true,
            default_vibrate_timings: true,
            notification_priority: 'PRIORITY_HIGH',
            visibility: 'PUBLIC'
          },
          priority: 'HIGH'
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
        },
        webpush: {
          notification: {
            title: title,
            body: body,
            icon: '/icon-192x192.png',
            badge: '/badge-72x72.png'
          }
        }
      }
    }

    console.log('📤 Enviando a Firebase FCM v1...')

    // 6. Enviar a Firebase
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
    const duration = Date.now() - startTime

    if (firebaseResponse.ok) {
      console.log('🎉 Notificación enviada exitosamente')
      console.log('📊 Duración:', duration + 'ms')
      
      return new Response(JSON.stringify({ 
        success: true, 
        message: 'Push notification sent successfully',
        firebase_response: result,
        duration_ms: duration,
        timestamp: new Date().toISOString()
      }), {
        status: 200, 
        headers: { 'Content-Type': 'application/json' } 
      })
    } else {
      console.error('❌ Error de Firebase:', result)
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'Failed to send push notification',
        firebase_error: result,
        duration_ms: duration
      }), {
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      })
    }

  } catch (error) {
    const duration = Date.now() - startTime
    console.error('💥 Error en Edge Function:', error.message)
    
    return new Response(JSON.stringify({ 
      success: false, 
      error: 'Internal server error',
      details: error.message,
      duration_ms: duration,
      timestamp: new Date().toISOString()
    }), {
      status: 500, 
      headers: { 'Content-Type': 'application/json' } 
    })
  }
})

// Función auxiliar para convertir PEM a DER
function pemToDer(pem) {
  const pemHeader = "-----BEGIN PRIVATE KEY-----"
  const pemFooter = "-----END PRIVATE KEY-----"
  const pemContents = pem.replace(pemHeader, "").replace(pemFooter, "").replace(/\s/g, "")
  const binaryString = atob(pemContents)
  const bytes = new Uint8Array(binaryString.length)
  
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i)
  }
  
  return bytes.buffer
}