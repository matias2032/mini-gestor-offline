
@echo off
title ERP & PDV    Flutter Launcher

@REM gorillas

echo ========================================
echo  Starting Flutter Windows Launcher...
echo ========================================

echo.
echo [INFO] A iniciar Flutter Windows apontando para localhost...
echo [INFO] Backend: 
echo.

cd /d "C:\mini\app_mini"

flutter run -d windows --dart-define=API_BASE_URL=http://localhost:8080

echo.
echo ========================================
echo   Flutter encerrando...
echo ========================================

pause