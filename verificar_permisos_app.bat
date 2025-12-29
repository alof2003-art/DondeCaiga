@echo off
echo ========================================
echo VERIFICACION PERMISOS - DONDE CAIGA
echo ========================================

echo.
echo 1. Verificando que la app esta instalada...
adb shell pm list packages | findstr dondecaiga

echo.
echo 2. Verificando permisos otorgados...
adb shell dumpsys package com.dondecaiga.app | findstr POST_NOTIFICATIONS

echo.
echo 3. Verificando informacion de la app...
adb shell dumpsys package com.dondecaiga.app | findstr "Package \[com.dondecaiga.app\]" -A 5

echo.
echo 4. Verificando version instalada...
adb shell dumpsys package com.dondecaiga.app | findstr versionName

echo.
echo ========================================
echo VERIFICACION COMPLETADA
echo ========================================
echo.
echo Si ves "com.dondecaiga.app" en el primer comando,
echo la app esta correctamente instalada.
echo.
echo Si ves "POST_NOTIFICATIONS" en el segundo comando,
echo los permisos estan otorgados.
echo.
echo Ahora puedes:
echo 1. Abrir Configuracion de Android
echo 2. Ir a Apps y buscar "Donde Caiga"
echo 3. La app deberia aparecer en la lista
echo 4. Configurar notificaciones segun necesites
echo ========================================

pause