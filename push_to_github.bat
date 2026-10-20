@echo off
setlocal
cd /d "%~dp0"
title Alathar - upload to GitHub
set "REPO=https://github.com/abdulla737/Alathar-app.git"

where git >nul 2>&1
if errorlevel 1 (
  echo Git is not installed. Install it from https://git-scm.com/download/win
  echo then run this file again.
  pause & exit /b 1
)

if not exist .git (
  git init -b main
)

rem Commit author (only for this project, if not already set)
git config user.name >nul 2>&1 || git config user.name "abdulla737"
git config user.email >nul 2>&1 || git config user.email "abdulla737@gmail.com"

git remote get-url origin >nul 2>&1 || git remote add origin %REPO%

git add -A
git commit -m "Alathar app update" >nul 2>&1
if errorlevel 1 echo (No new changes to commit)

echo.
echo Uploading to %REPO% ...
echo (A browser window may open the first time to sign in to GitHub.)
git push -u origin main
if errorlevel 1 (
  echo.
  echo Upload was refused. If the GitHub repository already has files
  echo ^(for example a README created on GitHub^), run this once:
  echo     git pull origin main --allow-unrelated-histories
  echo then run this file again.
)
echo.
pause
