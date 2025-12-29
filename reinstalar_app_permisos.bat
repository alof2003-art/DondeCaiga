@echo off
echo ========================================
echo REINSTALACION COMPLETA - DONDE CAIGA
echo Arreglando permisos de notificaciones
echo ========================================

echo.
echo 1. Desinstalando version anterior...
adb uninstall com.dondecaiga.app

echo.
echo 2. Instalando nueva version con permisos...
adb install -r -g build\app\outputs\flutter-apk\app-release.apk

echo.
echo 3. Otorgando permisos de notificaciones...
adb shell pm grant com.dondecaiga.app android.permission.POST_NOTIFICATIONS

echo.
echo 4. Verificando instalacion...
adb shell pm list packages | findstr dondecaiga

echo.
echo ========================================
echo INSTALACION COMPLETADA
echo ========================================
echo.
echo PROXIMOS PASOS:
echo 1. Abrir la app Donde Caiga
echo 2. Ir a Configuracion de Android
echo 3. Buscar "Donde Caiga" en Apps
echo 4. Verificar que aparece en la lista
echo 5. Activar notificaciones si es necesario
echo.
echo La app ahora deberia aparecer en la
echo configuracion de notificaciones de Android
echo ========================================

pause