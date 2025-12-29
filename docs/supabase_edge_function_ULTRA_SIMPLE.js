// =====================================================
// EDGE FUNCTION ULTRA SIMPLE - BASADO EN DOCS DE SUPABASE
// =====================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    console.log('🚀 Edge Function iniciada')
    
    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    const { fcm_token, title, body } = await req.json()
    console.log('📨 Datos recibidos:', { title, body })

    if (!fcm_token || !title || !body) {
      return new Response(JSON.stringify({ 
        error: 'Missing required fields' 
      }), {
        status: 400, 
        headers: { 'Content-Type': 'application/json' } 
      })
    }

    // Obtener service account
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT not found')
    }

    const serviceAccount = JSON.parse(serviceAccountJson)
    console.log('✅ Service Account cargado')

    // Crear JWT simple
    const now = Math.floor(Date.now() / 1000)
    const payload = {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/cloud-platform",
      aud: "https://oauth2.googleapis.com/token",
      exp: now + 3600,
      iat: now
    }

    // Usar Web Crypto API para JWT
    const header = { alg: "RS256", typ: "JWT" }
    
    const encode = (obj) => btoa(JSON.stringify(obj))
      .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
    
    const headerEncoded = encode(header)
    const payloadEncoded = encode(payload)
    const unsignedToken = `${headerEncoded}.${payloadEncoded}`

    // Convertir PEM a formato crypto
    const pemHeader = "-----BEGIN PRIVATE KEY-----"
    const pemFooter = "-----END PRIVATE KEY-----"
    const pemContents = serviceAccount.private_key
      .replace(pemHeader, "")
      .replace(pemFooter, "")
      .replace(/\s/g, "")
    
    const binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0))
    
    const cryptoKey = await crypto.subtle.importKey(
      "pkcs8",
      binaryDer,
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"]
    )

    const signature = await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      cryptoKey,
      new TextEncoder().encode(unsignedToken)
    )

    const signatureEncoded = btoa(String.fromCharCode(...new Uint8Array(signature)))
      .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')

    const jwt = `${unsignedToken}.${signatureEncoded}`
    console.log('✅ JWT creado')

    // Obtener access token
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
      throw new Error(`Token error: ${JSON.stringify(tokenData)}`)
    }
    console.log('✅ Access token obtenido')

    // Mensaje FCM ultra simple
    const message = {
      message: {
        token: fcm_token,
        notification: {
          title: title,
          body: body
        }
      }
    }

    console.log('📤 Enviando a Firebase...')

    // Enviar a Firebase
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
    console.log('📨 Respuesta Firebase:', result)

    if (firebaseResponse.ok) {
      console.log('✅ ¡NOTIFICACIÓN ENVIADA EXITOSAMENTE!')
      return new Response(JSON.stringify({ 
        success: true, 
        message: 'Push notification sent successfully',
        firebase_response: result
      }), {
        status: 200, 
        headers: { 'Content-Type': 'application/json' } 
      })
    } else {
      console.error('❌ Error Firebase:', result)
      return new Response(JSON.stringify({ 
        success: false, 
        error: 'Firebase error',
        firebase_error: result
      }), {
        status: 500, 
        headers: { 'Content-Type': 'application/json' } 
      })
    }

  } catch (error) {
    console.error('❌ Error general:', error)
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