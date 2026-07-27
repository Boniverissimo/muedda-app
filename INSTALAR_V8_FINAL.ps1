param(
  [string]$ProjectPath = "C:\Users\Financeiro\Desktop\meu_app"
)

$ErrorActionPreference = "Stop"

try {
  $project = (Resolve-Path $ProjectPath).Path
} catch {
  throw "Projeto não encontrado em: $ProjectPath"
}

if (-not (Test-Path (Join-Path $project "pubspec.yaml"))) {
  throw "pubspec.yaml não encontrado em: $project"
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter não foi encontrado no PATH do Windows."
}

$sourceLib = Join-Path $PSScriptRoot "lib"
if (-not (Test-Path $sourceLib)) {
  throw "A pasta lib do pacote não foi encontrada: $sourceLib"
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $project "backup_muedda_design_v8_$stamp"
$log = Join-Path $project "muedda_analyze_v8.txt"

Write-Host "Criando backup em $backup" -ForegroundColor Cyan
Copy-Item (Join-Path $project "lib") $backup -Recurse -Force

Write-Host "Aplicando o Design Final V8..." -ForegroundColor Cyan
Copy-Item (Join-Path $sourceLib "*") (Join-Path $project "lib") -Recurse -Force

Push-Location $project
try {
  Write-Host "Formatando arquivos..." -ForegroundColor Cyan
  dart format lib

  Write-Host "Atualizando dependências..." -ForegroundColor Cyan
  flutter pub get

  Write-Host "Executando análise..." -ForegroundColor Cyan
  flutter analyze 2>&1 | Tee-Object -FilePath $log

  Write-Host "" 
  Write-Host "Design V8 aplicado." -ForegroundColor Green
  Write-Host "Backup: $backup" -ForegroundColor Green
  Write-Host "Relatório: $log" -ForegroundColor Green
  Write-Host "Agora execute: flutter run" -ForegroundColor Yellow
} finally {
  Pop-Location
}
