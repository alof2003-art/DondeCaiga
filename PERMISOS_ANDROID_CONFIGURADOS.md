# 📱 PERMISOS DE ANDROID - CONFIGURACIÓN COMPLETA

**Fecha:** 2025-12-04  
**Estado:** ✅ CONFIGURADO

---

## 🎯 RESUMEN

Se han configurado todos los permisos necesarios en el archivo `AndroidManifest.xml` para que la aplicación solicite correctamente los permisos de **cámara**, **almacenamiento** y **ubicación** cuando se instale en un dispositivo Android.

---

## ✅ PERMISOS CONFIGURADOS

### 1. 🌐 Internet y Red

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

**Uso:**
- Conexión a Supabase (base de datos)
- Carga/descarga de imágenes
- Mapas de OpenStreetMap
- Búsqueda de direcciones (Nominatim)
- Chat en tiempo real

**Solicitud:** Automática (no requiere confirmación del usuario)

---

### 2. 📷 Cámara

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false"/>
```

**Uso:**
- Foto de perfil al registrarse
- Foto de cédula al registrarse
- Fotos de solicitud de anfitrión (selfie + propiedad)
- Fotos de propiedades al crear/editar

**Solicitud:** En tiempo de ejecución (cuando el usuario intenta tomar una foto)

**Comportamiento:**
- Primera vez: Aparece diálogo "¿Permitir que Donde Caiga acceda a la cámara?"
- Opciones: "Permitir" / "Denegar"
- Si deniega: Puede cambiar en Configuración > Aplicaciones > Donde Caiga > Permisos

**Nota:** `android:required="false"` permite que la app funcione en dispositivos sin cámara (emuladores)

---

### 3. 💾 Almacenamiento

#### Android 12 y anteriores (API ≤ 32)

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="32"/>
```

#### Android 13+ (API 33+)

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

**Uso:**
- Seleccionar fotos de la galería
- Guardar fotos tomadas
- Leer imágenes para subir a Supabase

**Solicitud:** En tiempo de ejecución (cuando el usuario intenta seleccionar una foto)

**Comportamiento:**
- Primera vez: Aparece diálogo "¿Permitir que Donde Caiga acceda a tus fotos?"
- Android 13+: Permisos más granulares (solo imágenes, no todo el almacenamiento)
- Opciones: "Permitir" / "Denegar" / "Permitir solo mientras uso la app"

**Nota:** `android:maxSdkVersion="32"` limita WRITE_EXTERNAL_STORAGE a Android 12 y anteriores

---

### 4. 📍 Ubicación (Opcional)

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

**Uso:**
- **Actualmente:** No se usa (ubicación se selecciona manualmente en el mapa)
- **Futuro:** Botón "Usar mi ubicación actual" en el selector de mapa

**Solicitud:** En tiempo de ejecución (si se implementa la funcionalidad)

**Comportamiento:**
- Primera vez: Aparece diálogo "¿Permitir que Donde Caiga acceda a tu ubicación?"
- Opciones: "Permitir siempre" / "Permitir solo mientras uso la app" / "Denegar"

**Nota:** Estos permisos están configurados pero no se solicitan actualmente

---

## 📋 ARCHIVO MODIFICADO

### `android/app/src/main/AndroidManifest.xml`

**Ubicación completa:**
```
android/
└── app/
    └── src/
        └── main/
            └── AndroidManifest.xml
```

**Contenido actualizado:**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- Permisos de Internet (requerido para Supabase y mapas) -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <!-- Permisos de Cámara (para fotos de perfil y propiedades) -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-feature android:name="android.hardware.camera" android:required="false"/>
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false"/>
    
    <!-- Permisos de Almacenamiento (para guardar y leer fotos) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="32"/>
    <!-- Android 13+ (API 33+) usa permisos granulares -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    
    <!-- Permisos de Ubicación (opcional, para mapas) -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    
    <application
        android:label="donde_caigav2"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <!-- ... resto del archivo ... -->
    </application>
</manifest>
```

---

## 🔄 FLUJO DE PERMISOS EN LA APP

### Registro de Usuario

```
1. Usuario abre pantalla de registro
   ↓
2. Presiona "Seleccionar foto de perfil"
   ↓
3. Sistema muestra opciones: "Cámara" / "Galería"
   ↓
