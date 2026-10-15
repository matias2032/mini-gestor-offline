@echo off
setlocal
title Mini - Launcher (backend + Flutter)

REM ============================================================
REM  Mini - arranque de desenvolvimento
REM  1. Le a chave privada de C:\mini\keys\private.b64 (so em memoria)
REM  2. Arranca o backend numa janela propria (se ainda nao estiver ativo)
REM  3. Espera o /actuator/health responder 200
REM  4. Arranca o Flutter Windows apontando para o backend local
REM ============================================================

set "KEY_FILE=C:\mini\keys\private.b64"
set "SERVER_DIR=C:\mini\license_server"
set "APP_DIR=C:\mini\app_mini"
set "API_URL=http://localhost:8080"
set "MAX_TRIES=60"

echo ========================================
echo  Mini - a preparar ambiente de dev
echo ========================================
echo.

REM --- Backend ja esta a correr? ---
call :health
if "%CODE%"=="200" (
    echo [INFO] Backend ja esta ativo em %API_URL%. A reutilizar.
    goto START_FLUTTER
)

REM --- Chave privada (o servidor nao consegue assinar sem ela) ---
if not exist "%KEY_FILE%" (
    echo [ERRO] Nao encontrei %KEY_FILE%
    echo        Gera o par com GenKey.java antes de continuar.
    goto END
)
set /p LICENSE_PRIVATE_KEY=<"%KEY_FILE%"
if "%LICENSE_PRIVATE_KEY%"=="" (
    echo [ERRO] %KEY_FILE% esta vazio.
    goto END
)

echo [INFO] A iniciar backend ^(perfil dev, com chave de assinatura^)...
REM A nova janela herda LICENSE_PRIVATE_KEY. O devtools nao e usado para recarregar a chave:
REM se mudares a chave ou o pom.xml, fecha a janela do backend e corre este .bat de novo.
start "Mini - Backend" /d "%SERVER_DIR%" cmd /k mvnw.cmd spring-boot:run -Dspring-boot.run.profiles=dev

REM Limpa a chave desta janela: o Flutter nao precisa dela
set "LICENSE_PRIVATE_KEY="

echo [INFO] A esperar o backend ficar pronto ^(ate %MAX_TRIES% tentativas de 2 s^)...
set /a TRIES=0

:WAIT
set /a TRIES+=1
call :health
if "%CODE%"=="200" goto READY
if %TRIES% GEQ %MAX_TRIES% goto TIMEOUT
timeout /t 2 /nobreak >nul
goto WAIT

:TIMEOUT
echo.
echo [ERRO] O backend nao respondeu a tempo. Ve a janela "Mini - Backend".
goto END

:READY
echo [OK] Backend pronto ^(%TRIES% tentativas^).
echo [INFO] Confirma na janela do backend que NAO aparece o WARN "license.private-key vazia".

:START_FLUTTER
echo.
echo ========================================
echo  Starting Flutter Windows Launcher...
echo ========================================
echo [INFO] Backend: %API_URL%
echo.

cd /d "%APP_DIR%"
flutter run -d windows --dart-define=API_BASE_URL=%API_URL%

echo.
echo ========================================
echo   Flutter encerrado. O backend continua
echo   na janela "Mini - Backend" (fecha-a
echo   quando terminares).
echo ========================================

:END
pause
endlocal
exit /b

REM --- sub-rotina: devolve o codigo HTTP do health em %CODE% ---
:health
set "CODE=000"
for /f %%C in ('curl.exe -s -o nul -w "%%{http_code}" %API_URL%/actuator/health 2^>nul') do set "CODE=%%C"
exit /b