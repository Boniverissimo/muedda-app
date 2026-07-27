@echo off
setlocal
set "PROJECT=C:\Users\Financeiro\Desktop\meu_app"
if not exist "%PROJECT%\pubspec.yaml" (
  echo Projeto nao encontrado em %PROJECT%
  pause
  exit /b 1
)
copy /Y "%~dp0lib\features\transactions\presentation\pages\transactions_page.dart" "%PROJECT%\lib\features\transactions\presentation\pages\transactions_page.dart"
cd /d "%PROJECT%"
dart format lib\features\transactions\presentation\pages\transactions_page.dart
flutter clean
flutter pub get
flutter analyze
pause
