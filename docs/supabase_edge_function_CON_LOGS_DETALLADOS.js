// =====================================================
// EDGE FUNCTION CON LOGS SÚPER DETALLADOS PARA DEBUG
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const startTime = Date.now()
  console.log('🚀🚀🚀 ===== EDGE FUNCTION INICIADA =====')
  console.log('⏰ Timestamp:', new Date().toISOString())
  console.log('🌐 Method:', req.method)
  console.log('📍 URL:', req.url)
  console.log('📋 Headers:', Object.fromEntries(req.headers.entries()))

  try {
    // Solo permitir POST
    if (req.method !== 'POST') {
      console.log('❌ Method not allowed:', req.method)
      return new Response('Method not allowed', { status: 405 })
    }

    console.log('✅ Method POST confirmado')

    // Leer el body
    console.log('📖 Leyendo request body...')
    const requestText = await req.text()
    console.log('📄 Raw request body:', requestText)

    let requestData
    try {
      requestData = JSON.parse(requestText)
      console.log('✅ JSON parseado correctamente:', requestData)
    } catch (parseError) {
      console.error('❌ Error parseando JSON:', parseError)
      return new Response(JSON.stringify({ 
        error: 'Invalid JSON', 
        details: parseError.message,
        received: requestText 
      }), {
        status: 400, 
        headers: { 'Content-Type': 'application/json' } 
      })
    }

    const { fcm_token, title, body } = requestData
    console.log('📨 Datos extraídos:')
    console.log('  - fcm_token:', fcm_token ? fcm_token.substring(0, 20) + '...' : 'MISSING')
    console.log('  - title:', title || 'MISSING')
    console.log('  - body:', body || 'MISSING')

    // Validar parámetros requeridos
    if (!fcm_token || !title || !body) {
      console.error('❌ Faltan parámetros requeridos')
      console.error('  - fcm_token presente:', !!fcm_token)
      console.error('  - title presente:', !!title)
      console.error('  - body presente:', !!body)
      
      return new Response(JSON.stringify({ 
        error: 'Missing required fields: fcm_token, title, body',
        received: { fcm_token: !!fcm_token, title: !!title, body: !!body }
      }), {
        status: 400, 
        headers: { 'Content-Type': 'application/json' } 
      })
    }

    console.log('✅ Todos los parámetros presentes')

    // 1. Obtener el JSON desde el Secret
    console.log('🔑 Obteniendo FIREBASE_SERVICE_ACCOUNT...')
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    
    if (!serviceAccountJson) {
      console.error('❌ FIREBASE_SERVICE_ACCOUNT no encontrado en variables de entorno')
      console.error('📋 Variables disponibles:', Object.keys(Deno.env.toObject()))
      throw new Error('FIREBASE_SERVICE_ACCOUNT environment variable not found')
    }

    console.log('✅ Service Account encontrado, longitud:', serviceAccountJson.length)

    let serviceAccount
    try {
      serviceAccount = JSON.parse(serviceAccountJson)
      console.log('✅ Service Account parseado correctamente')
      console.log('📧 Client email:', serviceAccount.client_email)
      console.log('🆔 Project ID:', serviceAccount.project_id)
      console.log('🔑 Private key presente:', !!serviceAccount.private_key)
    } catch (parseError) {
      console.error('❌ Error parseando Service Account JSON:', parseError)
      throw new Error('Invalid FIREBASE_SERVICE_ACCOUNT JSON')
    }

    // 2. Crear JWT
    console.log('🔐 Creando JWT...')
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

    console.log('📋 JWT Payload:', payload)

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

    console.log('✅ JWT sin firmar creado, longitud:', unsignedToken.length)

    // Importar clave privada
    console.log('🔑 Importando clave privada...')
    const privateKeyPem = serviceAccount.private_key
    console.log('🔑 Private key longitud:', privateKeyPem.length)

    const privateKeyDer = pemToDer(privateKeyPem)
    console.log('✅ PEM convertido a DER')

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
    console.log('✅ Clave criptográfica importada')

    // Firmar
    console.log('✍️ Firmando JWT...')
    const encoder = new TextEncoder()
    const data = encoder.encode(unsignedToken)
    const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", cryptoKey, data)
    
    const base64Signature = btoa(String.fromCharCode(...new Uint8Array(signature)))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=/g, '')

    const jwt = `${unsignedToken}.${base64Signature}`
    console.log('✅ JWT firmado correctamente, longitud total:', jwt.length)

    // 3. Obtener access token
    console.log('🔄 Solicitando access token a Google...')
    const tokenRequestBody = new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt
    })

    console.log('📤 Token request body:', tokenRequestBody.toString())

    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: tokenRequestBody
    })

    console.log('📥 Token response status:', tokenResponse.status)
    console.log('📥 Token response headers:', Object.fromEntries(tokenResponse.headers.entries()))

    const tokenData = await tokenResponse.json()
    console.log('📥 Token response data:', tokenData)

    if (!tokenResponse.ok) {
      console.error('❌ Error obteniendo token de Google')
      console.error('📄 Response:', tokenData)
      throw new Error(`Token error: ${JSON.stringify(tokenData)}`)
    }

    console.log('✅ Access token obtenido exitosamente')
    console.log('🔑 Token type:', tokenData.token_type)
    console.log('⏱️ Expires in:', tokenData.expires_in)

    // 4. Preparar mensaje FCM
    console.log('📝 Preparando mensaje FCM...')
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

    console.log('📋 Mensaje FCM preparado:', JSON.stringify(message, null, 2))

    // 5. Enviar a Firebase FCM v1
    const firebaseUrl = `https://fcm.googleapis.com/v1/projects/donde-caiga-notifications/messages:send`
    console.log('🚀 Enviando a Firebase URL:', firebaseUrl)

    const firebaseHeaders = {
      'Authorization': `Bearer ${tokenData.access_token}`,
      'Content-Type': 'application/json',
    }
    console.log('📋 Firebase headers:', firebaseHeaders)

    const firebaseBody = JSON.stringify(message)
    console.log('📄 Firebase body length:', firebaseBody.length)

    const firebaseResponse = await fetch(firebaseUrl, {
      method: 'POST',
      headers: firebaseHeaders,
      body: firebaseBody
    })

    console.log('📥 Firebase response status:', firebaseResponse.status)
    console.log('📥 Firebase response headers:', Object.fromEntries(firebaseResponse.headers.entries()))

    const result = await firebaseResponse.json()
    console.log('📥 Firebase response data:', JSON.stringify(result, null, 2))

    const endTime = Date.now()
    const duration = endTime - startTime
    console.log('⏱️ Duración total:', duration + 'ms')

    if (firebaseResponse.ok) {
      console.log('🎉🎉🎉 ===== NOTIFICACIÓN ENVIADA EXITOSAMENTE =====')
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
      console.error('💥💥💥 ===== ERROR DE FIREBASE =====')
      console.error('📄 Error details:', result)
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'Failed to send push notification',
        firebase_error: result,
        duration_ms: duration,
        timestamp: new Date().toISOString()
      }), {
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      })
    }

  } catch (error) {
    const endTime = Date.now()
    const duration = endTime - startTime
    
    console.error('💥💥💥 ===== ERROR GENERAL EN EDGE FUNCTION =====')
    console.error('❌ Error message:', error.message)
    console.error('❌ Error stack:', error.stack)
    console.error('⏱️ Duración hasta error:', duration + 'ms')
    
    return new Response(JSON.stringify({ 
      success: false, 
      error: 'Internal server error',
      details: error.message,
      stack: error.stack,
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
  console.log('🔄 Convirtiendo PEM a DER...')
  const pemHeader = "-----BEGIN PRIVATE KEY-----"
  const pemFooter = "-----END PRIVATE KEY-----"
  const pemContents = pem.replace(pemHeader, "").replace(pemFooter, "").replace(/\s/g, "")
  
  console.log('📏 PEM contents length:', pemContents.length)
  
  const binaryString = atob(pemContents)
  const bytes = new Uint8Array(binaryString.length)
  
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i)
  }
  
  console.log('✅ DER conversion completed, bytes length:', bytes.length)
  return bytes.buffer
}