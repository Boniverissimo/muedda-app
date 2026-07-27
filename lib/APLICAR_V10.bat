@echo off
chcp 65001 >nul
setlocal
set "PROJECT=C:\Users\Financeiro\Desktop\meu_app"

echo ==================================================
echo       MUEDDA - DESIGN COMPLETO V10
echo ==================================================
echo.

if not exist "%PROJECT%\pubspec.yaml" (
  echo Projeto padrao nao encontrado em:
  echo %PROJECT%
  echo.
  set /p PROJECT=Digite ou cole o caminho completo do projeto: 
)

if not exist "%PROJECT%\pubspec.yaml" (
  echo.
  echo ERRO: pubspec.yaml nao encontrado em "%PROJECT%".
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALAR_V10_FINAL.ps1" -ProjectPath "%PROJECT%"

if errorlevel 1 (
  echo.
  echo A instalacao encontrou um erro. Consulte os relatorios na pasta do projeto.
) else (
  echo.
  echo Design completo aplicado. Execute flutter run na pasta do projeto.
)

echo.
pause
endlocal
