@echo off
REM GradeBridge App - Quick Setup Script (Windows)
REM Run this to get your app running!

echo ==========================================
echo    GradeBridge - Quick Setup
echo ==========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo X Flutter is not installed!
    echo Download from: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('flutter --version') do set flutter_ver=%%i
echo + Flutter found: %flutter_ver%
echo.

REM Step 1: Get dependencies
echo Step 1: Installing dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo X Failed to install dependencies
    pause
    exit /b 1
)
echo + Dependencies installed successfully!
echo.

REM Step 2: Run the app
echo Step 2: Starting app with hot reload...
echo    - Save files ^> Hot reload automatically
echo    - Press 'R' ^> Manual hot reload
echo    - Press 'Shift+R' ^> Full restart
echo    - Press 'q' ^> Quit
echo.
echo Starting Flutter app...
echo.

call flutter run

echo.
echo ==========================================
echo    App stopped! Run again: flutter run
echo ==========================================
pause
