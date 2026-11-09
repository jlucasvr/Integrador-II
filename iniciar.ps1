param(
    [ValidateSet('run', 'check', 'build', 'integration', 'package')][string]$Action = 'run',
    [switch]$Api,
    [string]$ApiBaseUrl = $env:API_BASE_URL,
    [string]$FlutterSdk,
    [switch]$Offline
)
$ErrorActionPreference = 'Stop'
if ($Action -eq 'package') {
    $searchDefines = @('--dart-define=API_BASE_URL=/api/v1', '--dart-define=MOCK_SEARCH=false', '--dart-define=LOCAL_EVALUATION=true')
} elseif ($Api -and $Action -ne 'integration') {
    if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
        if ($Action -eq 'build') { throw 'Informe -ApiBaseUrl ou defina API_BASE_URL para gerar o build em modo API.' }
        $ApiBaseUrl = 'http://127.0.0.1:3000/api/v1'
    }
    [Uri]$parsedApiUrl = $null
    if (-not [Uri]::TryCreate($ApiBaseUrl, [UriKind]::Absolute, [ref]$parsedApiUrl) -or
        $parsedApiUrl.Scheme -notin @('http', 'https') -or -not $parsedApiUrl.Host -or
        $parsedApiUrl.UserInfo -or $parsedApiUrl.Query -or $parsedApiUrl.Fragment) {
        throw 'Informe uma URL HTTP ou HTTPS da API sem credenciais, consulta ou fragmento.'
    }
    $searchDefines = @("--dart-define=API_BASE_URL=$($parsedApiUrl.AbsoluteUri)", '--dart-define=MOCK_SEARCH=false')
} else {
    $searchDefines = @('--dart-define=MOCK_SEARCH=true')
}
if ($FlutterSdk) {
    $sdkPath = Join-Path $FlutterSdk 'bin\flutter.bat'
} else {
    $flutterCommand = Get-Command flutter.bat -ErrorAction SilentlyContinue
    $sdkPath = if ($flutterCommand) { $flutterCommand.Source } else {
        Join-Path $env:USERPROFILE 'Downloads\flutter\bin\flutter.bat'
    }
}
if (-not (Test-Path -LiteralPath $sdkPath)) {
    throw 'Flutter nao encontrado. Adicione flutter\bin ao PATH ou informe -FlutterSdk com a pasta do SDK.'
}
$sdkBin = Split-Path -Parent (Resolve-Path -LiteralPath $sdkPath).Path
$sdkRoot = Split-Path -Parent $sdkBin
$aliases = [System.Collections.Generic.List[string]]::new()
function Get-AsciiPath([string]$Directory) {
    if ($Directory -notmatch '[^\x00-\x7F]') { return $Directory }
    $drive = @('R','S','T','U','V','W','X','Y','Z') | Where-Object {
        -not (Test-Path "${_}:\") -and -not $aliases.Contains("${_}:")
    } | Select-Object -First 1
    if (-not $drive) { throw 'Nenhuma letra de unidade livre para o alias temporario.' }
    & subst "${drive}:" $Directory
    if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel criar o alias temporario.' }
    $aliases.Add("${drive}:")
    return "${drive}:\"
}

function Invoke-IsolatedIntegration {
    $previousPath = $env:Path
    try {
        $env:Path = "$(Split-Path -Parent $flutterPath);$previousPath"
        & node tool/run_management_live_check.mjs
        if ($LASTEXITCODE -ne 0) { throw 'Falha na integracao isolada.' }
    } finally {
        $env:Path = $previousPath
    }
}

$projectPushed = $false
$dependenciesReady = $false
try {
    $projectPath = Get-AsciiPath $PSScriptRoot
    $flutterPath = Join-Path (Get-AsciiPath $sdkRoot) 'bin\flutter.bat'
    Push-Location -LiteralPath $projectPath
    $projectPushed = $true
    $pubOptions = @('--enforce-lockfile')
    if ($Offline) { $pubOptions += '--offline' }
    & $flutterPath pub get @pubOptions
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao obter dependencias.' }
    $dependenciesReady = $true
    if ($Action -eq 'integration') {
        Invoke-IsolatedIntegration
        return
    }
    if ($Action -eq 'check') {
        & $flutterPath analyze --no-pub
        if ($LASTEXITCODE -ne 0) { throw 'Falha na analise.' }
        & $flutterPath test --no-pub
        if ($LASTEXITCODE -ne 0) { throw 'Falha nos testes.' }
        if ($Api) {
            & npm.cmd test --prefix backend
            if ($LASTEXITCODE -ne 0) { throw 'Falha nos testes da API.' }
            Invoke-IsolatedIntegration
        }
    }
    if ($Action -eq 'package') {
        $packagePath = "build/entrega-local-$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')"
        & $flutterPath build web --no-pub "--output=$packagePath/web" @searchDefines
        if ($LASTEXITCODE -ne 0) { throw 'Falha na compilacao do pacote.' }
        New-Item -ItemType Directory -Path "$packagePath/backend" | Out-Null
        Copy-Item -LiteralPath @('backend/src', 'backend/package.json', 'backend/package-lock.json') -Destination "$packagePath/backend" -Recurse
        Copy-Item -LiteralPath 'ENTREGA_LOCAL.md' -Destination $packagePath
        Write-Output "Pacote local em $packagePath"
    } elseif ($Action -in @('check','build')) {
        & $flutterPath build web --no-pub @searchDefines
        if ($LASTEXITCODE -ne 0) { throw 'Falha na compilacao web.' }
    } else {
        & $flutterPath run --no-pub -d edge @searchDefines
    }
} finally {
    if ($projectPushed) { Pop-Location }
    try {
        if ($aliases.Count -gt 0 -and $dependenciesReady) {
            # Restaura caminhos permanentes antes de remover os aliases.
            Push-Location -LiteralPath $PSScriptRoot
            try { & $sdkPath pub get --offline --enforce-lockfile } finally { Pop-Location }
        }
    } finally {
        foreach ($aliasDrive in $aliases) { & subst $aliasDrive /d }
    }
}


