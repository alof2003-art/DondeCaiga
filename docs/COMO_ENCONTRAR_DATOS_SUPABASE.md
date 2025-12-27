# 🔍 CÓMO ENCONTRAR TUS DATOS DE SUPABASE

## 📍 PASO A PASO PARA ENCONTRAR TU URL Y ANON KEY:

### PASO 1: IR A SUPABASE DASHBOARD
1. Ve a **https://supabase.com**
2. **Inicia sesión** con tu cuenta
3. **Selecciona tu proyecto** (donde tienes "Donde Caiga")

### PASO 2: IR A CONFIGURACIÓN
1. En el menú lateral izquierdo, busca **"Settings"** (Configuración)
2. Haz clic en **"API"**

### PASO 3: COPIAR TUS DATOS
En la página de API verás:

#### 🌐 **PROJECT URL:**
```
https://abcdefghijklmnop.supabase.co
```
- Esta es tu URL única del proyecto
- Cada proyecto tiene una diferente

#### 🔑 **ANON/PUBLIC KEY:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprbG1ub3AiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY0NjA2ODAwMCwiZXhwIjoxOTYxNjQ0MDAwfQ.ejemplo-de-clave-larga
```
- Esta es tu clave pública/anon
- Es segura para usar en el frontend

## 🎯 EJEMPLO DE CÓMO SE VE:

En Supabase Dashboard > Settings > API verás algo así:

```
Project URL
https://xyzabc123def456.supabase.co

API Keys
anon/public: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
service_role: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (¡NO uses esta!)
```

## ✅ USAR TUS DATOS REALES:

Una vez que copies tus datos, ejecuta esto en Supabase SQL Editor:

```sql
SELECT configure_supabase_settings(
    'https://TU-URL-REAL.supabase.co',
    'TU-ANON-KEY-REAL'
);
```

### 🔍 EJEMPLO CON DATOS REALES:
```sql
SELECT configure_supabase_settings(
    'https://xyzabc123def456.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh5emFiYzEyM2RlZjQ1NiIsInJvbGUiOiJhbm9uIiwiaWF0IjoxNjQ2MDY4MDAwLCJleHAiOjE5NjE2NDQwMDB9.ejemplo-de-firma-jwt'
);
```

## 🚨 IMPORTANTE:
- ✅ **USA** la clave **anon/public**
- ❌ **NO USES** la clave **service_role** (es muy peligrosa)
- ✅ La URL siempre termina en **.supabase.co**
- ✅ La anon key siempre empieza con **eyJ**

## 🎉 DESPUÉS DE CONFIGURAR:
```sql
-- Verificar que se guardó correctamente
SELECT * FROM test_supabase_config();

-- Probar push notification
SELECT test_push_auto();
```

¡Con estos datos tu sistema de push notifications funcionará automáticamente! 🚀