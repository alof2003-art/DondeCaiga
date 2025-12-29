# 🔥 CONFIGURAR FIREBASE ANDROID COMPLETO

## 🚨 **PROBLEMA:** "App no se encuentra en la lista aplicaciones instaladas"

### **CAUSA:** La app no está correctamente registrada en Firebase Console

## 🔧 **SOLUCIÓN PASO A PASO:**

### **PASO 1: VERIFICAR FIREBASE CONSOLE**

#### **A. Ir a Firebase Console:**
```
https://console.firebase.google.com
```

#### **B. Seleccionar proyecto:**
- **Proyecto:** `donde-caiga-notifications`
- **Project ID:** `donde-caiga-notifications`

#### **C. Verificar configuración:**
1. **Project Settings** (⚙️)
2. **General** tab
3. **Your apps** section

### **PASO 2: CONFIGURAR APP ANDROID**

#### **A. Si no existe la app Android:**
1. **Add app** → **Android**
2. **Package name:** `com.dondecaiga.app`
3. **App nickname:** `Donde Caiga Android`
4. **SHA-1:** (opcional por ahora)

#### **B. Si ya existe, verificar:**
- **Package name:** Debe ser exactamente `com.dondecaiga.app`
- **Status:** Debe estar "Active"

### **PASO 3: DESCARGAR google-services.json**

#### **A. Descargar archivo:**
1. En Firebase Console → **Project Settings**
2. **Your apps** → **Android app**
3. **Download google-services.json**

#### **B. Reemplazar archivo:**
```bash
# Ubicación correcta:
android/app/google-services.json
```

### **PASO 4: VERIFICAR build.gradle**

#### **A. android/app/build.gradle:**
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.dondecaiga.app"  // ✅ DEBE COINCIDIR
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }
}
```

#### **B. android/build.gradle:**
```gradle
dependencies {
    classpath 'com.android.tools.build:gradle:7.3.0'
    classpath 'com.google.gms:google-services:4.3.15'  // ✅ FIREBASE
    classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
}
```

#### **C. android/app/build.gradle (final):**
```gradle
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'dev.flutter.flutter-gradle-plugin'
apply plugin: 'com.google.gms.google-services'  // ✅ FIREBASE
```

### **PASO 5: VERIFICAR PERMISOS ANDROID**

#### **A. AndroidManifest.xml ya está correcto:**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
```

### **PASO 6: CONFIGURAR SHA-1 (OPCIONAL PERO RECOMENDADO)**

#### **A. Generar SHA-1 debug:**
```bash
cd android
./gradlew signingReport
```

#### **B. Copiar SHA-1 y agregarlo en Firebase Console:**
1. **Project Settings** → **Your apps** → **Android**
2. **Add fingerprint**
3. Pegar SHA-1

### **PASO 7: REBUILD COMPLETO**

```bash
# Limpiar todo
flutter clean
cd android && ./gradlew clean && cd ..

# Reinstalar dependencias
flutter pub get

# Build debug
flutter build apk --debug

# Instalar
flutter install
```

### **PASO 8: VERIFICAR CONFIGURACIÓN**

#### **A. Logs esperados:**
```
✅ Firebase configurado correctamente
✅ FCM token generado
✅ Permisos de notificación concedidos
```

#### **B. Logs problemáticos:**
```
❌ FirebaseApp is not initialized
❌ Default FirebaseApp is not initialized
❌ No Firebase App '[DEFAULT]' has been created
```

## 🎯 **CHECKLIST FINAL:**

- [ ] **Firebase Console:** App Android registrada
- [ ] **Package name:** `com.dondecaiga.app` (exacto)
- [ ] **google-services.json:** Descargado y ubicado correctamente
- [ ] **build.gradle:** Plugin Firebase aplicado
- [ ] **AndroidManifest.xml:** Permisos configurados
- [ ] **App rebuildeada:** Clean + build + install

## 🚨 **SI SIGUE FALLANDO:**

### **OPCIÓN 1: CREAR NUEVO PROYECTO FIREBASE**
1. Crear proyecto nuevo en Firebase Console
2. Registrar app con package name correcto
3. Actualizar configuración

### **OPCIÓN 2: VERIFICAR PACKAGE NAME**
```bash
# Verificar package name actual
grep -r "applicationId" android/app/build.gradle
```

### **OPCIÓN 3: LOGS DETALLADOS**
```bash
# Ver logs completos
flutter run --verbose
adb logcat | grep -i firebase
```

## ✅ **RESULTADO ESPERADO:**

Después de seguir estos pasos:
1. **Firebase se inicializa correctamente**
2. **FCM token se genera**
3. **App aparece en configuración de Android**
4. **Notificaciones push funcionan**

¿En qué paso necesitas ayuda específica?