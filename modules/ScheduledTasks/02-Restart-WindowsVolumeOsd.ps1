function Get-WindowsSetupPwshPath {
    $processPath = [Environment]::ProcessPath

    if (
        [string]::IsNullOrWhiteSpace($processPath) -or
        [IO.Path]::GetFileName($processPath) -ine "pwsh.exe" -or
        -not (Test-Path -LiteralPath $processPath -PathType Leaf)
    ) {
        throw (
            "Aktueller PowerShell-7-Host konnte nicht eindeutig aufgelöst " +
            "werden. ProcessPath='{0}'." -f
            $processPath
        )
    }

    return $processPath
}

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

    Stop-WindowsVolumeOsdProcesses

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

    $taskInfo = Get-ScheduledTaskInfo `
        -TaskName $taskName `
        -ErrorAction SilentlyContinue

    $resultText = if ($taskInfo) {
        " LastTaskResult={0}." -f $taskInfo.LastTaskResult
    }
    else {
        ""
    }

    $diagnostics = Get-WindowsVolumeOsdStartupDiagnostics

    throw (
        "Volume OSD wurde nach dem gezielten Neustart nicht rechtzeitig erkannt." +
        $resultText +
        $diagnostics
    )
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

    $pwsh = Get-WindowsSetupPwshPath

    $action = New-ScheduledTaskAction `
        -Execute $pwsh `
        -Argument (
            '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f
            $BootstrapPath
        ) `
        -WorkingDirectory (Split-Path -Parent $BootstrapPath)

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

    $komorebic = (
        Get-Command `
            -Name "komorebic" `
            -CommandType Application `
            -ErrorAction Stop
    ).Source

    $komorebiDirectory = Split-Path `
        -Parent $komorebic

    $action = New-ScheduledTaskAction `
        -Execute $komorebic `
        -Argument "start --whkd --masir" `
        -WorkingDirectory $env:USERPROFILE

    Write-Host (
        "[FOUND] komorebic Autostart: {0}" -f
        $komorebic
    )

    Write-Host (
        "[INFO] komorebi Working Directory: {0}" -f
        $env:USERPROFILE
    )

    if (-not (Test-Path -LiteralPath $komorebiDirectory -PathType Container)) {
        throw "komorebi-Verzeichnis nicht gefunden: $komorebiDirectory"
    }

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
            -CommandType Application `
            -ErrorAction Stop
    ).Source

    $action = New-ScheduledTaskAction `
        -Execute $zebar `
        -WorkingDirectory (Split-Path -Parent $zebar)

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

    $pwsh = Get-WindowsSetupPwshPath

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

    $vbsLog = Join-Path `
        $logRoot `
        "volume-osd-vbs.log"

    $escapedOsdPath = $osdPath.Replace("'", "''")
    $escapedLogPath = $startupLog.Replace("'", "''")

    $launcherPs1Content = @"
#Requires -Version 7.0
`$ErrorActionPreference = "Stop"

function Write-VolumeOsdStartupTrace {
    param(
        [Parameter(Mandatory)]
        [string] `$Stage
    )

    `$timestamp = [DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss.fff")
    `$line = "[{0}] PID={1} {2}`r`n" -f `$timestamp, `$PID, `$Stage

    [System.IO.File]::AppendAllText(
        '$escapedLogPath',
        `$line
    )
}

try {
    Write-VolumeOsdStartupTrace -Stage "launcher-enter"
    Set-Location -LiteralPath '$($RepositoryPath.Replace("'", "''"))'
    Write-VolumeOsdStartupTrace -Stage "module-load-start"
    . '$escapedOsdPath'
    Write-VolumeOsdStartupTrace -Stage "module-load-complete"
    Write-VolumeOsdStartupTrace -Stage "start-volume-osd-enter"
    Start-VolumeOsd
    Write-VolumeOsdStartupTrace -Stage "start-volume-osd-returned"
}
catch {
    `$timestamp = [DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss.fff")
    `$message = (
        "[{0}] PID={1} exception: {2}`r`n{3}`r`n" -f
        `$timestamp,
        `$PID,
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
    $escapedVbsLog = $vbsLog.Replace('"', '""')

    $launcherVbsContent = @"
Option Explicit
Dim shell, command, fileSystem, logFile
Dim exitCode, errorNumber, errorDescription

Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")
command = "$escapedVbsCommand"

Set logFile = fileSystem.OpenTextFile("$escapedVbsLog", 8, True)
logFile.WriteLine Now & " vbs-enter command=" & command
logFile.Close

On Error Resume Next
exitCode = shell.Run(command, 0, True)
errorNumber = Err.Number
errorDescription = Err.Description
On Error GoTo 0

Set logFile = fileSystem.OpenTextFile("$escapedVbsLog", 8, True)

If errorNumber <> 0 Then
    logFile.WriteLine Now & " shell-run-error number=" & _
        CStr(errorNumber) & " description=" & errorDescription
    logFile.Close
    WScript.Quit 1
End If

logFile.WriteLine Now & " shell-run-exit-code=" & CStr(exitCode)
logFile.Close
WScript.Quit exitCode
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

    foreach ($generatedLauncher in @($launcherPs1, $launcherVbs)) {
        if (-not (Test-Path -LiteralPath $generatedLauncher -PathType Leaf)) {
            throw "Generierter Volume-OSD-Launcher fehlt: $generatedLauncher"
        }
    }

    if (
        [IO.File]::ReadAllText($launcherPs1) -cne $launcherPs1Content -or
        [IO.File]::ReadAllText($launcherVbs) -cne $launcherVbsContent
    ) {
        throw "Generierter Volume-OSD-Launcher entspricht nicht dem Desired State."
    }

    $action = New-ScheduledTaskAction `
        -Execute $wscript `
        -Argument (
            '//B //NoLogo "{0}"' -f
            $launcherVbs
        ) `
        -WorkingDirectory $RepositoryPath

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