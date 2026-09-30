$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Sync-PathFromRegistry {
    # Terminal Cursor/IDE sering tidak mewarisi PATH terbaru; muat ulang dari registry (Machine + User).
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user =    [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = @($machine, $user) -join ';'
}

function Get-FlutterExe {
    Sync-PathFromRegistry

    $fromPath = Get-Command flutter -ErrorAction SilentlyContinue
    if ($fromPath) {
        return $fromPath.Source
    }
    $candidates = @(
        if ($env:FLUTTER_ROOT) { Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat' }
        'D:\flutter\bin\flutter.bat'
        (Join-Path $env:LOCALAPPDATA 'flutter\bin\flutter.bat')
        (Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat')
        'C:\flutter\bin\flutter.bat'
        'C:\src\flutter\bin\flutter.bat'
    ) | Where-Object { $_ }

    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) {
            return $c
        }
    }
    return $null
}

$flutter = Get-FlutterExe
if (-not $flutter) {
    Write-Host 'Flutter tidak ditemukan. Install SDK (https://docs.flutter.dev/get-started/install/windows), lalu tambahkan ke PATH atau set FLUTTER_ROOT.' -ForegroundColor Red
    exit 1
}

Write-Host "Menggunakan Flutter: $flutter" -ForegroundColor Cyan
& $flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'android'))) {
    Write-Host 'Folder platform belum ada — menjalankan flutter create . ...' -ForegroundColor Yellow
    & $flutter create .
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

& $flutter run @args
