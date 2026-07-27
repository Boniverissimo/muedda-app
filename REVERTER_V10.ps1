param(
  [string]$ProjectPath = "C:\Users\Financeiro\Desktop\meu_app",
  [Parameter(Mandatory=$true)][string]$BackupPath
)
$ErrorActionPreference = "Stop"
$project = (Resolve-Path $ProjectPath).Path
$backup = (Resolve-Path $BackupPath).Path
if (-not (Test-Path (Join-Path $backup "app")) -and -not (Test-Path (Join-Path $backup "features"))) {
  throw "O backup informado não parece conter uma pasta lib válida."
}
Remove-Item (Join-Path $project "lib") -Recurse -Force
Copy-Item $backup (Join-Path $project "lib") -Recurse -Force
Write-Host "Backup restaurado com sucesso." -ForegroundColor Green
