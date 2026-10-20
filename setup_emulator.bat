@echo off
setlocal
cd /d "%~dp0"
title Alathar - set up Android emulator (one time)

rem ---- Android SDK and its command-line tools ----------------------------
set "SDK=%LOCALAPPDATA%\Android\Sdk"
if defined ANDROID_HOME set "SDK=%ANDROID_HOME%"
set "SDKM=%SDK%\cmdline-tools\latest\bin\sdkmanager.bat"
set "AVDM=%SDK%\cmdline-tools\latest\bin\avdmanager.bat"
if not exist "%SDKM%" (
  echo sdkmanager not found: %SDKM%
  pause & exit /b 1
)

rem ---- Java: use the one bundled with Android Studio if none is set -------
if not defined JAVA_HOME (
  if exist "%ProgramFiles%\Android\Android Studio\jbr\bin\java.exe" set "JAVA_HOME=%ProgramFiles%\Android\Android Studio\jbr"
)

set "IMG=system-images;android-35;google_apis;x86_64"
set "AVD=Alathar_Pixel"

echo.
echo [1/3] Downloading the Android Emulator and a phone system image (about 1.5 GB).
echo       If asked to accept a licence, read it and type  y  then Enter.
echo.
call "%SDKM%" "emulator" "platform-tools" "%IMG%"
if errorlevel 1 (
  echo Download failed - check the internet connection and try again.
  pause & exit /b 1
)

echo.
echo [2/3] Creating the virtual phone "%AVD%" (Pixel 8)...
echo no| call "%AVDM%" create avd -n "%AVD%" -k "%IMG%" -d pixel_8 --force
if errorlevel 1 (
  echo Could not create the virtual phone.
  pause & exit /b 1
)

echo.
echo [3/3] Starting it and opening Alathar...
call "%~dp0run_emulator.bat" "%AVD%"
