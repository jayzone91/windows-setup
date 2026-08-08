function Get-LogitechGHubExecutable {

    $possiblePaths = @(
        "$env:ProgramFiles\LGHUB\lghub.exe"
        "$env:LOCALAPPDATA\LGHUB\lghub.exe"
    )


    foreach ($path in $possiblePaths) {

        if (Test-Path $path) {
            return $path
        }
    }


    return $null
}


function Stop-LogitechGHub {

    Write-Host "[INFO] Logitech G HUB wird beendet."


    Get-Process `
        -Name "lghub*" `
        -ErrorAction SilentlyContinue |
    Stop-Process `
        -Force `
        -ErrorAction SilentlyContinue


    for ($attempt = 1; $attempt -le 20; $attempt++) {

        $processes = Get-Process `
            -Name "lghub*" `
            -ErrorAction SilentlyContinue


        if (-not $processes) {
            break
        }


        Start-Sleep `
            -Milliseconds 250
    }


    if (
        Get-Process `
            -Name "lghub*" `
            -ErrorAction SilentlyContinue
    ) {

        throw "Logitech G HUB konnte nicht vollständig beendet werden."
    }


    Start-Sleep `
        -Milliseconds 750
}


function Start-LogitechGHub {

    $gHubExecutable = Get-LogitechGHubExecutable


    if (-not $gHubExecutable) {

        Write-Warning "Logitech G HUB wurde nicht gefunden."
        return
    }


    Write-Host "[START] Logitech G HUB"


    $stdoutLog = Join-Path `
        $env:TEMP `
        "lghub.stdout.log"

    $stderrLog = Join-Path `
        $env:TEMP `
        "lghub.stderr.log"


    Start-Process `
        -FilePath $gHubExecutable `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog
}


function Get-FileSha256 {

    param(
        [Parameter(Mandatory)]
        [string] $Path
    )


    if (-not (Test-Path $Path)) {
        return $null
    }


    return (
        Get-FileHash `
            -Path $Path `
            -Algorithm SHA256
    ).Hash
}


function Sync-LogitechGHubConfiguration {

    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )


    Write-Host ""
    Write-Host "========================================"
    Write-Host " Logitech G HUB"
    Write-Host "========================================"


    $repositoryFile = Join-Path `
        $RepositoryPath `
        "settings.db"

    $localDirectory = Join-Path `
        $env:LOCALAPPDATA `
        "LGHUB"

    $localFile = Join-Path `
        $localDirectory `
        "settings.db"

    $markerFile = Join-Path `
        $localDirectory `
        ".windows-setup-configured"


    if (-not (Test-Path $localFile)) {

        Write-Warning (
            "G HUB settings.db wurde nicht gefunden. " +
            "G HUB wurde möglicherweise noch nicht initialisiert."
        )

        return
    }


    if (-not (Test-Path $RepositoryPath)) {

        New-Item `
            -Path $RepositoryPath `
            -ItemType Directory `
            -Force |
        Out-Null
    }


    $gHubWasRunning = [bool](
        Get-Process `
            -Name "lghub*" `
            -ErrorAction SilentlyContinue
    )


    if ($gHubWasRunning) {
        Stop-LogitechGHub
    }


    try {

        #
        # Frisches System:
        # einmalig Repo -> lokale G HUB Datenbank
        #

        if (-not (Test-Path $markerFile)) {

            if (Test-Path $repositoryFile) {

                Write-Host (
                    "[RESTORE] Gesicherte G HUB Konfiguration " +
                    "wird angewendet."
                )


                Copy-Item `
                    -Path $repositoryFile `
                    -Destination $localFile `
                    -Force


                Write-Host "[OK] G HUB Konfiguration wiederhergestellt." `
                    -ForegroundColor Green
            }
            else {

                Write-Host (
                    "[BACKUP] Keine Repository-Konfiguration vorhanden. " +
                    "Lokaler Stand wird übernommen."
                )


                Copy-Item `
                    -Path $localFile `
                    -Destination $repositoryFile `
                    -Force


                Write-Host "[OK] G HUB Initialkonfiguration gesichert." `
                    -ForegroundColor Green
            }


            Set-Content `
                -Path $markerFile `
                -Value "Configured by windows-setup" `
                -Encoding UTF8


            return
        }


        #
        # Bereits eingerichtetes System:
        # lokale G HUB DB ist der aktuelle Stand.
        #

        $localHash = Get-FileSha256 `
            -Path $localFile

        $repositoryHash = Get-FileSha256 `
            -Path $repositoryFile


        if ($localHash -eq $repositoryHash) {

            Write-Host "[CURRENT] G HUB Konfiguration unverändert."
            return
        }


        Write-Host "[CHANGE] G HUB Konfiguration wurde geändert."


        Copy-Item `
            -Path $localFile `
            -Destination $repositoryFile `
            -Force


        Write-Host (
            "[BACKUP] Aktuelle G HUB Konfiguration " +
            "ins Repository übernommen."
        ) `
            -ForegroundColor Green


        Write-Host (
            "[INFO] Repository enthält jetzt Änderungen."
        )
    }
    finally {

        if ($gHubWasRunning) {
            Start-LogitechGHub
        }
    }
}
