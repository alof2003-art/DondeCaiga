# 🚨 DIAGNÓSTICO COMPLETO DE PROBLEMAS PUSH

## 📋 **PROBLEMAS IDENTIFICADOS:**

### **1. ERROR DE CONEXIÓN SUPABASE** ❌
```
Failed host lookup: 'louehuwimvwsoqesjjau.supabase.co'
```
**CAUSA:** Problema de conectividad o URL incorrecta

### **2. APP NO REGISTRADA EN ANDROID** ❌
```
"Mi app no se encuentra en la lista aplicaciones instaladas"
```
**CAUSA:** Falta configuración en Firebase Console

### **3. PUSH NOTIFICATIONS NO FUNCIONAN** ❌
**CAUSA:** Edge Function no deployado + problemas de configuración

## 🔧 **SOLUCIONES PASO A PASO:**

### **SOLUCIÓN 1: VERIFICAR CONECTIVIDAD SUPABASE**

#### **A. Probar URL manualmente:**
```bash
curl -I https://louehuwimvwsoqesjjau.supabase.co
```

#### **B. Si falla, verificar en Supabase Dashboard:**
1. Ir a https://supabase.com/dashboard
2. Verificar que el proyecto esté activo
3. Copiar URL correcta desde Settings → API

### **SOLUCIÓN 2: REGISTRAR APP EN FIREBASE CONSOLE**

#### **A. Ir a Firebase Console:**
1. https://console.firebase.google.com
2. Seleccionar proyecto: `donde-caiga-notifications`

#### **B. Verificar configuración Android:**
1. **Project Settings → General**
2. **Your apps → Android app**
3. **Package name:** `com.dondecaiga.app`
4. **SHA certificate fingerprints:** Agregar debug y release

#### **C. Descargar google-services.json actualizado:**
1. Descargar desde Firebase Console
2. Reemplazar `android/app/google-services.json`

### **SOLUCIÓN 3: DEPLOY EDGE FUNCTION**

#### **A. Crear Edge Function en Supabase:**
1. Dashboard → Edge Functions → Create Function
2. **Name:** `send-push-notification`
3. **Code:** Copiar de `docs/EDGE_FUNCTION_FINAL_WORKING.js`

#### **B. Configurar Environment Variable:**
1. **Variable:** `FIREBASE_SERVICE_ACCOUNT`
2. **Value:** JSON completo del Service Account de Firebase

### **SOLUCIÓN 4: ARREGLAR CONFIGURACIÓN ANDROID**

#### **A. Verificar Package Name en build.gradle:**
```gradle
// android/app/build.gradle
applicationId "com.dondecaiga.app"
```

#### **B. Verificar google-services.json:**
```json
{
  "project_info": {
    "project_id": "donde-caiga-notifications"
  },
  "client": [
    {
      "client_info": {
        "android_client_info": {
          "package_name": "com.dondecaiga.app"
        }
      }
    }
  ]
}
```

## 🎯 **ORDEN DE EJECUCIÓN:**

### **PASO 1: VERIFICAR SUPABASE**
```bash
# Probar conectividad
ping louehuwimvwsoqesjjau.supabase.co
```

### **PASO 2: ACTUALIZAR FIREBASE**
1. Descargar nuevo `google-services.json`
2. Reemplazar archivo existente
3. Rebuild app

### **PASO 3: DEPLOY EDGE FUNCTION**
1. Crear función en Supabase Dashboard
2. Configurar environment variables
3. Probar con curl

### **PASO 4: REBUILD Y PROBAR**
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

## 🔍 **COMANDOS DE DIAGNÓSTICO:**

### **A. Probar Supabase:**
```bash
curl -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
     https://louehuwimvwsoqesjjau.supabase.co/rest/v1/users_profiles
```

### **B. Probar Edge Function:**
```bash
curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_ANON_KEY" \
     -d '{"fcm_token":"test","title":"Test","body":"Test"}' \
     https://louehuwimvwsoqesjjau.supabase.co/functions/v1/send-push-notification
```

### **C. Verificar Firebase:**
```bash
# Verificar que google-services.json existe
ls -la android/app/google-services.json
```

## ⚡ **SOLUCIÓN RÁPIDA:**

Si tienes prisa, ejecuta estos comandos en orden:

```bash
# 1. Limpiar proyecto
flutter clean
flutter pub get

# 2. Verificar archivos críticos
ls -la android/app/google-services.json
ls -la .env

# 3. Rebuild
flutter build apk --debug

# 4. Instalar y probar
flutter install
```

## 🎯 **PRÓXIMOS PASOS:**

1. **Ejecutar diagnósticos**
2. **Arreglar problemas encontrados**
3. **Deploy Edge Function**
4. **Probar sistema completo**

¿Por cuál problema quieres empezar?