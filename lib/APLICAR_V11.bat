@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0INSTALAR_V11_FINAL.ps1" -ProjectPath "C:\Users\Financeiro\Desktop\meu_app"
echo.
pause
