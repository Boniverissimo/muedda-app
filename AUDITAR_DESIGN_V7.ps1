param([string]$ProjectPath = ".")
$ErrorActionPreference = "Stop"
$root = (Resolve-Path $ProjectPath).Path
$report = Join-Path $root "muedda_design_audit_v7.txt"
$patterns = @(
  "AppColors.surface",
  "AppColors.background",
  "Colors.white",
  "Scaffold\(",
  "showDialog\(",
  "showModalBottomSheet\("
)
"AUDITORIA VISUAL MUEDDA V7 - $(Get-Date)" | Set-Content $report
foreach ($pattern in $patterns) {
  "`n=== $pattern ===" | Add-Content $report
  Get-ChildItem "$root\lib" -Recurse -Filter *.dart |
    Select-String -Pattern $pattern |
    ForEach-Object { "$($_.Path):$($_.LineNumber): $($_.Line.Trim())" } |
    Add-Content $report
}
Write-Host "Relatório criado em: $report" -ForegroundColor Green
