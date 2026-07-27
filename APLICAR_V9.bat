@echo off
chcp 65001 >nul
setlocal
set "PROJECT=C:\Users\Financeiro\Desktop\meu_app"

echo ================================================
echo        MUEDDA - DESIGN DE CONCLUSAO V9
echo ================================================
echo.

if not exist "%PROJECT%\pubspec.yaml" (
  echo Projeto padrão não encontrado.
  set /p PROJECT=Digite ou cole o caminho completo do projeto: 
)

if not exist "%PROJECT%\pubspec.yaml" (
  echo.
  echo ERRO: pubspec.yaml não encontrado em "%PROJECT%".
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALAR_V9_FINAL.ps1" -ProjectPath "%PROJECT%"

if errorlevel 1 (
  echo.
  echo A instalação encontrou um erro. Consulte a mensagem e o relatório gerado.
) else (
  echo.
  echo Design aplicado. Agora execute flutter run na pasta do projeto.
)

echo.
pause
endlocal
