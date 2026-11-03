param(
    [ValidateSet('Doctor', 'Init', 'Prepare', 'CheckBackend', 'Run', 'Build', 'CheckMedia')]
    [string]$Action = 'Doctor',
    [string]$Device,
    [string]$File
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    foreach ($candidate in @("$env:ProgramFiles\Git\cmd", "$env:LOCALAPPDATA\Programs\Git\cmd")) {
        if (Test-Path -LiteralPath "$candidate\git.exe") {
            $env:Path = "$candidate;$env:Path"
            break
        }
    }
}
switch ($Action) {
    'Doctor' { node tool/ar-pilot/doctor.mjs }
    'Init' { node tool/ar-pilot/prepare.mjs --init }
    'Prepare' { node tool/ar-pilot/prepare.mjs }
    'CheckBackend' { node tool/ar-pilot/backend.mjs }
    'CheckMedia' {
        $pythonPath = Join-Path $projectRoot '.venv-tours\Scripts\python.exe'
        if (-not (Test-Path -LiteralPath $pythonPath)) { throw 'Falta preparar .venv-tours según docs/implementation/ar-development-pilot.md.' }
        if ($File) { & $pythonPath processing/tours/check_pilot_media.py --file $File }
        else { & $pythonPath processing/tours/check_pilot_media.py --check-dependencies }
    }
    { $_ -in 'Run', 'Build' } {
        if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter no está en PATH.' }
        if ($Action -eq 'Run' -and -not $Device) { throw 'Indica -Device con un ID de flutter devices.' }
        node tool/ar-pilot/prepare.mjs
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        $defines = '--dart-define-from-file=.dart_tool/ar-pilot/defines.json'
        if ($Action -eq 'Run') {
            flutter run --debug --no-pub -t lib/main.dart -d $Device --web-port=7358 $defines
        } else {
            flutter build apk --debug --no-pub -t lib/main.dart $defines
            if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
            New-Item -ItemType Directory -Path build/ar-pilot -Force | Out-Null
            Copy-Item -LiteralPath build/app/outputs/flutter-apk/app-debug.apk -Destination build/ar-pilot/marea-development-debug.apk
            Write-Output 'APK: build/ar-pilot/marea-development-debug.apk'
        }
    }
}
exit $LASTEXITCODE
