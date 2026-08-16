function Test-SeelenUiRunning {
    return [bool](
        Get-Process `
            -Name "seelen-ui" `
            -ErrorAction SilentlyContinue
    )
}

function Get-SeelenStartApp {
    $startAppMatches = @(
        Get-StartApps |
        Where-Object {
            $_.Name -eq "Seelen UI" -or
            $_.AppID -match "Seelen"
        }
    )

    if ($startAppMatches.Count -eq 0) {
        throw "Seelen UI wurde in Get-StartApps nicht gefunden."
    }

    $exact = @(
        $startAppMatches |
        Where-Object { $_.Name -eq "Seelen UI" }
    )

    if ($exact.Count -eq 1) {
        return $exact[0]
    }

    if ($startAppMatches.Count -eq 1) {
        return $startAppMatches[0]
    }

    throw "Seelen UI konnte nicht eindeutig ermittelt werden."
}

function Remove-LegacyWindowsDesktopEnvironment {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Legacy Desktop Cleanup"
    Write-Host "========================================"

    foreach ($taskName in @(
        "komorebi Desktop",
        "Zebar Desktop",
        "Windows Setup Volume OSD"
    )) {
        $task = Get-ScheduledTask `
            -TaskName $taskName `
            -ErrorAction SilentlyContinue

        if ($task) {
            Stop-ScheduledTask `
                -TaskName $taskName `
                -ErrorAction SilentlyContinue

            Unregister-ScheduledTask `
                -TaskName $taskName `
                -Confirm:$false `
                -ErrorAction Stop

            Write-Host "[REMOVE] Scheduled Task: $taskName"
        }
    }

    foreach ($processName in @(
        "komorebi",
        "whkd",
        "masir",
        "zebar"
    )) {
        Get-Process `
            -Name $processName `
            -ErrorAction SilentlyContinue |
        Stop-Process `
            -Force `
            -ErrorAction Stop
    }

    $volumeOsdProcesses = @(
        Get-CimInstance `
            -ClassName Win32_Process `
            -Filter "Name = 'pwsh.exe'" `
            -ErrorAction SilentlyContinue |
        Where-Object {
            $_.CommandLine -like "*\modules\VolumeOsd\*" -or
            $_.CommandLine -like "*\.generated\volume-osd\*"
        }
    )

    foreach ($process in $volumeOsdProcesses) {
        Stop-Process `
            -Id $process.ProcessId `
            -Force `
            -ErrorAction SilentlyContinue
    }

    $windhawkCli = Get-WindhawkCliPath

    if ($windhawkCli) {
        foreach ($modId in @(
            "windows-11-taskbar-styler",
            "windows-11-start-menu-styler",
            "windows-11-notification-center-styler",
            "taskbar-auto-hide-speed"
        )) {
            & $windhawkCli mod disable $modId

            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Windhawk-Mod konnte nicht deaktiviert werden: $modId"
            }
        }
    }

    Write-Host "[OK] Legacy-Desktop entfernt/deaktiviert." `
        -ForegroundColor Green
}

function Stop-WindowsDesktopEnvironment {
    [CmdletBinding()]
    param()

    Get-Process `
        -Name "seelen-ui" `
        -ErrorAction SilentlyContinue |
    Stop-Process `
        -Force `
        -ErrorAction Stop
}

function Start-WindowsDesktopEnvironment {
    [CmdletBinding()]
    param()

    if (Test-SeelenUiRunning) {
        Write-Host "[SKIP] Seelen UI läuft bereits." `
            -ForegroundColor Green

        return
    }

    $app = Get-SeelenStartApp

    Start-Process `
        -FilePath "explorer.exe" `
        -ArgumentList "shell:AppsFolder\$($app.AppID)"

    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        if (Test-SeelenUiRunning) {
            Write-Host "[OK] Seelen UI läuft." `
                -ForegroundColor Green

            return
        }

        Start-Sleep -Milliseconds 250
    }

    throw "Seelen UI wurde nach dem Start nicht innerhalb von 10 Sekunden erkannt."
}

function Restart-WindowsDesktopEnvironment {
    [CmdletBinding()]
    param()

    Stop-WindowsDesktopEnvironment
    Start-Sleep -Milliseconds 500
    Start-WindowsDesktopEnvironment

    Write-Host "[OK] Seelen Desktop Environment neu gestartet." `
        -ForegroundColor Green
}
