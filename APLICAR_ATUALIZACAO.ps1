$ErrorActionPreference = "Stop"

Write-Host "Muedda - Aplicacao do Pacote Figma V3" -ForegroundColor Cyan

$packageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Get-Location
$pubspec = Join-Path $projectRoot "pubspec.yaml"

if (-not (Test-Path $pubspec)) {
  Write-Host "ERRO: execute este script na pasta raiz do projeto Flutter (onde fica pubspec.yaml)." -ForegroundColor Red
  exit 1
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $projectRoot "backup_muedda_$timestamp"

Write-Host "1/5 Criando backup em $backupDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
Copy-Item -Path (Join-Path $projectRoot "lib") -Destination $backupDir -Recurse -Force

Write-Host "2/5 Copiando arquivos do pacote" -ForegroundColor Yellow
Copy-Item -Path (Join-Path $packageRoot "lib\*") -Destination (Join-Path $projectRoot "lib") -Recurse -Force

Write-Host "3/5 Formatando codigo" -ForegroundColor Yellow
dart format lib

Write-Host "4/5 Atualizando dependencias" -ForegroundColor Yellow
flutter pub get

Write-Host "5/5 Executando analise" -ForegroundColor Yellow
flutter analyze

Write-Host "Pacote aplicado. Backup criado em: $backupDir" -ForegroundColor Green
Write-Host "Agora execute: flutter run" -ForegroundColor Green
