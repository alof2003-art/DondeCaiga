# 🚨 INSTRUCCIONES SIN ERRORES

## 📋 **OPCIÓN 1: SCRIPT MEJORADO (RECOMENDADO)**

1. Ve a Supabase SQL Editor
2. Ejecuta: `docs/CREAR_NOTIFICACIONES_SIMPLE_TODOS.sql`
3. **Si da error:** Pasa a la Opción 2

## 📋 **OPCIÓN 2: SCRIPT BÁSICO (GARANTIZADO)**

1. Ve a Supabase SQL Editor
2. Ejecuta: `docs/SOLO_CREAR_NOTIFICACIONES_BASICO.sql`
3. **Este script es súper básico y no debería dar errores**

## 🔧 **SI QUIERES AGREGAR MÁS USUARIOS MANUALMENTE:**

### **Paso 1: Ver todos tus usuarios**
```sql
SELECT email, id FROM public.users_profiles ORDER BY email;
```

### **Paso 2: Para cada usuario adicional, ejecuta:**
```sql
INSERT INTO public.notifications (user_id, type, title, message, is_read, created_at)
VALUES 
('REEMPLAZA_CON_USER_ID', 'general', 'Notificación Prueba', 'Mensaje de prueba', false, NOW()),
('REEMPLAZA_CON_USER_ID', 'nuevo_mensaje', 'Mensaje Prueba', 'Mensaje de chat de prueba', false, NOW() - INTERVAL '1 hour');
```

## ✅ **RESULTADO ESPERADO**

Después de ejecutar cualquiera de los scripts:
- ✅ **Cada usuario** tendrá **3 notificaciones de prueba**
- ✅ **RLS deshabilitado** para evitar problemas
- ✅ **Notificaciones visibles** en la campana de la app

## 🧪 **PROBAR EN LA APP**

1. Compila la app: `flutter build apk --release`
2. Instala: `flutter install --release`
3. Ve a **Notificaciones** en la app
4. **Resultado esperado:** Debe mostrar las notificaciones de prueba

## 🔍 **VERIFICAR MANUALMENTE**

```sql
-- Ver todas las notificaciones creadas
SELECT 
    up.email,
    n.title,
    n.message,
    n.created_at
FROM notifications n
JOIN users_profiles up ON n.user_id = up.id
ORDER BY up.email, n.created_at DESC;
```

**¡Usa la Opción 2 si la Opción 1 da errores!**