4. Si elige "Cámara":
   - Primera vez: Solicita permiso de CÁMARA
   - Usuario acepta/rechaza
   - Si acepta: Abre cámara
   ↓
5. Si elige "Galería":
   - Primera vez: Solicita permiso de ALMACENAMIENTO
   - Usuario acepta/rechaza
   - Si acepta: Abre galería
   ↓
6. Usuario toma/selecciona foto
   ↓
7. Foto se muestra en la app
   ↓
8. Al registrarse, foto se sube a Supabase
```

### Crear Propiedad

```
1. Usuario (anfitrión) crea propiedad
   ↓
2. Presiona "Agregar foto principal"
   ↓
3. Sistema muestra opciones: "Cámara" / "Galería"
   ↓
4. Solicita permisos (si no se han otorgado)
   ↓
5. Usuario toma/selecciona foto
   ↓
6. Foto se sube a Supabase Storage
```

### Solicitud de Anfitrión

```
1. Usuario solicita ser anfitrión
   ↓
2. Debe subir 2 fotos:
   - Selfie con cédula
   - Foto de la propiedad
   ↓
3. Para cada foto:
   - Solicita permisos (si no se han otorgado)
   - Usuario toma/selecciona foto
   ↓
4. Fotos se suben a Supabase
```

---

## 🔐 GESTIÓN DE PERMISOS

### Permisos Denegados

Si el usuario deniega un permiso:

1. **Primera denegación:**
   - La app muestra un mensaje: "Necesitamos acceso a [permiso] para [función]"
   - Usuario puede intentar de nuevo

2. **Segunda denegación (permanente):**
   - Android marca como "No volver a preguntar"
   - La app debe mostrar: "Ve a Configuración > Aplicaciones > Donde Caiga > Permisos para habilitar [permiso]"
   - Puede abrir configuración con `openAppSettings()`

### Verificar Permisos

El paquete `image_picker` maneja automáticamente:
- ✅ Verificación de permisos
- ✅ Solicitud de permisos
- ✅ Manejo de denegaciones
- ✅ Compatibilidad con diferentes versiones de Android

**No necesitas código adicional** para manejar permisos de cámara/almacenamiento.

---

## 📱 COMPATIBILIDAD POR VERSIÓN DE ANDROID

### Android 6.0 - 9.0 (API 23-28)

- ✅ Permisos en tiempo de ejecución
- ✅ READ_EXTERNAL_STORAGE
- ✅ WRITE_EXTERNAL_STORAGE
- ✅ CAMERA

### Android 10 (API 29)

- ✅ Scoped Storage (almacenamiento limitado)
- ✅ Acceso a MediaStore
- ✅ Sin acceso directo a archivos

### Android 11 (API 30)

- ✅ Scoped Storage obligatorio
- ✅ Permisos más restrictivos
- ✅ Acceso solo a archivos de la app

### Android 12 (API 31-32)

- ✅ Permisos de ubicación aproximada/precisa
- ✅ Mejoras en privacidad
- ✅ WRITE_EXTERNAL_STORAGE aún funciona

### Android 13+ (API 33+)

- ✅ Permisos granulares de medios
- ✅ READ_MEDIA_IMAGES (solo imágenes)
- ✅ READ_MEDIA_VIDEO (solo videos)
- ✅ READ_MEDIA_AUDIO (solo audio)
- ❌ WRITE_EXTERNAL_STORAGE ignorado

**La app es compatible con todas estas versiones** ✅

---

## 🧪 PRUEBAS DE PERMISOS

### Cómo Probar en Dispositivo Real

1. **Instalar la app:**
   ```bash
   flutter run --release
   ```

2. **Primera instalación:**
   - Todos los permisos están denegados por defecto
   - La app solicitará permisos cuando sea necesario

3. **Probar cámara:**
   - Ir a Registro
   - Presionar "Seleccionar foto de perfil"
   - Elegir "Cámara"
   - Verificar que aparece diálogo de permiso
   - Aceptar y verificar que abre la cámara

4. **Probar galería:**
   - Ir a Registro
   - Presionar "Seleccionar foto de perfil"
   - Elegir "Galería"
   - Verificar que aparece diálogo de permiso
   - Aceptar y verificar que abre la galería

5. **Probar denegación:**
   - Denegar permiso
   - Verificar que la app muestra mensaje apropiado
   - Intentar de nuevo
   - Verificar que solicita permiso nuevamente

### Resetear Permisos

Para probar de nuevo desde cero:

```bash
# Desinstalar la app
adb uninstall com.example.donde_caigav2

