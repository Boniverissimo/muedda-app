$ErrorActionPreference = "Continue"
Write-Host "Validacao Muedda" -ForegroundColor Cyan
flutter doctor -v
dart format --output=none --set-exit-if-changed lib
flutter analyze
flutter test
