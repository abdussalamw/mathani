param([Parameter(Mandatory = $true)][string]$DeviceId)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
New-Item -ItemType Directory -Path 'artifacts/performance' -Force | Out-Null
$profileLog = Join-Path 'artifacts/performance' ('android-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
flutter run --profile -d $DeviceId --dart-define=MATHANI_PERFORMANCE=true 2>&1 | Tee-Object -FilePath $profileLog
exit $LASTEXITCODE
