$ErrorActionPreference = "Stop"

if (-not (Test-Path "pubspec.yaml")) {
  Write-Error "Execute este script na raiz do projeto Flutter, onde está o pubspec.yaml."
}

$orphan = "lib/features/transactions/presentation/pages/transaction_form_page_corrigido.dart"
if (Test-Path $orphan) {
  Remove-Item $orphan -Force
  Write-Host "Arquivo duplicado removido: $orphan"
}

Write-Host "Patch V0.9-01B aplicado. Agora execute:"
Write-Host "dart format ."
Write-Host "flutter analyze"
Write-Host "flutter test"
Write-Host "flutter run"
