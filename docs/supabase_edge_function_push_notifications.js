// Edge Function para enviar notificaciones push via Firebase FCM
// Archivo: supabase/functions/send-push-notification/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Manejar preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Obtener datos de la notificación
    const { 
      fcmToken, 
      titulo, 
      mensaje, 
      tipo,
      datos = {},
      usuarioId 
    } = await req.json()

    console.log('📨 Enviando notificación push:', { titulo, mensaje, tipo, usuarioId })

    // Validar que tenemos los datos necesarios
    if (!fcmToken || !titulo || !mensaje) {
      throw new Error('Faltan datos requeridos: fcmToken, titulo, mensaje')
    }

    // Configurar el payload para FCM
    const fcmPayload = {
      to: fcmToken,
      notification: {
        title: titulo,
        body: mensaje,
        icon: 'ic_launcher',
        sound: 'default',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      data: {
        tipo: tipo || 'general',
        usuario_id: usuarioId || '',
        datos: JSON.stringify(datos),
        timestamp: new Date().toISOString(),
      },
      android: {
        notification: {
          channel_id: 'donde_caiga_notifications',
          priority: 'high',
          default_sound: true,
          default_vibrate_timings: true,
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          }
        }
      }
    }

    // Obtener la clave del servidor FCM desde las variables de entorno
    const fcmServerKey = Deno.env.get('FCM_SERVER_KEY')
    if (!fcmServerKey) {
      throw new Error('FCM_SERVER_KEY no está configurada en las variables de entorno')
    }

    // Enviar la notificación a Firebase FCM
    const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${fcmServerKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(fcmPayload),
    })

    const fcmResult = await fcmResponse.json()
    
    console.log('📤 Respuesta de FCM:', fcmResult)

    // Verificar si la notificación se envió correctamente
    if (fcmResult.success === 1) {
      console.log('✅ Notificación enviada exitosamente')
      
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'Notificación enviada exitosamente',
          fcmResult 
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        },
      )
    } else {
      console.log('❌ Error al enviar notificación:', fcmResult)
      
      return new Response(
        JSON.stringify({ 
          success: false, 
          error: 'Error al enviar notificación',
          fcmResult 
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        },
      )
    }

  } catch (error) {
    console.error('❌ Error en edge function:', error.message)
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: error.message 
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      },
    )
  }
})

/* 
INSTRUCCIONES PARA DESPLEGAR:

1. Instalar Supabase CLI:
   npm install -g supabase

2. Inicializar proyecto (si no está hecho):
   supabase init

3. Crear la función:
   supabase functions new send-push-notification

4. Copiar este código a:
   supabase/functions/send-push-notification/index.ts

5. Configurar la clave FCM:
   supabase secrets set FCM_SERVER_KEY=tu_clave_fcm_aqui

6. Desplegar la función:
   supabase functions deploy send-push-notification

7. La URL será:
   https://tu-proyecto.supabase.co/functions/v1/send-push-notification
*/