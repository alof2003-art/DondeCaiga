plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Google Services (Añadido)
    id("com.google.gms.google-services")
    // El plugin de Flutter debe ir después
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.dondecaiga.app" // Cambiado para coincidir con Firebase
    compileSdk = 36 // Actualizado para compatibilidad con las dependencias
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Habilitar core library desugaring para flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.dondecaiga.app" // Cambiado para coincidir con Firebase
        // Para notificaciones y Firebase, te recomiendo mínimo 21
        minSdk = flutter.minSdkVersion // Para notificaciones y Firebase
        targetSdk = 34 // Mantener targetSdk en 34 por compatibilidad
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Importa el BoM de Firebase (como sugiere tu imagen de Firebase)
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))
    
    // Dependencias para notificaciones
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-analytics")
    
    // Core library desugaring para flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
