param([Parameter(Mandatory=$true)][string]$BackupPath,[string]$ProjectPath=(Get-Location).Path)
$ErrorActionPreference='Stop'
$ProjectPath=(Resolve-Path $ProjectPath).Path
$BackupPath=(Resolve-Path $BackupPath).Path
if (-not (Test-Path (Join-Path $BackupPath 'lib'))) { throw 'O backup informado não contém a pasta lib.' }
Remove-Item (Join-Path $ProjectPath 'lib') -Recurse -Force
Copy-Item (Join-Path $BackupPath 'lib') (Join-Path $ProjectPath 'lib') -Recurse -Force
Write-Host 'Backup restaurado com sucesso.' -ForegroundColor Green
