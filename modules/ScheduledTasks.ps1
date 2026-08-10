function Register-WindowsSetupScheduledTask {

    param(
        [Parameter(Mandatory)]
        [string] $BootstrapPath
    )


    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Setup Scheduled Task"
    Write-Host "========================================"


    $taskName =
    "Windows Setup Weekly Maintenance"


    $pwsh = (
        Get-Command pwsh `
            -ErrorAction Stop
    ).Source


    $action = New-ScheduledTaskAction `
        -Execute $pwsh `
        -Argument (
        '-NoProfile -ExecutionPolicy Bypass -File "{0}"' `
            -f $BootstrapPath
    )


    #
    # Sonntag 12:00 Uhr
    #

    $trigger = New-ScheduledTaskTrigger `
        -Weekly `
        -DaysOfWeek Sunday `
        -At 12:00


    #
    # Im Kontext des angemeldeten Benutzers,
    # damit Desktop-Toasts funktionieren.
    #

    $principal = New-ScheduledTaskPrincipal `
        -UserId $env:USERNAME `
        -LogonType Interactive `
        -RunLevel Highest


    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -MultipleInstances IgnoreNew


    $existingTask = Get-ScheduledTask `
        -TaskName $taskName `
        -ErrorAction SilentlyContinue


    if ($existingTask) {

        Write-Host "[UPDATE] Bestehende Aufgabe wird aktualisiert."


        Set-ScheduledTask `
            -TaskName $taskName `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings |
        Out-Null
    }
    else {

        Write-Host "[CREATE] Wöchentliche Wartungsaufgabe."


        Register-ScheduledTask `
            -TaskName $taskName `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings |
        Out-Null
    }


    Write-Host (
        "[OK] Aufgabe '{0}' eingerichtet." `
            -f $taskName
    ) `
        -ForegroundColor Green
}

function Register-KomorebiStartupTask {

    Write-Host ""
    Write-Host "========================================"
    Write-Host " komorebi Desktop Autostart"
    Write-Host "========================================"


    $taskName =
    "komorebi Desktop"


    $pwsh = (
        Get-Command `
            -Name "pwsh" `
            -ErrorAction Stop
    ).Source
    $action = New-ScheduledTaskAction `
        -Execute $pwsh `
        -Argument (
        '-NoProfile -WindowStyle Hidden ' +
        '-Command "' +
        'komorebic start --whkd --masir' +
        '"'
    )


    $trigger = New-ScheduledTaskTrigger `
        -AtLogOn `
        -User $env:USERNAME


    #
    # komorebi ist eine Desktop-Anwendung und benötigt
    # keine erhöhten Rechte.
    #

    $principal = New-ScheduledTaskPrincipal `
        -UserId $env:USERNAME `
        -LogonType Interactive `
        -RunLevel Highest


    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -MultipleInstances IgnoreNew


    $existingTask = Get-ScheduledTask `
        -TaskName $taskName `
        -ErrorAction SilentlyContinue


    if ($existingTask) {

        Write-Host "[UPDATE] Bestehende Desktop-Aufgabe."


        Set-ScheduledTask `
            -TaskName $taskName `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings |
        Out-Null
    }
    else {

        Write-Host "[CREATE] Desktop-Autostart-Aufgabe."


        Register-ScheduledTask `
            -TaskName $taskName `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings |
        Out-Null
    }


    Write-Host (
        "[OK] Aufgabe '{0}' eingerichtet." `
            -f $taskName
    ) `
        -ForegroundColor Green
}

function Register-ZebarStartupTask {

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Zebar Autostart"
    Write-Host "========================================"


    $taskName =
    "Zebar Desktop"


    $zebar = (
        Get-Command `
            -Name "zebar" `
            -ErrorAction Stop
    ).Source


    $action = New-ScheduledTaskAction `
        -Execute $zebar


    $trigger = New-ScheduledTaskTrigger `
        -AtLogOn `
        -User $env:USERNAME


    #
    # Zebar ist eine Desktop-Anwendung und benötigt
    # keine erhöhten Rechte.
    #

    $principal = New-ScheduledTaskPrincipal `
        -UserId $env:USERNAME `
        -LogonType Interactive `
        -RunLevel Limited


    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -MultipleInstances IgnoreNew


    $existingTask = Get-ScheduledTask `
        -TaskName $taskName `
        -ErrorAction SilentlyContinue


    if ($existingTask) {

        Write-Host "[UPDATE] Bestehende Zebar-Aufgabe."


        Set-ScheduledTask `
            -TaskName $taskName `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings |
        Out-Null
    }
    else {

        Write-Host "[CREATE] Zebar Autostart-Aufgabe."


        Register-ScheduledTask `
            -TaskName $taskName `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings |
        Out-Null
    }


    Write-Host (
        "[OK] Aufgabe '{0}' eingerichtet." `
            -f $taskName
    ) `
        -ForegroundColor Green
}

function Stop-WindowsDesktopEnvironment {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Desktop Environment stoppen"
    Write-Host "========================================"

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
        & komorebic stop --whkd --masir

        if ($LASTEXITCODE -ne 0) {
            throw (
                "komorebi konnte nicht sauber beendet werden. " +
                "Exit-Code: $LASTEXITCODE"
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

    foreach ($taskName in @("komorebi Desktop", "Zebar Desktop")) {
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
