@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
title Alathar - collect phone log

rem  Installs the newest APK from the "apk" folder on a connected Android
rem  phone (USB debugging on) or a running emulator, opens Alathar, and saves
rem  what the app prints while starting to phone_log.txt.

set "SDK=%LOCALAPPDATA%\Android\Sdk"
if defined ANDROID_HOME set "SDK=%ANDROID_HOME%"
set "ADB=%SDK%\platform-tools\adb.exe"
if not exist "%ADB%" (
  echo adb not found: %ADB%
  pause & exit /b 1
)

"%ADB%" start-server >nul 2>&1
set "DEV="
for /f "skip=1 tokens=1,2" %%a in ('"%ADB%" devices') do (
  if "%%b"=="device" if not defined DEV set "DEV=%%a"
)
if not defined DEV (
  echo No phone or emulator found.
  echo  - Phone: Settings ^> Developer options ^> USB debugging ON, connect the cable,
  echo    and tap "Allow" on the phone.
  echo  - Or start the emulator with run_emulator.bat first.
  pause & exit /b 1
)
echo Using device: %DEV%

set "APK="
for /f "delims=" %%f in ('dir /b /o-d apk\*.apk 2^>nul') do if not defined APK set "APK=apk\%%f"
if defined APK (
  echo Installing %APK% ...
  "%ADB%" -s %DEV% install -r "%APK%"
) else (
  echo No APK in the apk folder - using the app already on the device.
)

echo Starting Alathar and recording for 25 seconds...
"%ADB%" -s %DEV% logcat -c
"%ADB%" -s %DEV% shell am force-stop com.hadeeth.alathar
"%ADB%" -s %DEV% shell monkey -p com.hadeeth.alathar -c android.intent.category.LAUNCHER 1 >nul 2>&1
timeout /t 25 /nobreak >nul

> phone_log.txt echo ===== %date% %time%  device=%DEV%  apk=%APK% =====
"%ADB%" -s %DEV% logcat -d -v time *:W flutter:V >> phone_log.txt
echo.
echo Saved phone_log.txt - tell Claude it is ready.
pause
