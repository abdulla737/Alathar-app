@echo off
cd /d "%~dp0"
echo Building Alathar APK... (log: build_log.txt)
echo ===== %date% %time% ===== > build_log.txt
if exist lib\screens\tawheed_screen.dart (
  if not exist _to_delete mkdir _to_delete
  move /y lib\screens\tawheed_screen.dart _to_delete\ >> build_log.txt 2>&1
)
echo ----- flutter clean >> build_log.txt
call flutter clean >> build_log.txt 2>&1
echo ----- flutter pub get >> build_log.txt
call flutter pub get >> build_log.txt 2>&1
echo ----- flutter build apk --debug >> build_log.txt
call flutter build apk --debug >> build_log.txt 2>&1
echo EXIT CODE %errorlevel% >> build_log.txt
if exist build\app\outputs\flutter-apk\app-debug.apk (
  echo APK READY: build\app\outputs\flutter-apk\app-debug.apk >> build_log.txt
  echo.
  echo DONE - APK is in build\app\outputs\flutter-apk
  explorer build\app\outputs\flutter-apk
) else (
  echo.
  echo BUILD FAILED - see build_log.txt
)
pause
