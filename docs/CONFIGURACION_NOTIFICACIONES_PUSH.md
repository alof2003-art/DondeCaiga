# 🔔 CONFIGURACIÓN DE NOTIFICACIONES PUSH - DONDE CAIGA

## 📋 GUÍA PASO A PASO

### 1. 🔥 CONFIGURACIÓN DE FIREBASE

#### Crear Proyecto Firebase
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Clic en "Crear proyecto"
3. Nombre: `donde-caiga-notifications`
4. Habilitar Google Analytics (opcional)
5. Crear proyecto

#### Configurar Android
1. En Firebase Console → "Agregar app" → Android
2. Nombre del paquete: `com.dondecaiga.app` (o tu package name)
3. Descargar `google-services.json`
4. Colocar en `android/app/google-services.json`

#### Configurar iOS
1. En Firebase Console → "Agregar app" → iOS
2. Bundle ID: `com.dondecaiga.app` (mismo que Android)
3. Descargar `GoogleService-Info.plist`
4. Colocar en `ios/Runner/GoogleService-Info.plist`

---

### 2. 📱 CONFIGURACIÓN ANDROID

#### `android/app/build.gradle`
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21  // Mínimo para notificaciones
        targetSdkVersion 34
    }
}

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.4.0'
    implementation 'androidx.work:work-runtime:2.9.0'
}

// Al final del archivo
apply plugin: 'com.google.gms.google-services'
```

#### `android/build.gradle`
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### `android/app/src/main/AndroidManifest.xml`
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Permisos necesarios -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    
    <application
        android:label="Donde Caiga"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Configuración de notificaciones -->
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
        
        <!-- Firebase Messaging Service -->
        <service
            android:name="io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>
        
        <!-- Actividad principal -->
        <activity
            android:exported="true"
            android:name=".MainActivity"
            android:theme="@style/LaunchTheme"
            android:launchMode="singleTop">
            
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            
            <!-- Intent filter para notificaciones -->
            <intent-filter>
                <action android:name="FLUTTER_NOTIFICATION_CLICK" />
                <category android:name="android.intent.category.DEFAULT" />
            </intent-filter>
        </activity>
        
    </application>
</manifest>
```

---

### 3. 🍎 CONFIGURACIÓN iOS

#### `ios/Runner/Info.plist`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Configuración existente -->
    
    <!-- Configuración de notificaciones -->
    <key>UIBackgroundModes</key>
    <array>
        <string>remote-notification</string>
        <string>background-fetch</string>
    </array>
    
    <!-- Configuración de Firebase -->
    <key>FirebaseAppDelegateProxyEnabled</key>
    <false/>
    
</dict>
</plist>
```

#### `ios/Runner/AppDelegate.swift`
```swift
import UIKit
import Flutter
import Firebase
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Configurar Firebase
    FirebaseApp.configure()
    
    // Configurar notificaciones
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Manejar notificaciones en primer plano
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.alert, .badge, .sound])
  }
  
  // Manejar tap en notificación
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
  
  // Registrar token FCM
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
  }
}
```

---

### 4. 🔧 CONFIGURACIÓN FLUTTER

#### `pubspec.yaml`
```yaml
dependencies:
  # Notificaciones
  flutter_local_notifications: ^17.0.0
  firebase_messaging: ^14.7.10
  firebase_core: ^2.24.2
  
  # Otras dependencias existentes...
```

#### Ejecutar comandos
```bash
# Instalar dependencias
flutter pub get

# Configurar Firebase (opcional, si tienes Firebase CLI)
firebase init

# Para iOS, instalar pods
cd ios && pod install && cd ..
```

---

### 5. 🎯 CONFIGURACIÓN EN SUPABASE

#### Edge Function para FCM (Opcional)
```javascript
// supabase/functions/send-notification/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { fcmToken, title, body, data } = await req.json()
    
    const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        'Authorization': `key=${Deno.env.get('FCM_SERVER_KEY')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: fcmToken,
        notification: {
          title,
          body,
        },
        data,
      }),
    })

    const result = await fcmResponse.json()
    
    return new Response(
      JSON.stringify({ success: true, result }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})
```

---

### 6. 🧪 TESTING

#### Probar Notificaciones Locales
```dart
// En cualquier parte de tu app
final pushService = PushNotificationsService();

// Probar notificación simple
await pushService.showLocalNotification(
  title: 'Prueba',
  body: 'Esta es una notificación de prueba',
);
```

#### Probar FCM (Firebase Console)
1. Ve a Firebase Console → Cloud Messaging
2. Clic en "Enviar tu primer mensaje"
3. Título: "Prueba FCM"
4. Texto: "Mensaje de prueba desde Firebase"
5. Seleccionar tu app
6. Enviar

#### Verificar Permisos
```dart
// Verificar si los permisos están concedidos
final pushService = PushNotificationsService();
final hasPermissions = await pushService.areNotificationsEnabled();

if (!hasPermissions) {
  final granted = await pushService.requestPermissions();
  print('Permisos concedidos: $granted');
}
```

---

### 7. 🐛 TROUBLESHOOTING

#### Problema: No llegan notificaciones en Android
```bash
# Verificar que Firebase esté configurado
flutter packages get
cd android && ./gradlew signingReport

# Verificar SHA-1 en Firebase Console
```

#### Problema: No llegan notificaciones en iOS
```bash
# Verificar certificados APNs en Firebase
# Asegurarse de que el Bundle ID coincida
# Probar en dispositivo físico (no simulador)
```

#### Problema: Permisos denegados
```dart
// Verificar estado de permisos
final settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Estado de autorización: ${settings.authorizationStatus}');

if (settings.authorizationStatus == AuthorizationStatus.denied) {
  // Mostrar diálogo explicativo al usuario
  showDialog(/* ... */);
}
```

#### Logs útiles
```dart
// Habilitar logs de Firebase
await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  alert: true,
  badge: true,
  sound: true,
);

// Log del token FCM
final token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');
```

---

### 8. 🚀 DEPLOYMENT

#### Android Release
```bash
# Generar keystore si no tienes
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Configurar en android/key.properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-keystore>

# Build release
flutter build apk --release
```

#### iOS Release
```bash
# Asegurarse de tener certificados de producción
# Configurar en Xcode → Signing & Capabilities
# Build para App Store
flutter build ios --release
```

---

### 9. 📊 MONITOREO

#### Firebase Analytics
```dart
// Trackear eventos de notificaciones
await FirebaseAnalytics.instance.logEvent(
  name: 'notification_received',
  parameters: {
    'notification_type': 'solicitudReserva',
    'user_id': userId,
  },
);
```

#### Métricas importantes
- **Delivery rate**: % de notificaciones entregadas
- **Open rate**: % de notificaciones abiertas
- **Conversion rate**: % que completan acción deseada

---

## ✅ CHECKLIST FINAL

### Antes de lanzar:
- [ ] Firebase configurado correctamente
- [ ] Permisos de notificación funcionando
- [ ] Notificaciones locales funcionando
- [ ] FCM funcionando en desarrollo
- [ ] Navegación desde notificaciones funciona
- [ ] Probado en dispositivos Android e iOS
- [ ] Certificados de producción configurados
- [ ] Edge functions desplegadas (si aplica)
- [ ] Monitoreo configurado

### En producción:
- [ ] Monitorear delivery rates
- [ ] Revisar logs de errores
- [ ] Optimizar mensajes según engagement
- [ ] Mantener certificados actualizados

---

**¡Tu sistema de notificaciones push está listo para producción! 🚀📱**