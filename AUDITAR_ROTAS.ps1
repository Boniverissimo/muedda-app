param([string]$ProjectPath=(Get-Location).Path)
$ProjectPath=(Resolve-Path $ProjectPath).Path
$routes = Get-ChildItem (Join-Path $ProjectPath 'lib') -Recurse -Filter *.dart |
  Select-String -Pattern "context\.(push|go)\('([^']+)'" -AllMatches |
  ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[2].Value } | Sort-Object -Unique
Write-Host 'Rotas usadas pela apresentação:' -ForegroundColor Cyan
$routes | ForEach-Object { Write-Host " - $_" }
