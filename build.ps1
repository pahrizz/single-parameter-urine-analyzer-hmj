$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Sync-PathFromRegistry {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = @($machine, $user) -join ';'
}

function Get-FlutterExe {
    Sync-PathFromRegistry
    $fromPath = Get-Command flutter -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }
    $candidates = @(
        if ($env:FLUTTER_ROOT) { Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat' }
        'D:\flutter\bin\flutter.bat'
        (Join-Path $env:LOCALAPPDATA 'flutter\bin\flutter.bat')
        (Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat')
        'C:\flutter\bin\flutter.bat'
        'C:\src\flutter\bin\flutter.bat'
    ) | Where-Object { $_ }
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return $c }
    }
    return $null
}

$flutter = Get-FlutterExe
if (-not $flutter) {
    Write-Host 'Flutter tidak ditemukan. Install dari https://docs.flutter.dev/get-started/install/windows' -ForegroundColor Red
    exit 1
}

Write-Host "Menggunakan Flutter: $flutter" -ForegroundColor Cyan

$doctorText = (& $flutter doctor 2>&1 | Out-String)
if ($doctorText -match 'Unable to locate Android SDK') {
    Write-Host ''
    Write-Host 'Android SDK belum terpasang — APK tidak bisa dibuild.' -ForegroundColor Red
    Write-Host '1. Install Android Studio: https://developer.android.com/studio' -ForegroundColor Yellow
    Write-Host '2. Buka Android Studio → SDK Manager → install Android SDK' -ForegroundColor Yellow
    Write-Host '3. Jalankan: flutter doctor --android-licenses' -ForegroundColor Yellow
    Write-Host '4. Ulangi: .\build.ps1' -ForegroundColor Yellow
    Write-Host ''
    exit 1
}

& $flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'android'))) {
    Write-Host 'Folder platform belum ada — menjalankan flutter create . ...' -ForegroundColor Yellow
    & $flutter create .
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host 'Membangun APK release...' -ForegroundColor Cyan
& $flutter build apk --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apkSource = Join-Path $PSScriptRoot 'build\app\outputs\flutter-apk\app-release.apk'
if (-not (Test-Path -LiteralPath $apkSource)) {
    Write-Host "APK tidak ditemukan di: $apkSource" -ForegroundColor Red
    exit 1
}

$distDir = Join-Path $PSScriptRoot 'dist'
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

$version = '1.0.0'
$pubspec = Join-Path $PSScriptRoot 'pubspec.yaml'
if (Test-Path -LiteralPath $pubspec) {
    $match = Select-String -Path $pubspec -Pattern '^version:\s*(\S+)' | Select-Object -First 1
    if ($match -and $match.Matches.Groups.Count -gt 1) {
        $raw = $match.Matches.Groups[1].Value
        $version = ($raw -split '\+')[0]
    }
}

$apkDest = Join-Path $distDir "MedicalFluidAnalyzer-v$version.apk"
Copy-Item -LiteralPath $apkSource -Destination $apkDest -Force

Write-Host ''
Write-Host 'Build selesai.' -ForegroundColor Green
Write-Host "  APK (salinan): $apkDest" -ForegroundColor Green
Write-Host "  APK (asli):    $apkSource" -ForegroundColor DarkGray
Write-Host ''
Write-Host 'Bagikan file APK di folder dist/ (WhatsApp, Drive, GitHub Releases, dll.).' -ForegroundColor Cyan
