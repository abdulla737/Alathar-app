@echo off
setlocal
cd /d "%~dp0"
title Alathar - build Android APK

rem  Builds the Android app (APK) you can install on any Android phone.
rem    build_apk.bat           -> release APK (small and fast, for phones)
rem    build_apk.bat debug     -> debug APK (for testing with flutter run)
rem  The finished file is copied to the "apk" folder as Alathar-<date>.apk.

set "MODE=release"
if /i "%~1"=="debug" set "MODE=debug"

where flutter >nul 2>&1
if errorlevel 1 (
  echo Flutter was not found. Install Flutter and add it to PATH, then try again.
  pause & exit /b 1
)

echo Building Alathar APK (%MODE%)... this takes a few minutes.
echo Log: build_log.txt
echo ===== %date% %time%  mode=%MODE% ===== > build_log.txt

rem Old leftover file that breaks the build, if it is still there.
if exist lib\screens\tawheed_screen.dart (
  if not exist _to_delete mkdir _to_delete
  move /y lib\screens\tawheed_screen.dart _to_delete\ >> build_log.txt 2>&1
)

echo [1/3] Cleaning...
echo ----- flutter clean >> build_log.txt
call flutter clean >> build_log.txt 2>&1

echo [2/3] Getting packages...
echo ----- flutter pub get >> build_log.txt
call flutter pub get >> build_log.txt 2>&1

echo [3/3] Building APK...
echo ----- flutter build apk --%MODE% >> build_log.txt
call flutter build apk --%MODE% >> build_log.txt 2>&1
echo EXIT CODE %errorlevel% >> build_log.txt

set "OUT=build\app\outputs\flutter-apk\app-%MODE%.apk"
if not exist "%OUT%" (
  echo.
  echo BUILD FAILED - open build_log.txt and send the last lines.
  pause & exit /b 1
)

rem Date stamp like 2026-10-20 for the file name.
for /f %%d in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HHmm"') do set "STAMP=%%d"
if not exist apk mkdir apk
set "NAME=Alathar-%STAMP%"
if /i "%MODE%"=="debug" set "NAME=%NAME%-debug"
copy /y "%OUT%" "apk\%NAME%.apk" >nul

echo APK READY: apk\%NAME%.apk >> build_log.txt
echo.
echo DONE - apk\%NAME%.apk
echo Send this file to an Android phone and open it to install.
explorer apk
pause
