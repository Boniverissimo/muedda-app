param(
  [Parameter(Mandatory=$true)][string]$BackupPath,
  [string]$ProjectPath = "."
)
$ErrorActionPreference = "Stop"
$ProjectPath = (Resolve-Path $ProjectPath).Path
$BackupPath = (Resolve-Path $BackupPath).Path
$source = Join-Path $BackupPath "lib"
if (-not (Test-Path $source)) { throw "Pasta lib não encontrada no backup informado." }
Remove-Item (Join-Path $ProjectPath "lib") -Recurse -Force
Copy-Item $source $ProjectPath -Recurse -Force
Write-Host "Backup restaurado com sucesso." -ForegroundColor Green
