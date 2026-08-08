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
