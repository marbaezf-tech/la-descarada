@echo off
echo ============================================
echo   PLAGA: LA DESCARADA - Exportar APK v0.3.0
echo ============================================
echo.

set GODOT="C:\Users\HardwareX\Downloads\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe"
set PROJECT="C:\Users\HardwareX\OneDrive\Documentos\descarada"
set OUTPUT="C:\Users\HardwareX\OneDrive\Documentos\descarada\export\descarada_v0.3.0.apk"

echo [1/3] Verificando Godot...
if not exist %GODOT% (
    echo ERROR: No se encontro Godot en %GODOT%
    echo Verifica la ruta del ejecutable.
    pause
    exit /b 1
)

echo [2/3] Creando carpeta export...
if not exist "%PROJECT%\export" mkdir "%PROJECT%\export"

echo [3/3] Exportando APK...
%GODOT% --headless --path %PROJECT% --export-debug "Android" %OUTPUT%

if exist %OUTPUT% (
    echo.
    echo ============================================
    echo   APK EXPORTADA EXITOSAMENTE!
    echo   %OUTPUT%
    echo ============================================
) else (
    echo.
    echo ERROR: La exportacion fallo.
    echo Verifica que tengas el export preset de Android configurado en Godot.
    echo Abre Godot -^> Proyecto -^> Exportar -^> Android
)

echo.
pause
