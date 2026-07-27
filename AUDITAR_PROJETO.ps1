param([string]$ProjectPath = ".")
$ErrorActionPreference = "Stop"
$project = (Resolve-Path $ProjectPath).Path
if (-not (Test-Path (Join-Path $project "pubspec.yaml"))) { throw "pubspec.yaml não encontrado." }
Set-Location $project
Write-Host "[1/5] Formatando..." -ForegroundColor Cyan
dart format lib
Write-Host "[2/5] Dependências..." -ForegroundColor Cyan
flutter pub get
Write-Host "[3/5] Análise estática..." -ForegroundColor Cyan
flutter analyze | Tee-Object -FilePath "muedda_analyze_v5.txt"
Write-Host "[4/5] Testes..." -ForegroundColor Cyan
flutter test | Tee-Object -FilePath "muedda_tests_v5.txt"
Write-Host "[5/5] Build web de validação..." -ForegroundColor Cyan
flutter build web --release | Tee-Object -FilePath "muedda_build_web_v5.txt"
Write-Host "Auditoria concluída. Relatórios salvos na raiz do projeto." -ForegroundColor Green
