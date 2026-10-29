param([string]$Flutter = 'C:\flutter\bin\flutter.bat')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$betaRoot = Split-Path $PSScriptRoot -Parent
Push-Location $betaRoot
try {
    $betaBranch = git branch --show-current
    if ($betaBranch -ne 'beta/android-integrated-five-subjects') { throw 'Use the isolated integrated beta branch.' }
    if (git status --porcelain) { throw 'Commit the reviewed implementation before building its receipt.' }
    $betaBackend = Join-Path (Split-Path $betaRoot -Parent) 'ilm-ai-beta'
    if ((git -C $betaBackend branch --show-current) -ne $betaBranch -or (git -C $betaBackend status --porcelain)) {
        throw 'The corresponding isolated beta backend must be committed and clean.'
    }
    $ErrorActionPreference = 'Continue'
    & $Flutter build apk --debug --no-pub -t lib/main.dart `
        --dart-define=INTEGRATED_BETA=true `
        --dart-define=API_URL=http://127.0.0.1:8930
    $betaBuildExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($betaBuildExit -ne 0) { throw 'Integrated beta debug build failed.' }
    $betaApk = Get-Item -LiteralPath (Join-Path $betaRoot 'build\app\outputs\flutter-apk\app-debug.apk')
    $betaReceipt = [ordered]@{
        apk = $betaApk.FullName; bytes = $betaApk.Length
        sha256 = (Get-FileHash -LiteralPath $betaApk.FullName -Algorithm SHA256).Hash
        flutter_commit = (git rev-parse HEAD)
        backend_commit = (git -C $betaBackend rev-parse HEAD)
        branch = $betaBranch; application_id = 'com.ilmai.app.beta'
        label = 'ILM AI Beta'; entrypoint = 'lib/main.dart'
        mode = 'debug'; api = 'http://127.0.0.1:8930'
        created_utc = [DateTime]::UtcNow.ToString('o')
    }
    $betaReceipt | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $betaApk.DirectoryName 'integrated-beta-build.json') -Encoding UTF8
    $betaReceipt | ConvertTo-Json
} finally { Pop-Location }
