$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$versionMatch = [regex]::Match((Get-Content 'pubspec.yaml' -Raw), '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$')
if (-not $versionMatch.Success) { throw 'Expected version: major.minor.patch+build in pubspec.yaml' }
$releaseName = 'mathani-arm64-v8a-release-v' + $versionMatch.Groups[1].Value + '(' + $versionMatch.Groups[2].Value + ').apk'
if (Test-Path -LiteralPath $releaseName) { throw "APK already exists: $releaseName. Increment the build number." }
$previousOutput = 'build/app/outputs/flutter-apk/app-release.apk'
if (Test-Path -LiteralPath $previousOutput) {
  New-Item -ItemType Directory -Path 'artifacts/apk' -Force | Out-Null
  $previousDigest = (Get-FileHash -LiteralPath $previousOutput -Algorithm SHA256).Hash.ToLowerInvariant()
  $backupPath = Join-Path 'artifacts/apk' ("app-release-before-build-$previousDigest.apk")
  if (-not (Test-Path -LiteralPath $backupPath)) { Copy-Item -LiteralPath $previousOutput -Destination $backupPath }
}
flutter build apk --release --target-platform android-arm64 --no-pub
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (Test-Path -LiteralPath $releaseName) { throw "Refusing to overwrite $releaseName" }
Copy-Item -LiteralPath $previousOutput -Destination $releaseName
Get-FileHash -LiteralPath $releaseName -Algorithm SHA256
