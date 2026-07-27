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

function Enable-MueddaTheme([string]$Project) {
  $candidates = @(
    (Join-Path $Project "lib\app\app.dart"),
    (Join-Path $Project "lib\main.dart")
  )
  $appFile = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $appFile) {
    Write-Host "Aviso: app.dart/main.dart não encontrado para ligação automática do tema." -ForegroundColor Yellow
    return
  }

  $content = Get-Content $appFile -Raw
  if ($content -notmatch "app_theme.dart") {
    $content = "import 'theme/app_theme.dart';`r`n" + $content
    if ($appFile.EndsWith("main.dart")) {
      $content = $content.Replace("import 'theme/app_theme.dart';", "import 'app/theme/app_theme.dart';")
    }
  }

  if ($content -match "MaterialApp\.router\s*\(") {
    if ($content -notmatch "darkTheme\s*:") {
      $content = [regex]::Replace(
        $content,
        "MaterialApp\.router\s*\(",
        "MaterialApp.router(`r`n      theme: AppTheme.light,`r`n      darkTheme: AppTheme.dark,`r`n      themeMode: ThemeMode.system,",
        1
      )
    } else {
      $content = [regex]::Replace($content, "theme\s*:\s*[^,]+,", "theme: AppTheme.light,", 1)
      $content = [regex]::Replace($content, "darkTheme\s*:\s*[^,]+,", "darkTheme: AppTheme.dark,", 1)
      if ($content -match "themeMode\s*:") {
        $content = [regex]::Replace($content, "themeMode\s*:\s*[^,]+,", "themeMode: ThemeMode.system,", 1)
      }
    }
    Set-Content $appFile $content -Encoding UTF8
    Write-Host "Tema claro/escuro ligado em: $appFile" -ForegroundColor Green
  } else {
    Write-Host "Aviso: MaterialApp.router não foi localizado. Confira o LEIA-ME_V11.txt." -ForegroundColor Yellow
  }
}

$project = Resolve-MueddaProject $ProjectPath
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw "Flutter não foi encontrado no PATH." }
if (-not (Get-Command dart -ErrorAction SilentlyContinue)) { throw "Dart não foi encontrado no PATH." }

$sourceLib = Join-Path $PSScriptRoot "lib"
if (-not (Test-Path $sourceLib)) { throw "A pasta lib do pacote não foi encontrada." }

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backup = Join-Path $project "backup_muedda_design_v11_$stamp"
$log = Join-Path $project "muedda_analyze_v11.txt"

Write-Host "Criando backup completo da pasta lib..." -ForegroundColor Cyan
Copy-Item (Join-Path $project "lib") $backup -Recurse -Force

try {
  Write-Host "Aplicando telas e correções finais..." -ForegroundColor Cyan
  Copy-Item (Join-Path $sourceLib "*") (Join-Path $project "lib") -Recurse -Force
  Enable-MueddaTheme $project

  Push-Location $project
  try {
    dart format lib
    flutter clean
    flutter pub get
    $analysis = flutter analyze 2>&1
    $analysis | Tee-Object -FilePath $log
    $analyzeExit = $LASTEXITCODE

    if ($analyzeExit -ne 0 -and $ReverterSeFalhar) {
      Pop-Location
      Remove-Item (Join-Path $project "lib") -Recurse -Force
      Copy-Item $backup (Join-Path $project "lib") -Recurse -Force
      throw "A atualização foi revertida porque flutter analyze encontrou erros."
    }
  } finally {
    if ((Get-Location).Path -eq $project) { Pop-Location }
  }

  Write-Host "" 
  Write-Host "Design V11 aplicado." -ForegroundColor Green
  Write-Host "Backup: $backup" -ForegroundColor Green
  Write-Host "Relatório: $log" -ForegroundColor Green
  Write-Host "Execute agora: flutter run" -ForegroundColor Yellow
} catch {
  Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red
  throw
}
