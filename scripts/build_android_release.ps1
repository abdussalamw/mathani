$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$versionMatch = [regex]::Match((Get-Content 'pubspec.yaml' -Raw), '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$')
if (-not $versionMatch.Success) { throw 'Expected version: major.minor.patch+build in pubspec.yaml' }
$releaseName = 'mathani-arm64-v8a-release-v' + $versionMatch.Groups[1].Value + '(' + $versionMatch.Groups[2].Value + ').apk'

$defaultOutputDir = 'build/app/outputs/flutter-apk'
$archiveDir = 'artifacts/apk'
New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null

$releasePath = Join-Path $defaultOutputDir $releaseName
$archivePath = Join-Path $archiveDir $releaseName

if (Test-Path -LiteralPath $archivePath) { throw "APK already exists in archive: $archivePath. Increment the build number." }

$previousOutput = 'build/app/outputs/flutter-apk/app-release.apk'
if (Test-Path -LiteralPath $previousOutput) {
  $previousDigest = (Get-FileHash -LiteralPath $previousOutput -Algorithm SHA256).Hash.ToLowerInvariant()
  $backupPath = Join-Path $archiveDir ("app-release-before-build-$previousDigest.apk")
  if (-not (Test-Path -LiteralPath $backupPath)) { Copy-Item -LiteralPath $previousOutput -Destination $backupPath }
}
flutter build apk --release --target-platform android-arm64 --no-pub
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Copy-Item -LiteralPath $previousOutput -Destination $releasePath -Force
Copy-Item -LiteralPath $previousOutput -Destination $archivePath -Force
Get-FileHash -LiteralPath $releasePath -Algorithm SHA256
