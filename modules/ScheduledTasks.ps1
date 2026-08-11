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

function Register-VolumeOsdStartupTask {

    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Volume OSD Autostart"
    Write-Host "========================================"

    $taskName = "Windows Setup Volume OSD"
    $osdPath = Join-Path `
        $RepositoryPath `
        "modules\VolumeOsd.ps1"

    if (-not (
        Test-Path `
            -LiteralPath $osdPath `
            -PathType Leaf
    )) {
        throw "Volume-OSD-Skript nicht gefunden: $osdPath"
    }

    $pwsh = (
        Get-Command `
            -Name "pwsh" `
            -ErrorAction Stop
    ).Source

    $escapedOsdPath = $osdPath.Replace(
        "'",
        "''"
    )

    $command =
        ". '$escapedOsdPath'; Start-VolumeOsd"

    $argument =
        '-NoProfile -STA -WindowStyle Hidden ' +
        '-ExecutionPolicy Bypass -Command "' +
        $command +
        '"'

    $action = New-ScheduledTaskAction `
        -Execute $pwsh `
        -Argument $argument

    $trigger = New-ScheduledTaskTrigger `
        -AtLogOn `
        -User $env:USERNAME

    $principal = New-ScheduledTaskPrincipal `
        -UserId $env:USERNAME `
        -LogonType Interactive `
        -RunLevel Limited

    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -MultipleInstances IgnoreNew `
        -ExecutionTimeLimit ([TimeSpan]::Zero)

    $existingTask = Get-ScheduledTask `
        -TaskName $taskName `
        -ErrorAction SilentlyContinue

    if ($existingTask) {
        Write-Host "[UPDATE] Bestehende Volume-OSD-Aufgabe."

        Set-ScheduledTask `
            -TaskName $taskName `
            -Action $action `
            -Trigger $trigger `
            -Principal $principal `
            -Settings $settings |
        Out-Null
    }
    else {
        Write-Host "[CREATE] Volume-OSD-Autostart-Aufgabe."

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
    ) -ForegroundColor Green
}

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
        $_.CommandLine -like "*modules\VolumeOsd.ps1*"
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
                $_.CommandLine -like "*modules\VolumeOsd.ps1*"
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
