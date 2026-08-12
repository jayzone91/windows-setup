function Restart-WindowsVolumeOsd {
    $taskName = "Windows Setup Volume OSD"

    if (
        -not (
            Get-ScheduledTask `
                -TaskName $taskName `
                -ErrorAction SilentlyContinue
        )
    ) {
        throw "Scheduled Task nicht gefunden: $taskName"
    }

    Stop-ScheduledTask `
        -TaskName $taskName `
        -ErrorAction SilentlyContinue

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

    Start-ScheduledTask `
        -TaskName $taskName

    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        if (Test-WindowsVolumeOsdRunning) {
            Write-Host "[OK] Volume OSD gezielt neu gestartet." `
                -ForegroundColor Green

            return
        }

        Start-Sleep -Milliseconds 250
    }

    throw "Volume OSD wurde nach dem gezielten Neustart nicht rechtzeitig erkannt."
}

function Register-WindowsSetupScheduledTask {
    param(
        [Parameter(Mandatory)]
        [string] $BootstrapPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Setup Scheduled Task"
    Write-Host "========================================"

    $taskName = "Windows Setup Weekly Maintenance"

    $pwsh = (
        Get-Command `
            -Name "pwsh" `
            -ErrorAction Stop
    ).Source

    $action = New-ScheduledTaskAction `
        -Execute $pwsh `
        -Argument (
            '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f
            $BootstrapPath
        )

    $trigger = New-ScheduledTaskTrigger `
        -Weekly `
        -WeeksInterval 1 `
        -DaysOfWeek Sunday `
        -At 12:00

    $principal = New-ScheduledTaskPrincipal `
        -UserId $env:USERNAME `
        -LogonType Interactive `
        -RunLevel Highest

    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -MultipleInstances IgnoreNew

    return Set-WindowsScheduledTaskDesiredState `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings
}

function Register-KomorebiStartupTask {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " komorebi Desktop Autostart"
    Write-Host "========================================"

    $taskName = "komorebi Desktop"

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

    $principal = New-ScheduledTaskPrincipal `
        -UserId $env:USERNAME `
        -LogonType Interactive `
        -RunLevel Highest

    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -MultipleInstances IgnoreNew

    return Set-WindowsScheduledTaskDesiredState `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings
}

function Register-ZebarStartupTask {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Zebar Autostart"
    Write-Host "========================================"

    $taskName = "Zebar Desktop"

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

    $principal = New-ScheduledTaskPrincipal `
        -UserId $env:USERNAME `
        -LogonType Interactive `
        -RunLevel Limited

    $settings = New-ScheduledTaskSettingsSet `
        -StartWhenAvailable `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -MultipleInstances IgnoreNew

    return Set-WindowsScheduledTaskDesiredState `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings
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
        "modules\VolumeOsd\index.ps1"

    if (-not (Test-Path -LiteralPath $osdPath -PathType Leaf)) {
        throw "Volume-OSD-Skript nicht gefunden: $osdPath"
    }

    $pwsh = (
        Get-Command `
            -Name "pwsh" `
            -ErrorAction Stop
    ).Source

    $wscript = Join-Path `
        $env:WINDIR `
        "System32\wscript.exe"

    if (-not (Test-Path -LiteralPath $wscript -PathType Leaf)) {
        throw "Windows Script Host nicht gefunden: $wscript"
    }

    $generatedRoot = Join-Path `
        $RepositoryPath `
        ".generated\volume-osd"

    $logRoot = Join-Path `
        $RepositoryPath `
        ".generated\logs"

    foreach ($directory in @($generatedRoot, $logRoot)) {
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            New-Item `
                -ItemType Directory `
                -Path $directory `
                -Force |
            Out-Null
        }
    }

    $launcherPs1 = Join-Path `
        $generatedRoot `
        "Start-VolumeOsd.ps1"

    $launcherVbs = Join-Path `
        $generatedRoot `
        "Start-VolumeOsd.vbs"

    $startupLog = Join-Path `
        $logRoot `
        "volume-osd-startup.log"

    $escapedOsdPath = $osdPath.Replace("'", "''")
    $escapedLogPath = $startupLog.Replace("'", "''")

    $launcherPs1Content = @"
#Requires -Version 7.0
`$ErrorActionPreference = "Stop"

try {
    . '$escapedOsdPath'
    Start-VolumeOsd
}
catch {
    `$timestamp = [DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss.fff")
    `$message = (
        "[{0}] {1}`r`n{2}`r`n" -f
        `$timestamp,
        `$_.Exception.Message,
        `$_.ScriptStackTrace
    )

    [System.IO.File]::AppendAllText(
        '$escapedLogPath',
        `$message
    )

    throw
}
"@

    $command = (
        '"' + $pwsh + '" ' +
        '-NoProfile -NonInteractive -STA ' +
        '-ExecutionPolicy Bypass ' +
        '-File "' + $launcherPs1 + '"'
    )

    $escapedVbsCommand = $command.Replace('"', '""')

    $launcherVbsContent = @"
Option Explicit
Dim shell
Dim command

Set shell = CreateObject("WScript.Shell")
command = "$escapedVbsCommand"

WScript.Quit shell.Run(command, 0, True)
"@

    $launcherChanged = $false

    if (
        Set-WindowsSetupGeneratedTextFile `
            -Path $launcherPs1 `
            -Content $launcherPs1Content `
            -Encoding Utf8NoBom
    ) {
        $launcherChanged = $true
    }

    if (
        Set-WindowsSetupGeneratedTextFile `
            -Path $launcherVbs `
            -Content $launcherVbsContent `
            -Encoding Ascii
    ) {
        $launcherChanged = $true
    }

    $action = New-ScheduledTaskAction `
        -Execute $wscript `
        -Argument (
            '//B //NoLogo "{0}"' -f
            $launcherVbs
        )

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

    $taskChanged = Set-WindowsScheduledTaskDesiredState `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings

    return ($launcherChanged -or $taskChanged)
}