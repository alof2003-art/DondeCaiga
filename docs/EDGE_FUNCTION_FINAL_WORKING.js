// =====================================================
// EDGE FUNCTION SIMPLE QUE FUNCIONA - SIN LIBRERÍAS EXTERNAS
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    console.log('🚀 Edge Function iniciada')
    
    // Solo permitir POST
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    const { fcm_token, title, body } = await req.json()
    console.log('📨 Datos recibidos:', { 
      fcm_token: fcm_token?.substring(0, 20) + '...', 
      title, 
      body 
    })

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
      console.error('❌ FIREBASE_SERVICE_ACCOUNT no encontrado')
      throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable not found')
    }
    console.log('✅ Service Account encontrado')

    const serviceAccount = JSON.parse(serviceAccountJson)

    // 2. Crear JWT usando una librería más simple
    const header = {
      alg: "RS256",
      typ: "JWT"
    }

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

    console.log('🔑 JWT creado, firmando...')

    // Importar clave privada
    const privateKeyPem = serviceAccount.private_key
    const privateKeyDer = pemToDer(privateKeyPem)

    const cryptoKey = await crypto.subtle.importKey(
      "pkcs8",
      privateKeyDer,
      {
        name: "RSASSA-PKCS1-v1_5",
        hash: "SHA-256",
      },
      false,
      ["sign"]
    )

    // Firmar
    const encoder = new TextEncoder()
    const data = encoder.encode(unsignedToken)
    const signature = await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5", 
      cryptoKey, 
      data
    )

    const base64Signature = btoa(String.fromCharCode(...new Uint8Array(signature)))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '')

    const jwt = `${unsignedToken}.${base64Signature}`
    console.log('✅ JWT firmado correctamente')

    // 3. Obtener access token
    console.log('🔄 Obteniendo access token...')
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
      console.error('❌ Error obteniendo token:', tokenData)
      throw new Error(`Token error: ${JSON.stringify(tokenData)}`)
    }
    console.log('✅ Access token obtenido')

    // 4. Preparar mensaje FCM (formato correcto)
    const message = {
      message: {
        token: fcm_token,
        notification: {
          title: title,
          body: body,
        },
        android: {
          notification: {
            channel_id: 'donde_caiga_notifications',
            sound: 'default',
            default_sound: true,
            default_vibrate_timings: true,
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
              }
            }
          }
        }
      }
    }

    console.log('📤 Enviando a Firebase...')

    // 5. Enviar a Firebase FCM v1
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
    console.log('📨 Respuesta de Firebase:', result)

    if (firebaseResponse.ok) {
      console.log('✅ Notificación enviada exitosamente')
      return new Response(JSON.stringify({ 
        success: true, 
        message: 'Push notification sent successfully',
        firebase_response: result
      }), {
        status: 200, 
        headers: { 'Content-Type': 'application/json' } 
      })
    } else {
      console.error('❌ Error de Firebase:', result)
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
    console.error('❌ Error en Edge Function:', error)
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

// Función auxiliar para convertir PEM a DER
function pemToDer(pem) {
  const pemHeader = "-----BEGIN PRIVATE KEY-----"
  const pemFooter = "-----END PRIVATE KEY-----"
  const pemContents = pem
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s/g, "")
  
  const binaryString = atob(pemContents)
  const bytes = new Uint8Array(binaryString.length)
  
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i)
  }
  
  return bytes.buffer
}