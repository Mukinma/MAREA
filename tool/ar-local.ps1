param(
    [ValidateSet('Reference', 'Test', 'Build', 'Run')]
    [string]$Action = 'Reference',
    [string]$Device
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

# Resolve Git for this process without changing the user's persistent PATH.
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    foreach ($candidate in @(
        "$env:ProgramFiles\Git\cmd",
        "$env:LOCALAPPDATA\Programs\Git\cmd"
    )) {
        if (Test-Path -LiteralPath "$candidate\git.exe") {
            $env:Path = "$candidate;$env:Path"
            break
        }
    }
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git no está en PATH. Agrega la carpeta cmd de Git y vuelve a ejecutar.'
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter no está en PATH. Agrega la carpeta bin del SDK y vuelve a ejecutar.'
}

$target = 'test/manual/business_ar_probe.dart'
$mapDefine = '--dart-define=MAP_TILE_URL=http://127.0.0.1:38765/tiles/{z}/{x}/{y}.png'
switch ($Action) {
    'Reference' { dart run tool/ar_reference.dart }
    'Test' {
        flutter analyze --no-pub
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        flutter test --no-pub test/features/tours test/features/map test/features/profile/profile_tools_test.dart test/core/router/app_router_test.dart
    }
    'Build' {
        flutter build apk --debug --no-pub -t $target $mapDefine
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        New-Item -ItemType Directory -Path build/ar-local -Force | Out-Null
        Copy-Item -LiteralPath build/app/outputs/flutter-apk/app-debug.apk -Destination build/ar-local/marea-ar-local-debug.apk
        Write-Output 'APK local: build/ar-local/marea-ar-local-debug.apk'
    }
    'Run' {
        if (-not $Device) { throw 'Indica -Device con un ID de flutter devices.' }
        flutter run --debug --no-pub -d $Device -t $target $mapDefine
    }
}
exit $LASTEXITCODE
