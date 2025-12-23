// Archivo: supabase/functions/send-password-reset/index.ts
// Este archivo se crea en tu proyecto Supabase

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { email, code } = await req.json()

    // Validar parámetros
    if (!email || !code) {
      throw new Error('Email y código son requeridos')
    }

    // Enviar email usando Resend
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: 'DondeCaiga <noreply@tudominio.com>', // Cambiar por tu dominio
        to: [email],
        subject: 'Código de Recuperación - DondeCaiga',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #4DB6AC;">Recuperación de Contraseña</h2>
            <p>Hola,</p>
            <p>Recibimos una solicitud para restablecer tu contraseña. Tu código de verificación es:</p>
            
            <div style="background-color: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px;">
              <h1 style="color: #4DB6AC; font-size: 32px; margin: 0; letter-spacing: 4px;">${code}</h1>
            </div>
            
            <p><strong>Este código expira en 15 minutos.</strong></p>
            
            <p>Si no solicitaste este cambio, puedes ignorar este email.</p>
            
            <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
            <p style="color: #666; font-size: 12px;">
              Este es un email automático, por favor no respondas a este mensaje.
            </p>
          </div>
        `,
      }),
    })

    if (!res.ok) {
      const error = await res.text()
      throw new Error(`Error enviando email: ${error}`)
    }

    const data = await res.json()
    
    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Email enviado correctamente',
        id: data.id 
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})