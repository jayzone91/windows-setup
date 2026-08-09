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


function Get-LogitechGHubConfigurationPaths {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    $localDirectory = Join-Path `
        $env:LOCALAPPDATA `
        "LGHUB"

    return @{
        RepositoryFile = Join-Path $RepositoryPath "settings.db"
        LocalDirectory = $localDirectory
        LocalFile      = Join-Path $localDirectory "settings.db"
        MarkerFile     = Join-Path $localDirectory ".windows-setup-configured"
    }
}


function Invoke-WithStoppedLogitechGHub {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock] $Action
    )

    $gHubWasRunning = [bool](
        Get-Process `
            -Name "lghub*" `
            -ErrorAction SilentlyContinue
    )

    if ($gHubWasRunning) {
        Stop-LogitechGHub
    }

    try {
        & $Action
    }
    finally {
        if ($gHubWasRunning) {
            Start-LogitechGHub
        }
    }
}


function Initialize-LogitechGHubConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Logitech G HUB"
    Write-Host "========================================"

    $paths = Get-LogitechGHubConfigurationPaths `
        -RepositoryPath $RepositoryPath

    if (-not (Test-Path $paths.LocalFile)) {
        Write-Warning (
            "G HUB settings.db wurde nicht gefunden. " +
            "G HUB wurde möglicherweise noch nicht initialisiert."
        )

        return
    }

    if (Test-Path $paths.MarkerFile) {
        Write-Host (
            "[CURRENT] G HUB wurde bereits durch windows-setup initialisiert."
        ) -ForegroundColor Green

        Write-Host (
            "[SKIP] Keine automatische G-HUB-Synchronisierung. " +
            "G HUB bleibt geöffnet."
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

    Invoke-WithStoppedLogitechGHub {
        if (Test-Path $paths.RepositoryFile) {
            Write-Host (
                "[RESTORE] Gesicherte G HUB Konfiguration " +
                "wird auf diesem System initial angewendet."
            )

            Copy-Item `
                -Path $paths.RepositoryFile `
                -Destination $paths.LocalFile `
                -Force

            Write-Host "[OK] G HUB Konfiguration wiederhergestellt." `
                -ForegroundColor Green
        }
        else {
            Write-Host (
                "[BACKUP] Keine Repository-Konfiguration vorhanden. " +
                "Lokaler Initialstand wird übernommen."
            )

            Copy-Item `
                -Path $paths.LocalFile `
                -Destination $paths.RepositoryFile `
                -Force

            Write-Host "[OK] G HUB Initialkonfiguration gesichert." `
                -ForegroundColor Green
        }

        Set-Content `
            -Path $paths.MarkerFile `
            -Value "Configured by windows-setup" `
            -Encoding UTF8
    }
}


function Backup-LogitechGHubConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Logitech G HUB Backup"
    Write-Host "========================================"

    $paths = Get-LogitechGHubConfigurationPaths `
        -RepositoryPath $RepositoryPath

    if (-not (Test-Path $paths.LocalFile)) {
        throw "G HUB settings.db wurde nicht gefunden: $($paths.LocalFile)"
    }

    if (-not (Test-Path $RepositoryPath)) {
        New-Item `
            -Path $RepositoryPath `
            -ItemType Directory `
            -Force |
        Out-Null
    }

    Invoke-WithStoppedLogitechGHub {
        Copy-Item `
            -Path $paths.LocalFile `
            -Destination $paths.RepositoryFile `
            -Force

        Set-Content `
            -Path $paths.MarkerFile `
            -Value "Configured by windows-setup" `
            -Encoding UTF8
    }

    Write-Host (
        "[OK] G HUB Konfiguration wurde bewusst ins Repository gesichert."
    ) -ForegroundColor Green
}


function Restore-LogitechGHubConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Logitech G HUB Restore"
    Write-Host "========================================"

    $paths = Get-LogitechGHubConfigurationPaths `
        -RepositoryPath $RepositoryPath

    if (-not (Test-Path $paths.RepositoryFile)) {
        throw (
            "Keine gesicherte G HUB Konfiguration gefunden: " +
            $paths.RepositoryFile
        )
    }

    if (-not (Test-Path $paths.LocalDirectory)) {
        New-Item `
            -Path $paths.LocalDirectory `
            -ItemType Directory `
            -Force |
        Out-Null
    }

    Invoke-WithStoppedLogitechGHub {
        Copy-Item `
            -Path $paths.RepositoryFile `
            -Destination $paths.LocalFile `
            -Force

        Set-Content `
            -Path $paths.MarkerFile `
            -Value "Configured by windows-setup" `
            -Encoding UTF8
    }

    Write-Host (
        "[OK] G HUB Konfiguration wurde bewusst aus dem Repository wiederhergestellt."
    ) -ForegroundColor Green
}
