param(
  [string]$ProjectPath = ".",
  [switch]$SkipAnalyze
)

$ErrorActionPreference = "Stop"
$ProjectPath = (Resolve-Path $ProjectPath).Path
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $ProjectPath "backup_muedda_v6_$timestamp"

if (-not (Test-Path (Join-Path $ProjectPath "pubspec.yaml"))) {
  throw "pubspec.yaml não encontrado em $ProjectPath. Execute na raiz do projeto Flutter."
}

Write-Host "Criando backup em $backup" -ForegroundColor Cyan
New-Item -ItemType Directory -Path $backup | Out-Null
Copy-Item (Join-Path $ProjectPath "lib") $backup -Recurse -Force

Write-Host "Aplicando arquivos da V6..." -ForegroundColor Cyan
Copy-Item (Join-Path $PackageRoot "lib\*") (Join-Path $ProjectPath "lib") -Recurse -Force

Push-Location $ProjectPath
try {
  dart format lib
  flutter pub get
  if (-not $SkipAnalyze) {
    flutter analyze 2>&1 | Tee-Object -FilePath "muedda_analyze_v6.txt"
  }
  Write-Host "V6 aplicada. Backup: $backup" -ForegroundColor Green
} catch {
  Write-Host "Falha durante a validação. Seus arquivos originais estão em $backup" -ForegroundColor Yellow
  throw
} finally {
  Pop-Location
}
