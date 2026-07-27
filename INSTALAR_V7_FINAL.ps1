param([string]$ProjectPath = ".")
$ErrorActionPreference = "Stop"
$project = (Resolve-Path $ProjectPath).Path
if (-not (Test-Path (Join-Path $project "pubspec.yaml"))) { throw "pubspec.yaml não encontrado." }
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $project "backup_muedda_v7_$stamp"
Copy-Item (Join-Path $project "lib") $backup -Recurse -Force
Copy-Item (Join-Path $PSScriptRoot "lib\*") (Join-Path $project "lib") -Recurse -Force
Push-Location $project
try {
  dart format lib
  flutter pub get
  flutter analyze 2>&1 | Tee-Object -FilePath "muedda_analyze_v7.txt"
} finally { Pop-Location }
Write-Host "V7 aplicada. Backup: $backup" -ForegroundColor Green
