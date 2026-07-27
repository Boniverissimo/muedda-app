param(
  [string]$ProjectPath = "C:\Users\Financeiro\Desktop\meu_app",
  [switch]$ReverterSeFalhar
)

$ErrorActionPreference = "Stop"

function Resolve-MueddaProject([string]$Path) {
  try { $resolved = (Resolve-Path $Path).Path } catch { throw "Projeto não encontrado em: $Path" }
  if (-not (Test-Path (Join-Path $resolved "pubspec.yaml"))) {
    throw "pubspec.yaml não encontrado em: $resolved"
  }
  return $resolved
}

$project = Resolve-MueddaProject $ProjectPath
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw "Flutter não foi encontrado no PATH." }
if (-not (Get-Command dart -ErrorAction SilentlyContinue)) { throw "Dart não foi encontrado no PATH." }

$sourceLib = Join-Path $PSScriptRoot "lib"
if (-not (Test-Path $sourceLib)) { throw "A pasta lib do pacote não foi encontrada: $sourceLib" }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $project "backup_muedda_design_v9_$stamp"
$log = Join-Path $project "muedda_analyze_v9.txt"
$installLog = Join-Path $project "muedda_install_v9.txt"

"Início: $(Get-Date -Format s)" | Set-Content $installLog -Encoding UTF8
"Projeto: $project" | Add-Content $installLog
"Backup: $backup" | Add-Content $installLog

Write-Host "Criando backup completo da pasta lib..." -ForegroundColor Cyan
Copy-Item (Join-Path $project "lib") $backup -Recurse -Force

try {
  Write-Host "Aplicando o Design de Conclusão V9..." -ForegroundColor Cyan
  Copy-Item (Join-Path $sourceLib "*") (Join-Path $project "lib") -Recurse -Force

  Push-Location $project
  try {
    Write-Host "Formatando arquivos..." -ForegroundColor Cyan
    dart format lib 2>&1 | Tee-Object -FilePath $installLog -Append

    Write-Host "Atualizando dependências..." -ForegroundColor Cyan
    flutter pub get 2>&1 | Tee-Object -FilePath $installLog -Append

    Write-Host "Executando flutter analyze..." -ForegroundColor Cyan
    $analyzeOutput = flutter analyze 2>&1
    $analyzeOutput | Tee-Object -FilePath $log
    $analyzeExit = $LASTEXITCODE

    if ($analyzeExit -ne 0) {
      Write-Host "A análise encontrou problemas. Consulte: $log" -ForegroundColor Yellow
      if ($ReverterSeFalhar) {
        Write-Host "Revertendo automaticamente para o backup..." -ForegroundColor Yellow
        Remove-Item (Join-Path $project "lib") -Recurse -Force
        Copy-Item $backup (Join-Path $project "lib") -Recurse -Force
        throw "Instalação revertida porque flutter analyze retornou erros."
      }
    } else {
      Write-Host "Flutter analyze concluído sem erros." -ForegroundColor Green
    }
  } finally {
    Pop-Location
  }

  Write-Host ""
  Write-Host "Design V9 aplicado." -ForegroundColor Green
  Write-Host "Backup: $backup" -ForegroundColor Green
  Write-Host "Relatório: $log" -ForegroundColor Green
  Write-Host "Agora execute: flutter run" -ForegroundColor Yellow
} catch {
  "ERRO: $($_.Exception.Message)" | Add-Content $installLog
  throw
}
