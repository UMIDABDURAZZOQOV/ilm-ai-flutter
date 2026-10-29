param([string]$Flutter = 'C:\flutter\bin\flutter.bat')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$qaRoot = Split-Path $PSScriptRoot -Parent
Push-Location $qaRoot
try {
    $qaBranch = git branch --show-current
    if ($qaBranch -ne 'qa/android-five-subjects') { throw 'Use the isolated QA branch.' }
    # Windows PowerShell maps native stderr warnings to error records.
    # Determine success from Flutter's exit code, not warning stream routing.
    $ErrorActionPreference = 'Continue'
    & $Flutter build apk --debug --no-pub -t lib/phone_qa_main.dart `
        --dart-define=PHONE_QA=true `
        --dart-define=API_URL=http://127.0.0.1:8925 `
        --dart-define=PHYSICS_PREVIEW=true `
        --dart-define=CHEMISTRY_PREVIEW=true `
        --dart-define=WORLD_HISTORY_PREVIEW=true `
        --dart-define=UZBEKISTAN_HISTORY_PREVIEW=true
    $qaBuildExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if ($qaBuildExit -ne 0) { throw 'Debug build failed.' }
    $qaApk = Get-Item -LiteralPath (Join-Path $qaRoot 'build\app\outputs\flutter-apk\app-debug.apk')
    $qaReceipt = [ordered]@{
        apk = $qaApk.FullName; bytes = $qaApk.Length
        sha256 = (Get-FileHash -LiteralPath $qaApk.FullName -Algorithm SHA256).Hash
        flutter_commit = (git rev-parse HEAD)
        backend_commit = (git -C (Join-Path (Split-Path $qaRoot -Parent) 'ilm-ai-phone-qa') rev-parse HEAD)
        branch = $qaBranch; application_id = 'com.ilmai.app.phoneqa'
        mode = 'debug'; api = 'http://127.0.0.1:8925'; contains_compiled_test_tokens = $false
    }
    $qaReceipt | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $qaApk.DirectoryName 'phone-qa-build.json') -Encoding UTF8
    $qaReceipt | ConvertTo-Json
} finally { Pop-Location }
