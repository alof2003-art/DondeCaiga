# 📱 GUÍA: CÓMO INSTALAR LA APP EN TU CELULAR

**Fecha:** 2025-12-04  
**Plataforma:** Android

---

## 🎯 OPCIONES DISPONIBLES

Tienes **3 opciones** para instalar la app en tu celular:

### Opción 1: 🔌 Instalación Directa por USB (Recomendada)
- ✅ Más rápida
- ✅ Permite ver logs en tiempo real
- ✅ Ideal para desarrollo y pruebas

### Opción 2: 📦 Generar APK e Instalar Manualmente
- ✅ No requiere cable USB
- ✅ Puedes compartir el APK
- ✅ Instalación independiente

### Opción 3: 🏪 Subir a Google Play (Producción)
- ⚠️ Requiere cuenta de desarrollador ($25 USD)
- ⚠️ Proceso de revisión (varios días)
- ✅ Distribución pública

---

## 🔌 OPCIÓN 1: INSTALACIÓN DIRECTA POR USB

### Paso 1: Habilitar Opciones de Desarrollador en tu Celular

1. **Abre Configuración** en tu celular Android
2. **Ve a "Acerca del teléfono"** o "Información del dispositivo"
3. **Busca "Número de compilación"** o "Build number"
4. **Toca 7 veces** sobre "Número de compilación"
5. Verás un mensaje: **"Ahora eres un desarrollador"**

### Paso 2: Habilitar Depuración USB

1. **Regresa a Configuración**
2. **Busca "Opciones de desarrollador"** o "Developer options"
   - Puede estar en: Sistema > Avanzado > Opciones de desarrollador
3. **Activa "Opciones de desarrollador"** (switch en la parte superior)
4. **Activa "Depuración USB"** o "USB debugging"
5. **Activa "Instalar vía USB"** (si está disponible)

### Paso 3: Conectar el Celular a la PC

1. **Conecta tu celular** a la PC con un cable USB
2. **En el celular**, aparecerá un mensaje:
   - "¿Permitir depuración USB?"
   - "Huella digital RSA: ..."
3. **Marca** "Permitir siempre desde este equipo"
4. **Presiona "Permitir"** o "Aceptar"

### Paso 4: Verificar Conexión

Ejecuta en la terminal:

```bash
flutter devices
```

Deberías ver algo como:

```
Found 2 connected devices:
  SM G960F (mobile) • 1234567890ABCDEF • android-arm64 • Android 12 (API 31)
  Windows (desktop) • windows • windows-x64 • Microsoft Windows
```

### Paso 5: Instalar la App

Ejecuta:

```bash
flutter install
```

O para compilar e instalar:

```bash
flutter run --release
```

**¡Listo!** La app se instalará automáticamente en tu celular.

---

## 📦 OPCIÓN 2: GENERAR APK E INSTALAR MANUALMENTE

### Paso 1: Compilar el APK

Ejecuta en la terminal:

```bash
flutter build apk --release
```

Esto tomará unos minutos. Verás:

```
✓ Built build\app\outputs\flutter-apk\app-release.apk (XX.X MB)
```

### Paso 2: Ubicar el APK

El APK se genera en:

```
build/app/outputs/flutter-apk/app-release.apk
```

**Tamaño aproximado:** 40-60 MB

### Paso 3: Transferir el APK al Celular

**Opción A: Por Cable USB**

1. Conecta el celular a la PC
2. Abre el explorador de archivos
3. Copia `app-release.apk` a la carpeta `Descargas` del celular

**Opción B: Por Email**

1. Envíate el APK por email
2. Abre el email en tu celular
3. Descarga el archivo adjunto

**Opción C: Por Google Drive / Dropbox**

1. Sube el APK a la nube
2. Descárgalo desde tu celular

**Opción D: Por WhatsApp**

1. Envíate el APK a ti mismo
2. Descárgalo en tu celular

