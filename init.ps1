#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================"
Write-Host " Windows Setup - Initial Bootstrap"
Write-Host "========================================"
Write-Host ""

function Test-Command {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# ------------------------------------------------------------
# winget
# ------------------------------------------------------------

Write-Host "[CHECK] winget"

if (-not (Test-Command "winget")) {
    Write-Host "[ERROR] winget wurde nicht gefunden." -ForegroundColor Red
    Write-Host ""
    Write-Host "App Installer bzw. Windows Update muss zunächst eingerichtet werden."
    exit 1
}

$wingetVersion = winget --version

Write-Host "[OK] winget $wingetVersion" -ForegroundColor Green


# ------------------------------------------------------------
# Git
# ------------------------------------------------------------

Write-Host ""
Write-Host "[CHECK] Git"

if (Test-Command "git") {
    $gitVersion = git --version

    Write-Host "[OK] $gitVersion" -ForegroundColor Green
}
else {
    Write-Host "[INSTALL] Git"

    winget install `
        --id Git.Git `
        --exact `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Git konnte nicht installiert werden." -ForegroundColor Red
        exit 1
    }

    # winget aktualisiert den PATH der bereits laufenden
    # PowerShell-Sitzung unter Umständen nicht.
    $gitPaths = @(
        "$env:ProgramFiles\Git\cmd",
        "$env:ProgramFiles\Git\bin"
    )

    foreach ($path in $gitPaths) {
        if (Test-Path $path) {
            $env:Path = "$path;$env:Path"
        }
    }

    if (-not (Test-Command "git")) {
        Write-Host "[ERROR] Git wurde installiert, ist aber nicht im PATH verfügbar." `
            -ForegroundColor Red

        Write-Host "Bitte PowerShell neu starten und init.ps1 erneut ausführen."
        exit 1
    }

    $gitVersion = git --version

    Write-Host "[OK] $gitVersion" -ForegroundColor Green
}


# ------------------------------------------------------------
# Fertig
# ------------------------------------------------------------

Write-Host ""
Write-Host "========================================"
Write-Host " Initialisierung abgeschlossen"
Write-Host "========================================"
Write-Host ""

Write-Host "Git:"
git --version

Write-Host ""
