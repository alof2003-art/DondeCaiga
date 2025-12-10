# 🔧 Solución: Perfil de Usuario No Se Crea

## 📋 Problema
El usuario se crea en `auth.users` pero NO se crea en la tabla `users_profiles`.

## ✅ Solución: Trigger Automático

Vamos a crear un **trigger** (disparador) que automáticamente cree el perfil cuando se registre un usuario.

### Paso 1: Ejecutar el Script SQL

1. Ve a tu proyecto en [Supabase](https://supabase.com)
2. Abre el **SQL Editor**
3. Copia y pega el contenido del archivo `supabase_trigger_perfil_usuario.sql`
4. Haz clic en **Run** para ejecutar

### Paso 2: Verificar que Funciona

Después de ejecutar el script, prueba registrando un nuevo usuario:

1. Usa un email nuevo (ejemplo: `prueba@test.com`)
2. Completa el registro
3. Ve a Supabase:
   - **Authentication** > **Users** → Deberías ver el usuario
   - **Table Editor** > **users_profiles** → Deberías ver el perfil creado automáticamente

## 🎯 Cómo Funciona

### Antes (❌ No funcionaba):
```
Usuario se registra
    ↓
Se crea en auth.users ✅
    ↓
Supabase cierra la sesión automáticamente
    ↓
La app intenta crear el perfil ❌ (sin permisos porque no hay sesión)
    ↓
El perfil NO se crea en users_profiles
```

### Ahora (✅ Funciona):
```
Usuario se registra
    ↓
Se crea en auth.users ✅
    ↓
TRIGGER automático crea el perfil básico en users_profiles ✅
    ↓
La app actualiza el perfil con datos adicionales (teléfono, fotos) ✅
    ↓
Todo funciona correctamente
```

## 📝 Qué Hace el Trigger

El trigger `trigger_crear_perfil_usuario`:
- Se ejecuta **automáticamente** cuando se crea un usuario en `auth.users`
- Crea un registro en `users_profiles` con:
  - `id`: El mismo ID del usuario
  - `email`: El email del usuario
  - `nombre`: El nombre que se envió en los metadatos (o "Usuario" por defecto)
  - `email_verified`: false (se actualiza cuando verifique el email)

Luego, la aplicación actualiza el perfil con:
- Teléfono
- Foto de perfil
- Cédula

## 🧪 Probar

1. Ejecuta el script SQL del trigger
2. Reinicia la app
3. Registra un nuevo usuario
4. Verifica en Supabase que el perfil se creó en `users_profiles`

## ⚠️ Nota

Si ya tienes usuarios en `auth.users` que no tienen perfil en `users_profiles`, puedes crearlos manualmente ejecutando:

```sql
-- Crear perfiles para usuarios existentes que no tienen perfil
INSERT INTO users_profiles (id, email, nombre, email_verified)
SELECT 
  id,
  email,
  COALESCE(raw_user_meta_data->>'nombre', 'Usuario'),
  email_confirmed_at IS NOT NULL
FROM auth.users
WHERE id NOT IN (SELECT id FROM users_profiles);
```

## 🎉 Resultado

Ahora cuando un usuario se registre:
1. ✅ Se crea en `auth.users`
2. ✅ Se crea automáticamente en `users_profiles` (por el trigger)
3. ✅ Se actualizan los datos adicionales (teléfono, fotos)
4. ✅ Todo funciona correctamente
