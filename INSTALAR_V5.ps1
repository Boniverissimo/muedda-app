param([string]$ProjectPath = ".")
$ErrorActionPreference = "Stop"
$project = (Resolve-Path $ProjectPath).Path
$package = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Test-Path (Join-Path $project "pubspec.yaml"))) { throw "pubspec.yaml não encontrado em $project" }
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $project "backup_muedda_v5_$stamp"
Write-Host "Criando backup em $backup" -ForegroundColor Cyan
Copy-Item (Join-Path $project "lib") $backup -Recurse -Force
Write-Host "Aplicando arquivos da V5..." -ForegroundColor Cyan
Copy-Item (Join-Path $package "lib\*") (Join-Path $project "lib") -Recurse -Force
Set-Location $project
dart format lib
flutter pub get
flutter analyze
Write-Host "V5 aplicada. Backup: $backup" -ForegroundColor Green
