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

    $masir = (
        Get-Command `
            -Name "masir" `
            -ErrorAction Stop
    ).Source

    $action = New-ScheduledTaskAction `
        -Execute $pwsh `
        -Argument (
        '-NoProfile -WindowStyle Hidden ' +
        '-Command "' +
        'komorebic start --whkd; ' +
        'Start-Process -FilePath ''' +
        $masir +
        ''' -WindowStyle Hidden' +
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