### Paso 4: Habilitar Instalación de Fuentes Desconocidas

1. **Abre Configuración** en tu celular
2. **Ve a "Seguridad"** o "Privacidad"
3. **Busca "Instalar apps desconocidas"** o "Fuentes desconocidas"
4. **Selecciona la app** que usarás para instalar (ej: Chrome, Archivos, Gmail)
5. **Activa** "Permitir de esta fuente"

### Paso 5: Instalar el APK

1. **Abre el administrador de archivos** en tu celular
2. **Ve a la carpeta Descargas**
3. **Toca el archivo** `app-release.apk`
4. **Presiona "Instalar"**
5. Espera a que termine la instalación
6. **Presiona "Abrir"** para ejecutar la app

**¡Listo!** La app está instalada.

---

## 🔧 SOLUCIÓN DE PROBLEMAS

### Problema 1: "Dispositivo no detectado"

**Síntomas:**
- `flutter devices` no muestra tu celular
- Solo aparece "Windows" y "Chrome"

**Soluciones:**

1. **Verifica el cable USB:**
   - Usa un cable que soporte transferencia de datos
   - Algunos cables solo cargan

2. **Cambia el modo USB:**
   - En el celular, desliza la notificación USB
   - Cambia de "Solo carga" a "Transferencia de archivos" o "MTP"

3. **Reinstala drivers USB:**
   ```bash
   # Verifica si ADB detecta el dispositivo
   adb devices
   ```
   
   Si no aparece, instala drivers USB del fabricante:
   - Samsung: Samsung USB Driver
   - Xiaomi: Mi USB Driver
   - Huawei: HiSuite
   - Motorola: Motorola Device Manager

4. **Revoca autorizaciones USB:**
   - En el celular: Opciones de desarrollador
   - "Revocar autorizaciones de depuración USB"
   - Desconecta y vuelve a conectar
   - Acepta de nuevo el diálogo

### Problema 2: "Error al compilar APK"

**Síntomas:**
- `flutter build apk` falla
- Errores de compilación

**Soluciones:**

1. **Limpia el proyecto:**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

2. **Verifica Java/Android SDK:**
   ```bash
   flutter doctor
   ```
   
   Debe mostrar:
   - ✓ Android toolchain
   - ✓ Android Studio

3. **Actualiza dependencias:**
   ```bash
   flutter pub upgrade
   ```

### Problema 3: "App no se instala en el celular"

**Síntomas:**
- "App no instalada"
- "Paquete no válido"

**Soluciones:**

1. **Desinstala versión anterior:**
   - Si ya tienes la app instalada
   - Desinstálala completamente
   - Intenta instalar de nuevo

2. **Verifica espacio disponible:**
   - La app necesita ~100 MB
   - Libera espacio si es necesario

3. **Habilita fuentes desconocidas:**
   - Configuración > Seguridad
   - Permitir instalación de apps desconocidas

### Problema 4: "App se cierra al abrir"

**Síntomas:**
- La app se instala pero crashea
- Pantalla negra y cierra

**Soluciones:**

1. **Verifica permisos:**
   - Configuración > Aplicaciones > Donde Caiga
   - Permisos > Permitir todos

2. **Revisa logs:**
   ```bash
   flutter logs
   ```
   
   O con el celular conectado:
   ```bash
   adb logcat | grep -i flutter
   ```

3. **Compila en modo debug:**
   ```bash
   flutter run --debug
   ```
   
   Esto mostrará errores detallados

### Problema 5: "Permisos no se solicitan"

**Síntomas:**
- La app no pide permisos de cámara/almacenamiento
- No puede tomar fotos

**Soluciones:**

1. **Verifica AndroidManifest.xml:**
   - Debe tener todos los permisos configurados
   - Ya está configurado en tu proyecto ✅

2. **Reinstala la app:**
   - Desinstala completamente
   - Instala de nuevo
   - Los permisos se resetean

