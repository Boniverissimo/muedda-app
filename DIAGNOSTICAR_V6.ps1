param([string]$ProjectPath = ".")
$ErrorActionPreference = "Continue"
$ProjectPath = (Resolve-Path $ProjectPath).Path
Push-Location $ProjectPath
$report = "muedda_diagnostico_v6.txt"
"DIAGNÓSTICO MUEDDA V6 - $(Get-Date)" | Set-Content $report
"`n== FLUTTER DOCTOR ==" | Add-Content $report
flutter doctor -v 2>&1 | Add-Content $report
"`n== DEPENDÊNCIAS ==" | Add-Content $report
flutter pub get 2>&1 | Add-Content $report
"`n== ANÁLISE ==" | Add-Content $report
flutter analyze 2>&1 | Add-Content $report
"`n== TESTES ==" | Add-Content $report
flutter test 2>&1 | Add-Content $report
Pop-Location
Write-Host "Relatório salvo em $ProjectPath\$report" -ForegroundColor Cyan
