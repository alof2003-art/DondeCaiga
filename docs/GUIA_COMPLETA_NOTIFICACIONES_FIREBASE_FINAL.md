# 🔥 GUÍA COMPLETA PARA PROBAR NOTIFICACIONES FIREBASE

## 📱 **PASO 1: INSTALAR LA APP**

Cuando conectes tu teléfono TECNO LI7:

```bash
flutter install --release
```

La APK ya está compilada en: `build\app\outputs\flutter-apk\app-release.apk`

---

## 🧪 **PASO 2: USAR EL WIDGET DE PRUEBA**

### **Ubicación del Test:**
1. Abre la app
2. Ve a **Notificaciones** (ícono de campana en la barra inferior)
3. Selecciona la pestaña **"Test FCM"**

### **Qué verás:**
- ✅ Estado de permisos
- ✅ Estado del servicio Firebase
- 🔑 **Token FCM completo** (para copiar)
- 📋 Botón para copiar el token
- 🔄 Botón para actualizar estado

---

## 🔥 **PASO 3: PROBAR DESDE FIREBASE CONSOLE**

### **3.1 Ir a Firebase Console:**
1. Ve a: https://console.firebase.google.com/
2. Selecciona tu proyecto: **"donde-caiga-notifications"**
3. Ve a **Messaging** en el menú lateral

### **3.2 Crear Campaña de Prueba:**
1. Clic en **"Create your first campaign"** o **"New campaign"**
2. Selecciona **"Firebase Notification messages"**
3. Clic en **"Send test message"**

### **3.3 Configurar el Mensaje:**
```
Título: Prueba Firebase
Mensaje: Esta es una notificación de prueba desde Firebase Console
```

### **3.4 Agregar Token:**
1. En **"Add an FCM registration token"**
2. Pega el token que copiaste de la app
3. Clic en **"Test"**

---

## 📋 **PASO 4: VERIFICAR QUE FUNCIONA**

### **✅ Escenarios de Prueba:**

#### **Prueba 1: App Cerrada**
1. Cierra completamente la app
2. Envía notificación desde Firebase Console
3. **Resultado esperado:** Notificación aparece en la bandeja del sistema

#### **Prueba 2: App en Background**
1. Abre la app y luego minimízala (botón home)
2. Envía notificación desde Firebase Console
3. **Resultado esperado:** Notificación aparece en la bandeja del sistema

#### **Prueba 3: App Abierta**
1. Mantén la app abierta en primer plano
2. Envía notificación desde Firebase Console
3. **Resultado esperado:** Notificación aparece como overlay dentro de la app

---

## 🔍 **PASO 5: DIAGNÓSTICO SI NO FUNCIONA**

### **5.1 Verificar en la Consola de la App:**
Busca estos mensajes en los logs:
```
✅ FirebaseNotificationsService inicializado correctamente
🔑 Token FCM obtenido: [token]...
💾 Token FCM guardado exitosamente
🔔 Estado de permisos Firebase: AuthorizationStatus.authorized
```

### **5.2 Verificar Permisos:**
En la pestaña "Test FCM":
- **Permisos concedidos:** ✅ Verde
- **Servicio inicializado:** ✅ Verde
- **Token FCM:** Debe mostrar un token largo

### **5.3 Si el Token no Aparece:**
1. Cierra y abre la app completamente
2. Espera 10-15 segundos
3. Toca "Actualizar Estado"
4. Si sigue sin aparecer, revisa los permisos del sistema

---

## 🛠️ **PASO 6: CONFIGURACIÓN AVANZADA**

### **6.1 Verificar Permisos del Sistema:**
1. Ve a **Configuración** del teléfono
2. **Apps** > **Donde Caiga** > **Notificaciones**
3. Asegúrate de que estén **ACTIVADAS**

### **6.2 Verificar en Supabase:**
1. Ve a tu Supabase Dashboard
2. **Table Editor** > **users_profiles**
3. Busca tu usuario por email
4. Verifica que el campo **fcm_token** tenga un valor

---

## 🎯 **PASO 7: PRUEBA DESDE TU EDGE FUNCTION**

Una vez que confirmes que Firebase funciona, puedes probar tu Edge Function:

### **7.1 Ejecutar en Supabase SQL Editor:**
```sql
-- Crear notificación de prueba que active la Edge Function
INSERT INTO notifications (
    user_id,
    type,
    title,
    message,
    metadata
) VALUES (
    '0dc7b2bc-04c7-430e-8725-19f6cdb55ee3', -- Tu user ID
    'general',
    'Prueba Edge Function',
    'Esta notificación viene de tu Edge Function',
    '{"test": true}'
);
```

---

## 📊 **RESUMEN DE CAMBIOS IMPLEMENTADOS**

### **✅ Arreglos Aplicados:**
1. **Background Handler único** en main.dart
2. **Servicio Firebase mejorado** con canal de notificaciones
3. **Configuración correcta** de foreground notifications
4. **Widget de prueba** integrado en la app
5. **Manejo de permisos** mejorado para Android 13+
6. **Token FCM** se guarda automáticamente en Supabase

### **✅ Configuración Verificada:**
- ✅ google-services.json en ubicación correcta
- ✅ Plugin de Google Services configurado
- ✅ minSdkVersion compatible
- ✅ Dependencias Firebase actualizadas
- ✅ Canal de notificaciones Android creado

---

## 🚨 **SOLUCIÓN DE PROBLEMAS COMUNES**

### **Problema: "Token no disponible"**
**Solución:**
1. Verifica conexión a internet
2. Reinicia la app completamente
3. Verifica permisos de notificaciones

### **Problema: "Permisos denegados"**
**Solución:**
1. Ve a Configuración > Apps > Donde Caiga > Permisos
2. Activa "Notificaciones"
3. Reinicia la app

### **Problema: "Notificación no llega"**
**Solución:**
1. Verifica que el token sea correcto
2. Prueba con la app completamente cerrada
3. Revisa que no esté en modo "No molestar"

---

## 🎉 **¡LISTO PARA PROBAR!**

Tu app ahora tiene:
- 🔥 **Firebase FCM** completamente configurado
- 📱 **Notificaciones en background** funcionando
- 🧪 **Widget de prueba** integrado
- 💾 **Token guardado** automáticamente en Supabase
- 🔔 **Canal de notificaciones** Android configurado

**Cuando conectes tu teléfono, ejecuta:**
```bash
flutter install --release
```

**Y sigue esta guía paso a paso para probar las notificaciones.**