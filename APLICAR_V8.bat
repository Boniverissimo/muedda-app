@echo off
chcp 65001 >nul
setlocal
set "PROJECT=C:\Users\Financeiro\Desktop\meu_app"

echo ================================================
echo       MUEDDA - DESIGN FINAL V8
echo ================================================
echo.
echo Projeto: %PROJECT%
echo.

if not exist "%PROJECT%\pubspec.yaml" (
  echo ERRO: pubspec.yaml nao encontrado em:
  echo %PROJECT%
  echo.
  set /p PROJECT=Digite o caminho completo do projeto: 
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALAR_V8_FINAL.ps1" -ProjectPath "%PROJECT%"

if errorlevel 1 (
  echo.
  echo A instalacao encontrou um erro. Leia a mensagem acima.
) else (
  echo.
  echo Atualizacao concluida. Abra o projeto e execute flutter run.
)

echo.
pause
endlocal
