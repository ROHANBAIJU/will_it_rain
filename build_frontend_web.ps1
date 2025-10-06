<#
Build helper for frontend Flutter web
Usage (PowerShell):
  ./build_frontend_web.ps1

This script changes to the FRONTEND directory, ensures Flutter is on PATH,
runs `flutter pub get` and `flutter build web --release`.
#>

try {
    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    if (-not $flutter) {
        Write-Error "Flutter executable not found in PATH. Please install Flutter and ensure 'flutter' is available on PATH."
        exit 1
    }

    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
    Push-Location $scriptDir

    # Ensure we run from the FRONTEND directory
    if (-not (Test-Path -Path "FRONTEND/pubspec.yaml")) {
        Write-Error "FRONTEND/pubspec.yaml not found. Make sure this repository has a FRONTEND folder with a Flutter project."
        exit 2
    }

    Set-Location -Path "FRONTEND"

    Write-Host "Flutter version:" -NoNewline; flutter --version

    Write-Host "Running: flutter pub get"
    flutter pub get

    Write-Host "Building Flutter web (release)"
    flutter build web --release

    Write-Host "Build complete. Output: FRONTEND/build/web"
} finally {
    Pop-Location -ErrorAction SilentlyContinue
}
