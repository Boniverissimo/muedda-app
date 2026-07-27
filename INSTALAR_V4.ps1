param(
  [string]$ProjectPath = (Get-Location).Path,
  [switch]$SkipAnalyze
)
$ErrorActionPreference = 'Stop'
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectPath = (Resolve-Path $ProjectPath).Path
if (-not (Test-Path (Join-Path $ProjectPath 'pubspec.yaml'))) {
  throw 'Execute apontando para a raiz do projeto Flutter, onde está o pubspec.yaml.'
}
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path $ProjectPath "backup_muedda_v4_$stamp"
New-Item -ItemType Directory -Path $backup | Out-Null
if (Test-Path (Join-Path $ProjectPath 'lib')) {
  Copy-Item (Join-Path $ProjectPath 'lib') $backup -Recurse -Force
}
Copy-Item (Join-Path $PackageRoot 'lib\*') (Join-Path $ProjectPath 'lib') -Recurse -Force
Push-Location $ProjectPath
try {
  dart format lib
  flutter pub get
  if (-not $SkipAnalyze) { flutter analyze }
  Write-Host "Atualização V4 aplicada. Backup: $backup" -ForegroundColor Green
} finally { Pop-Location }
