# 🔍 CÓMO ENCONTRAR TUS DATOS DE SUPABASE

**Necesitas:** PROJECT_ID y ANON_KEY para que el trigger funcione

---

## 🎯 **PASO 1: ENCONTRAR PROJECT_ID**

### **Opción A: Desde la URL**
Cuando estás en tu dashboard de Supabase, la URL se ve así:
```
https://supabase.com/dashboard/project/abcdefghijklmnop
                                      ^^^^^^^^^^^^^^^^
                                      Este es tu PROJECT_ID
```

### **Opción B: Desde Settings**
1. Ve a tu **Supabase Dashboard**
2. **Settings** (⚙️) → **General**
3. Busca **"Reference ID"**
4. Copia el ID (ejemplo: `abcdefghijklmnop`)

---

## 🔑 **PASO 2: ENCONTRAR ANON_KEY**

1. Ve a tu **Supabase Dashboard**
2. **Settings** (⚙️) → **API**
3. En **"Project API keys"**
4. Copia **"anon / public"** key
5. Es una clave larga que empieza con `eyJ...`

**Ejemplo:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYzNjU0ODAwMCwiZXhwIjoxOTUyMTI0MDAwfQ.ejemplo123456789
```

---

## 🚀 **PASO 3: USAR LOS DATOS**

Con tus datos reales, el trigger se vería así:

```sql
CREATE OR REPLACE FUNCTION send_push_notification_on_insert()
RETURNS TRIGGER AS $$
DECLARE
    fcm_token_var TEXT;
    project_url TEXT := 'https://abcdefghijklmnop.supabase.co';  -- 👈 TU PROJECT_ID
    anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';  -- 👈 TU ANON_KEY
BEGIN
    -- Resto del código...
```

---

## ✅ **VERIFICACIÓN RÁPIDA**

### **URL completa debe ser:**
```
https://TU_PROJECT_ID.supabase.co/functions/v1/send-push-notification
```

### **Ejemplo real:**
```
https://abcdefghijklmnop.supabase.co/functions/v1/send-push-notification
```

### **Para probar que la URL funciona:**
1. Abre esa URL en el navegador
2. Debería dar error 405 (Method Not Allowed)
3. Eso significa que la URL existe y funciona

---

## 🎯 **PRÓXIMOS PASOS**

1. **Encuentra** tu PROJECT_ID y ANON_KEY
2. **Edita** el archivo `RECREAR_TRIGGER_CORRECTO.sql`
3. **Reemplaza** TU_PROJECT_ID y TU_ANON_KEY con tus datos reales
4. **Ejecuta** el script en Supabase SQL Editor
5. **Prueba** insertando una notificación

**¡Una vez que tengas estos datos, el trigger debería funcionar correctamente!** 🚀