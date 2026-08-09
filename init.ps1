#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8


$RepositoryUrl = "https://github.com/jayzone91/windows-setup.git"

$InstallPath = Join-Path `
    $HOME `
    "windows-setup"


Write-Host ""
Write-Host "========================================"
Write-Host " Windows Setup - Initial Bootstrap"
Write-Host "========================================"
Write-Host ""


function Test-Command {

    param(
        [Parameter(Mandatory)]
        [string] $Name
    )


    return [bool](
        Get-Command `
            -Name $Name `
            -ErrorAction SilentlyContinue
    )
}


# ------------------------------------------------------------
# winget
# ------------------------------------------------------------

Write-Host "[CHECK] winget"


if (-not (Test-Command -Name "winget")) {

    Write-Host (
        "[ERROR] winget wurde nicht gefunden."
    ) `
        -ForegroundColor Red


    Write-Host ""
    Write-Host (
        "App Installer bzw. Windows Update muss zunächst eingerichtet werden."
    )


    exit 1
}


$wingetVersion = winget --version


Write-Host (
    "[OK] winget {0}" `
        -f $wingetVersion
) `
    -ForegroundColor Green


# ------------------------------------------------------------
# Git
# ------------------------------------------------------------

Write-Host ""
Write-Host "[CHECK] Git"


if (-not (Test-Command -Name "git")) {

    Write-Host "[INSTALL] Git"


    winget install `
        --id Git.Git `
        --exact `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements


    if ($LASTEXITCODE -ne 0) {

        Write-Host (
            "[ERROR] Git konnte nicht installiert werden."
        ) `
            -ForegroundColor Red


        exit 1
    }


    $gitPaths = @(
        "$env:ProgramFiles\Git\cmd",
        "$env:ProgramFiles\Git\bin"
    )


    foreach ($gitPath in $gitPaths) {

        if (
            (Test-Path $gitPath) -and
            ($env:Path -notlike "*$gitPath*")
        ) {

            $env:Path =
            "$gitPath;$env:Path"
        }
    }
}


if (-not (Test-Command -Name "git")) {

    Write-Host (
        "[ERROR] Git ist nicht verfügbar."
    ) `
        -ForegroundColor Red


    exit 1
}


Write-Host (
    "[OK] {0}" `
        -f (git --version)
) `
    -ForegroundColor Green


# ------------------------------------------------------------
# Repository
# ------------------------------------------------------------

Write-Host ""
Write-Host "[CHECK] Windows Setup Repository"


$gitDirectory = Join-Path `
    $InstallPath `
    ".git"


if (Test-Path $gitDirectory) {

    Write-Host (
        "[FOUND] {0}" `
            -f $InstallPath
    )


    Write-Host "[UPDATE] Repository"


    Push-Location $InstallPath

    try {

        git fetch origin

        if ($LASTEXITCODE -ne 0) {
            throw "git fetch ist fehlgeschlagen."
        }


        git pull `
            --ff-only

        if ($LASTEXITCODE -ne 0) {
            throw "git pull ist fehlgeschlagen."
        }
    }
    finally {

        Pop-Location
    }


    Write-Host "[OK] Repository aktualisiert." `
        -ForegroundColor Green
}
elseif (Test-Path $InstallPath) {

    throw (
        "Das Zielverzeichnis existiert bereits, ist aber kein Git Repository: {0}" `
            -f $InstallPath
    )
}
else {

    Write-Host "[DOWNLOAD] Repository"


    git clone `
        $RepositoryUrl `
        $InstallPath


    if ($LASTEXITCODE -ne 0) {
        throw "Repository konnte nicht heruntergeladen werden."
    }


    Write-Host "[OK] Repository heruntergeladen." `
        -ForegroundColor Green
}


# ------------------------------------------------------------
# Bootstrap
# ------------------------------------------------------------

$bootstrapPath = Join-Path `
    $InstallPath `
    "bootstrap.ps1"


if (-not (Test-Path $bootstrapPath)) {

    throw (
        "bootstrap.ps1 wurde nicht gefunden: {0}" `
            -f $bootstrapPath
    )
}


Write-Host ""
Write-Host "========================================"
Write-Host " Starte Windows Setup"
Write-Host "========================================"
Write-Host ""


$currentPowerShell = (
    Get-Process `
        -Id $PID `
        -ErrorAction Stop
).Path


if (-not $currentPowerShell) {
    throw "Pfad der aktuellen PowerShell konnte nicht ermittelt werden."
}


Write-Host (
    "[INFO] Bootstrap wird mit ExecutionPolicy Bypass " +
    "auf Prozessebene gestartet."
)


$bootstrapArguments = @(
    "-NoProfile"
    "-ExecutionPolicy"
    "Bypass"
    "-File"
    ('"{0}"' -f $bootstrapPath)
) -join " "


$bootstrapProcess = Start-Process `
    -FilePath $currentPowerShell `
    -ArgumentList $bootstrapArguments `
    -WorkingDirectory $InstallPath `
    -Wait `
    -PassThru


if ($bootstrapProcess.ExitCode -ne 0) {

    throw (
        "bootstrap.ps1 wurde mit ExitCode {0} beendet." `
            -f $bootstrapProcess.ExitCode
    )
}


Write-Host "[OK] Windows Setup abgeschlossen." `
    -ForegroundColor Green