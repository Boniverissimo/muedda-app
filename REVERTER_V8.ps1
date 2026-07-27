param(
  [Parameter(Mandatory=$true)][string]$BackupPath,
  [string]$ProjectPath = "C:\Users\Financeiro\Desktop\meu_app"
)
$ErrorActionPreference = "Stop"
$project = (Resolve-Path $ProjectPath).Path
$backup = (Resolve-Path $BackupPath).Path
if (-not (Test-Path (Join-Path $backup "features")) -and -not (Test-Path (Join-Path $backup "app"))) {
  throw "O caminho informado não parece ser um backup válido da pasta lib."
}
Remove-Item (Join-Path $project "lib") -Recurse -Force
Copy-Item $backup (Join-Path $project "lib") -Recurse -Force
Write-Host "Backup restaurado com sucesso." -ForegroundColor Green