3. **Otorga permisos manualmente:**
   - Configuración > Aplicaciones > Donde Caiga
   - Permisos > Permitir cámara y almacenamiento

---

## 📊 COMPARACIÓN DE OPCIONES

| Característica | USB Directo | APK Manual | Google Play |
|----------------|-------------|------------|-------------|
| **Velocidad** | ⚡ Rápida | 🐢 Media | 🐌 Lenta (días) |
| **Costo** | 💰 Gratis | 💰 Gratis | 💰 $25 USD |
| **Complejidad** | 🔧 Media | 🔧 Fácil | 🔧 Alta |
| **Logs en tiempo real** | ✅ Sí | ❌ No | ❌ No |
| **Compartir con otros** | ❌ No | ✅ Sí (APK) | ✅ Sí (Store) |
| **Actualizaciones** | 🔄 Manual | 🔄 Manual | 🔄 Automáticas |
| **Ideal para** | Desarrollo | Pruebas | Producción |

---

## 🎯 RECOMENDACIÓN

### Para Pruebas y Desarrollo:
**Usa Opción 1 (USB Directo)**
- Más rápida
- Puedes ver errores en tiempo real
- Fácil de actualizar

### Para Compartir con Amigos/Familia:
**Usa Opción 2 (APK Manual)**
- Genera el APK una vez
- Compártelo por WhatsApp/Email
- Ellos lo instalan directamente

### Para Lanzamiento Público:
**Usa Opción 3 (Google Play)**
- Cuando la app esté lista
- Quieras distribución masiva
- Necesites actualizaciones automáticas

---

## 📝 COMANDOS RÁPIDOS

### Verificar dispositivos conectados:
```bash
flutter devices
```

### Instalar directamente:
```bash
flutter install
```

### Ejecutar en modo release:
```bash
flutter run --release
```

### Generar APK:
```bash
flutter build apk --release
```

### Ver logs del celular:
```bash
flutter logs
```

### Desinstalar del celular:
```bash
flutter uninstall
```

---

## ✅ CHECKLIST PRE-INSTALACIÓN

Antes de instalar, verifica:

### En tu PC:
- [ ] Flutter instalado y funcionando
- [ ] Android SDK configurado
- [ ] Proyecto sin errores de compilación

### En tu Celular:
- [ ] Opciones de desarrollador habilitadas
- [ ] Depuración USB activada
- [ ] Cable USB que soporte datos (no solo carga)
- [ ] Espacio disponible (mínimo 100 MB)

### Para APK Manual:
- [ ] APK compilado exitosamente
- [ ] APK transferido al celular
- [ ] Fuentes desconocidas habilitadas
- [ ] Administrador de archivos instalado

---

## 🚀 PRÓXIMOS PASOS DESPUÉS DE INSTALAR

1. **Abre la app** por primera vez
2. **Acepta los permisos** cuando se soliciten:
   - Cámara
   - Almacenamiento
   - (Ubicación si se implementa)
3. **Regístrate** con un usuario de prueba
4. **Prueba las funcionalidades:**
   - Tomar foto de perfil
   - Crear propiedad
   - Subir fotos
   - Usar el mapa
   - Buscar direcciones
5. **Reporta cualquier error** que encuentres

---

## 📞 AYUDA ADICIONAL

Si tienes problemas:

1. **Revisa los logs:**
   ```bash
   flutter logs
   ```

2. **Ejecuta flutter doctor:**
   ```bash
   flutter doctor -v
   ```

3. **Verifica la conexión ADB:**
   ```bash
   adb devices
   ```

4. **Consulta la documentación:**
   - [Flutter - Deploy to Android](https://docs.flutter.dev/deployment/android)
   - [Android - USB Debugging](https://developer.android.com/studio/debug/dev-options)

---

**Creado por:** Kiro AI  
**Fecha:** 2025-12-04  
**Versión:** 1.0.0

---

**¡Buena suerte con la instalación!** 🚀📱
