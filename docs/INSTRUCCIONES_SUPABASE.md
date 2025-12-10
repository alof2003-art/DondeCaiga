# 🔧 Instrucciones para Corregir Errores de Supabase

## Problema
Estás recibiendo errores 403 (Unauthorized) porque las políticas de seguridad (RLS) están bloqueando las operaciones.

## Solución Paso a Paso

### 1. Ejecutar Script SQL de Corrección

1. Ve a tu proyecto en [Supabase](https://supabase.com)
2. Abre el **SQL Editor**
3. Copia y pega el contenido del archivo `supabase_fix_policies.sql`
4. Haz clic en **Run** para ejecutar el script

### 2. Configurar Buckets de Storage

#### Para profile-photos:
1. Ve a **Storage** en el menú lateral
2. Haz clic en el bucket **profile-photos**
3. Haz clic en el ícono de configuración (⚙️)
4. En "Public bucket", **MARCA** la casilla para hacerlo público
5. Guarda los cambios

#### Para id-documents:
1. Haz clic en el bucket **id-documents**
2. Haz clic en el ícono de configuración (⚙️)
3. En "Public bucket", **MARCA** la casilla para hacerlo público
4. Guarda los cambios

### 3. Verificar Configuración de Email

El error "over_email_send_rate_limit" significa que has intentado registrarte muchas veces.

**Opciones:**
- **Opción A (Recomendada)**: Espera 1 minuto antes de intentar registrarte de nuevo
- **Opción B**: Usa un email diferente para probar
- **Opción C**: Desactiva temporalmente la confirmación de email:
  1. Ve a **Authentication** > **Settings**
  2. Busca "Email Auth"
  3. **DESMARCA** "Enable email confirmations"
  4. Guarda los cambios

### 4. Limpiar Usuarios de Prueba (Opcional)

Si has creado muchos usuarios de prueba:
1. Ve a **Authentication** > **Users**
2. Elimina los usuarios que no necesites
3. Esto liberará los emails para volver a usarlos

### 5. Probar de Nuevo

Después de hacer estos cambios:
1. Cierra y vuelve a abrir la aplicación
2. Intenta registrarte con un nuevo email
3. Si desactivaste la confirmación de email, podrás iniciar sesión inmediatamente

## 🔍 Verificación

Para verificar que todo está bien configurado, ejecuta estas consultas en el SQL Editor:

```sql
-- Ver políticas de users_profiles
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'users_profiles';

-- Ver configuración de buckets
SELECT name, public FROM storage.buckets WHERE name IN ('profile-photos', 'id-documents');
```

## ⚠️ Nota de Seguridad

Las políticas que creamos son más permisivas para facilitar el desarrollo. En producción, deberías:
- Hacer los buckets privados de nuevo
- Usar políticas más restrictivas que verifiquen que cada usuario solo acceda a sus propios archivos
- Implementar validación de tamaño y tipo de archivo en el servidor

## 📞 Si Sigues Teniendo Problemas

1. Verifica que los buckets existan (profile-photos y id-documents)
2. Verifica que RLS esté habilitado en la tabla users_profiles
3. Verifica que tu SUPABASE_ANON_KEY sea correcta en el archivo .env
4. Revisa los logs en Supabase: **Logs** > **Postgres Logs**
