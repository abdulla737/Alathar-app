@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
title Alathar - Android emulator

rem ---- Find the Android SDK -------------------------------------------
set "SDK=%LOCALAPPDATA%\Android\Sdk"
if defined ANDROID_HOME set "SDK=%ANDROID_HOME%"
set "EMU=%SDK%\emulator\emulator.exe"
set "ADB=%SDK%\platform-tools\adb.exe"
if not exist "%EMU%" (
  echo Android Emulator not found: %EMU%
  echo Install it in Android Studio: SDK Manager ^> SDK Tools ^> Android Emulator.
  pause & exit /b 1
)

rem ---- Already running? go straight to the app -------------------------
"%ADB%" devices | findstr /b "emulator-" >nul && goto run

rem ---- Pick the virtual phone: the name given, or the first one ---------
set "AVD=%~1"
if not defined AVD (
  for /f "delims=" %%a in ('call "%EMU%" -list-avds 2^>nul ^| findstr /v /c:"|"') do (
    if not defined AVD set "AVD=%%a"
  )
)
if not defined AVD (
  echo No virtual phone found.
  echo Create one in Android Studio: Device Manager ^> + ^> Create Virtual Device
  echo ^(e.g. Pixel 8, system image API 34 or 35^), then run this file again.
  pause & exit /b 1
)

echo Starting virtual phone: %AVD%
start "Android Emulator" "%EMU%" -avd "%AVD%"

echo Waiting for it to finish booting (first start can take 1-3 minutes)...
"%ADB%" -e wait-for-device
:boot
set "BOOT="
for /f "delims=" %%b in ('call "%ADB%" -e shell getprop sys.boot_completed 2^>nul') do set "BOOT=%%b"
if not "!BOOT!"=="1" (
  timeout /t 2 /nobreak >nul
  goto boot
)

:run
echo.
echo Running Alathar on the emulator...
echo   r = hot reload   R = hot restart   q = quit
echo.
call flutter run -d emulator
pause