# O resetear permisos sin desinstalar
adb shell pm reset-permissions com.example.donde_caigav2
```

---

## 🚨 PROBLEMAS COMUNES Y SOLUCIONES

### Problema 1: Permisos no se solicitan

**Causa:** AndroidManifest.xml no tiene los permisos

**Solución:** ✅ Ya configurado en este commit

### Problema 2: Cámara no abre

**Causa:** Permiso denegado permanentemente

**Solución:** 
- Ir a Configuración del dispositivo
- Aplicaciones > Donde Caiga > Permisos
- Habilitar Cámara

### Problema 3: No puede seleccionar fotos en Android 13+

**Causa:** Falta permiso READ_MEDIA_IMAGES

**Solución:** ✅ Ya configurado en este commit

### Problema 4: App crashea al tomar foto

**Causa:** Falta configuración de FileProvider (para Android 7+)

**Solución:** El paquete `image_picker` lo maneja automáticamente

---

## 📊 RESUMEN DE PERMISOS

| Permiso | Uso | Cuándo se solicita | Requerido |
|---------|-----|-------------------|-----------|
| INTERNET | Supabase, mapas | Automático | ✅ Sí |
| ACCESS_NETWORK_STATE | Estado de red | Automático | ✅ Sí |
| CAMERA | Tomar fotos | Al usar cámara | ✅ Sí |
| READ_EXTERNAL_STORAGE | Leer galería | Al seleccionar foto | ✅ Sí |
| WRITE_EXTERNAL_STORAGE | Guardar fotos (≤API 32) | Al tomar foto | ✅ Sí |
| READ_MEDIA_IMAGES | Leer imágenes (≥API 33) | Al seleccionar foto | ✅ Sí |
| ACCESS_FINE_LOCATION | Ubicación precisa | No se usa aún | ⚠️ Opcional |
| ACCESS_COARSE_LOCATION | Ubicación aproximada | No se usa aún | ⚠️ Opcional |

---

## 🔮 MEJORAS FUTURAS

### Corto Plazo
- [ ] Implementar botón "Usar mi ubicación actual" en mapas
- [ ] Solicitar permisos de ubicación cuando se use
- [ ] Agregar mensajes personalizados al solicitar permisos

### Mediano Plazo
- [ ] Implementar paquete `permission_handler` para control más fino
- [ ] Agregar pantalla de "Permisos requeridos" en primer uso
- [ ] Implementar verificación de permisos antes de usar funciones

### Largo Plazo
- [ ] Modo offline con permisos mínimos
- [ ] Configuración de privacidad en la app
- [ ] Explicaciones contextuales de por qué se necesita cada permiso

---

## ✅ CHECKLIST DE VERIFICACIÓN

### Configuración
- [x] Permisos agregados a AndroidManifest.xml
- [x] Internet configurado
- [x] Cámara configurada
- [x] Almacenamiento configurado (Android ≤12)
- [x] Almacenamiento configurado (Android 13+)
- [x] Ubicación configurada (opcional)

### Funcionalidades
- [x] Foto de perfil (cámara/galería)
- [x] Foto de cédula (cámara/galería)
- [x] Fotos de solicitud anfitrión
- [x] Fotos de propiedades
- [x] Subida a Supabase Storage

### Testing
- [ ] Probar en Android 10
- [ ] Probar en Android 11
- [ ] Probar en Android 12
- [ ] Probar en Android 13+
- [ ] Probar denegación de permisos
- [ ] Probar denegación permanente

---

## 📞 SOPORTE

Si tienes problemas con permisos:

1. **Verifica la versión de Android** del dispositivo
2. **Revisa los logs** con `flutter logs`
3. **Verifica permisos** en Configuración del dispositivo
4. **Reinstala la app** para resetear permisos

---

**Desarrollador:** Kiro AI  
**Fecha:** 2025-12-04  
**Versión:** 1.0.0  
**Estado:** ✅ CONFIGURADO Y DOCUMENTADO

---

**FIN DE LA DOCUMENTACIÓN DE PERMISOS DE ANDROID**
