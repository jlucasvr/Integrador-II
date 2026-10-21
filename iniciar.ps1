param([ValidateSet('run', 'check', 'build')][string]$Action = 'run', [switch]$Api)
$ErrorActionPreference = 'Stop'
# Alias temporario para contornar erros do Flutter com acentos no caminho.
$profileRoot = $env:USERPROFILE.TrimEnd('\')
if (-not $PSScriptRoot.StartsWith($profileRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Este script espera o projeto dentro da pasta do usuario.'
}
$sdkPath = Join-Path $profileRoot 'Downloads\flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $sdkPath)) {
    throw 'Flutter nao encontrado em Downloads\flutter. Atualize sdkPath neste script.'
}
$driveName = @('R','S','T','U','V','W','X','Y','Z') | Where-Object {
    -not (Test-Path "${_}:\")
} | Select-Object -First 1
if (-not $driveName) { throw 'Nenhuma letra de unidade livre para o alias temporario.' }
& subst "${driveName}:" $profileRoot
if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel criar o alias temporario.' }
$relativeProject = $PSScriptRoot.Substring($profileRoot.Length)
$projectAlias = "${driveName}:$relativeProject"
$flutterAlias = "${driveName}:\Downloads\flutter\bin\flutter.bat"
try {
    Push-Location -LiteralPath $projectAlias
    & $flutterAlias pub get
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao obter dependencias.' }
    if ($Action -eq 'check') {
        & $flutterAlias analyze
        if ($LASTEXITCODE -ne 0) { throw 'Falha na analise.' }
        & $flutterAlias test
        if ($LASTEXITCODE -ne 0) { throw 'Falha nos testes.' }
    }
    if ($Action -in @('check','build')) {
        if ($Api) {
            & $flutterAlias build web --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1
        } else {
            & $flutterAlias build web
        }
        if ($LASTEXITCODE -ne 0) { throw 'Falha na compilacao web.' }
    } else {
        if ($Api) {
            & $flutterAlias run -d edge --dart-define=API_BASE_URL=http://127.0.0.1:3000/api/v1
        } else {
            & $flutterAlias run -d edge
        }
    }
} finally {
    Pop-Location
    # Restaura caminhos permanentes para o editor ao encerrar o alias.
    Push-Location -LiteralPath $PSScriptRoot
    try { & $sdkPath pub get --offline } finally { Pop-Location }
    & subst "${driveName}:" /d
}


