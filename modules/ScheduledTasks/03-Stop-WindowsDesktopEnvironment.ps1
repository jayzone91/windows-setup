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

    Stop-WindowsVolumeOsdProcesses

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

    $forceStopRequired = $false

    if ($komorebiProcess) {
        $komorebiStopOutput = @(
            & komorebic stop --whkd --masir 2>&1
        )
        $komorebiStopExitCode = $LASTEXITCODE

        if ($komorebiStopExitCode -eq 0) {
            try {
                $komorebiProcess |
                Wait-Process `
                    -Timeout 10 `
                    -ErrorAction Stop
            }
            catch {
                Write-Warning (
                    "komorebi reagierte auf den Stop-Befehl, wurde aber " +
                    "nicht innerhalb von 10 Sekunden beendet. " +
                    "Der Desktop-Stack wird als Recovery erzwungen beendet."
                )

                $forceStopRequired = $true
            }
        }
        else {
            Write-Warning (
                "komorebic stop konnte den laufenden komorebi-Prozess " +
                "nicht über IPC erreichen. Der Desktop-Stack wird als " +
                "Recovery erzwungen beendet. Exit-Code: {0}. Ausgabe: {1}" -f
                $komorebiStopExitCode,
                ($komorebiStopOutput -join " | ")
            )

            $forceStopRequired = $true
        }
    }

    if (
        $forceStopRequired -or
        -not $komorebiProcess
    ) {
        $desktopProcessesToStop = @(
            Get-Process `
                -Name "komorebi", "whkd", "masir" `
                -ErrorAction SilentlyContinue
        )

        if ($desktopProcessesToStop.Count -gt 0) {
            $stopErrors = @()

            foreach ($process in $desktopProcessesToStop) {
                try {
                    Stop-Process `
                        -Id $process.Id `
                        -Force `
                        -ErrorAction Stop
                }
                catch {
                    $stopErrors += (
                        "{0} (PID {1}): {2}" -f
                        $process.ProcessName,
                        $process.Id,
                        $_.Exception.Message
                    )
                }
            }

            if ($stopErrors.Count -gt 0) {
                throw (
                    "Desktop-Stack konnte im Recovery-Pfad nicht beendet " +
                    "werden. Stop-Fehler: " +
                    ($stopErrors -join " | ")
                )
            }

            foreach ($process in $desktopProcessesToStop) {
                try {
                    Wait-Process `
                        -Id $process.Id `
                        -Timeout 10 `
                        -ErrorAction Stop
                }
                catch {
                    if (
                        Get-Process `
                            -Id $process.Id `
                            -ErrorAction SilentlyContinue
                    ) {
                        throw (
                            "{0} (PID {1}) wurde nach Stop-Process -Force " +
                            "nicht innerhalb von 10 Sekunden beendet." -f
                            $process.ProcessName,
                            $process.Id
                        )
                    }
                }
            }
        }
    }

    $remainingDesktopProcesses = @(
        Get-Process `
            -Name "komorebi", "whkd", "masir" `
            -ErrorAction SilentlyContinue
    )

    if ($remainingDesktopProcesses.Count -gt 0) {
        $remainingDetails = (
            $remainingDesktopProcesses |
            ForEach-Object {
                "{0} (PID {1})" -f $_.ProcessName, $_.Id
            }
        ) -join ", "

        throw (
            "Desktop-Stack konnte nicht vollständig beendet werden. " +
            "Verbleibend: " +
            $remainingDetails
        )
    }

    Write-Host "[OK] komorebi, whkd und masir beendet." `
        -ForegroundColor Green
}

function Get-WindowsScheduledTaskFailureDetails {
    param(
        [Parameter(Mandatory)]
        [string] $TaskName
    )

    $task = Get-ScheduledTask `
        -TaskName $TaskName `
        -ErrorAction SilentlyContinue

    $taskInfo = Get-ScheduledTaskInfo `
        -TaskName $TaskName `
        -ErrorAction SilentlyContinue

    $parts = @()

    if ($task) {
        $parts += "State=$($task.State)"
    }

    if ($taskInfo) {
        $parts += "LastTaskResult=$($taskInfo.LastTaskResult)"
        if ($taskInfo.LastRunTime -gt [DateTime]::MinValue) {
            $parts += "LastRunTime=$($taskInfo.LastRunTime.ToString('o'))"
        }
    }

    return ($parts -join ", ")
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

        $details = Get-WindowsScheduledTaskFailureDetails `
            -TaskName "komorebi Desktop"

        throw (
            "Desktop Environment wurde nicht innerhalb von 15 Sekunden " +
            "vollständig gestartet. Fehlend: " +
            ($missingProcesses -join ", ") +
            ". Task-Diagnose: " +
            $details
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
        $details = Get-WindowsScheduledTaskFailureDetails `
            -TaskName "Zebar Desktop"

        throw "Zebar wurde nach dem Start nicht rechtzeitig erkannt. Task-Diagnose: $details"
    }

    Write-Host "[OK] Zebar läuft." `
        -ForegroundColor Green

    Start-ScheduledTask `
        -TaskName "Windows Setup Volume OSD"

    $volumeOsdReady = $false

    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        if (Test-WindowsVolumeOsdRunning) {
            $volumeOsdReady = $true
            break
        }

        Start-Sleep -Milliseconds 250
    }

    if (-not $volumeOsdReady) {
        $details = Get-WindowsScheduledTaskFailureDetails `
            -TaskName "Windows Setup Volume OSD"

        $repositoryPath = Split-Path `
            -Parent (
                Split-Path `
                    -Parent $PSScriptRoot
            )

        $startupLog = Join-Path `
            $repositoryPath `
            ".generated\logs\volume-osd-startup.log"

        $logTail = if (Test-Path -LiteralPath $startupLog -PathType Leaf) {
            $lines = @(
                Get-Content `
                    -LiteralPath $startupLog `
                    -Tail 20 `
                    -ErrorAction SilentlyContinue
            )

            if ($lines.Count -gt 0) {
                " Startup-Log: " + ($lines -join " | ")
            }
            else {
                " Startup-Log ist leer."
            }
        }
        else {
            " Startup-Log wurde nicht erzeugt."
        }

        throw (
            "Volume OSD wurde nach dem Start " +
            "nicht rechtzeitig erkannt. Task-Diagnose: " +
            $details +
            $logTail
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