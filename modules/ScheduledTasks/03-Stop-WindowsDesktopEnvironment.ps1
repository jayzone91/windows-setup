function Stop-WindowsDesktopEnvironment {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Desktop Environment stoppen"
    Write-Host "========================================"

    $volumeOsdTask = Get-ScheduledTask `
        -TaskName "Windows Setup Volume OSD" `
        -ErrorAction SilentlyContinue

    if ($volumeOsdTask) {
        Stop-ScheduledTask `
            -TaskName "Windows Setup Volume OSD" `
            -ErrorAction SilentlyContinue
    }

    Get-CimInstance `
        -ClassName Win32_Process `
        -Filter "Name = 'pwsh.exe'" `
        -ErrorAction SilentlyContinue |
    Where-Object {
        $_.CommandLine -like "*modules\VolumeOsd\index.ps1*" -or
        $_.CommandLine -like "*\.generated\volume-osd\Start-VolumeOsd.ps1*"
    } |
    ForEach-Object {
        Stop-Process `
            -Id $_.ProcessId `
            -Force `
            -ErrorAction SilentlyContinue
    }

    Write-Host "[OK] Volume OSD beendet." `
        -ForegroundColor Green

    $zebarTask = Get-ScheduledTask `
        -TaskName "Zebar Desktop" `
        -ErrorAction SilentlyContinue

    if ($zebarTask) {
        Stop-ScheduledTask `
            -TaskName "Zebar Desktop" `
            -ErrorAction SilentlyContinue
    }

    $zebarProcesses = @(
        Get-Process `
            -Name "zebar" `
            -ErrorAction SilentlyContinue
    )

    if ($zebarProcesses.Count -gt 0) {
        $zebarProcesses |
        Stop-Process `
            -Force `
            -ErrorAction SilentlyContinue

        $zebarProcesses |
        Wait-Process `
            -Timeout 5 `
            -ErrorAction SilentlyContinue
    }

    Write-Host "[OK] Zebar beendet." -ForegroundColor Green

    $komorebiProcess = Get-Process `
        -Name "komorebi" `
        -ErrorAction SilentlyContinue

    if ($komorebiProcess) {
        $komorebiStopOutput = @(
            & komorebic stop --whkd --masir 2>&1
        )
        $komorebiStopExitCode = $LASTEXITCODE

        if ($komorebiStopExitCode -ne 0) {
            throw (
                "komorebi konnte nicht sauber beendet werden. " +
                "Exit-Code: $komorebiStopExitCode. Ausgabe: " +
                ($komorebiStopOutput -join " | ")
            )
        }

        try {
            $komorebiProcess |
            Wait-Process `
                -Timeout 10 `
                -ErrorAction Stop
        }
        catch {
            throw "komorebi wurde nicht innerhalb von 10 Sekunden beendet."
        }
    }
    else {
        Get-Process `
            -Name "whkd", "masir" `
            -ErrorAction SilentlyContinue |
        Stop-Process `
            -Force `
            -ErrorAction SilentlyContinue
    }

    Write-Host "[OK] komorebi, whkd und masir beendet." `
        -ForegroundColor Green
}


function Start-WindowsDesktopEnvironment {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Desktop Environment starten"
    Write-Host "========================================"

    foreach ($taskName in @("komorebi Desktop", "Zebar Desktop", "Windows Setup Volume OSD")) {
        if (-not (
            Get-ScheduledTask `
                -TaskName $taskName `
                -ErrorAction SilentlyContinue
        )) {
            throw "Scheduled Task nicht gefunden: $taskName"
        }
    }

    Start-ScheduledTask `
        -TaskName "komorebi Desktop"

    $komorebiReady = $false
    $komorebiProcess = $null
    $whkdProcess = $null

    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        $komorebiProcess = Get-Process `
            -Name "komorebi" `
            -ErrorAction SilentlyContinue

        $whkdProcess = Get-Process `
            -Name "whkd" `
            -ErrorAction SilentlyContinue

        if ($komorebiProcess -and $whkdProcess) {
            $komorebiReady = $true
            break
        }

        Start-Sleep -Milliseconds 250
    }

    if (-not $komorebiReady) {
        $missingProcesses = @()

        if (-not $komorebiProcess) {
            $missingProcesses += "komorebi"
        }

        if (-not $whkdProcess) {
            $missingProcesses += "whkd"
        }

        throw (
            "Desktop Environment wurde nicht innerhalb von 15 Sekunden " +
            "vollständig gestartet. Fehlend: " +
            ($missingProcesses -join ", ")
        )
    }

    Write-Host "[OK] komorebi und whkd laufen." `
        -ForegroundColor Green

    Start-ScheduledTask `
        -TaskName "Zebar Desktop"

    $zebarReady = $false

    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        if (Get-Process -Name "zebar" -ErrorAction SilentlyContinue) {
            $zebarReady = $true
            break
        }

        Start-Sleep -Milliseconds 250
    }

    if (-not $zebarReady) {
        throw "Zebar wurde nach dem Start nicht rechtzeitig erkannt."
    }

    Write-Host "[OK] Zebar läuft." `
        -ForegroundColor Green

    Start-ScheduledTask `
        -TaskName "Windows Setup Volume OSD"

    $volumeOsdReady = $false

    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        $volumeOsdProcesses = @(
            Get-CimInstance `
                -ClassName Win32_Process `
                -Filter "Name = 'pwsh.exe'" `
                -ErrorAction SilentlyContinue |
            Where-Object {
                $_.CommandLine -like "*modules\VolumeOsd\index.ps1*" -or
                $_.CommandLine -like "*\.generated\volume-osd\Start-VolumeOsd.ps1*"
            }
        )

        if ($volumeOsdProcesses.Count -gt 0) {
            $volumeOsdReady = $true
            break
        }

        Start-Sleep -Milliseconds 250
    }

    if (-not $volumeOsdReady) {
        throw (
            "Volume OSD wurde nach dem Start " +
            "nicht rechtzeitig erkannt."
        )
    }

    Write-Host "[OK] Volume OSD läuft." `
        -ForegroundColor Green
}


function Restart-WindowsDesktopEnvironment {
    [CmdletBinding()]
    param()

    Stop-WindowsDesktopEnvironment
    Start-Sleep -Milliseconds 500
    Start-WindowsDesktopEnvironment

    Write-Host ""
    Write-Host "[OK] Desktop Environment neu gestartet." `
        -ForegroundColor Green
}
