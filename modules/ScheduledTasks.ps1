function ConvertTo-WindowsTaskUserIdentity {
    param(
        [AllowNull()]
        [string] $UserId
    )

    if ([string]::IsNullOrWhiteSpace($UserId)) {
        return ""
    }

    try {
        return (
            [Security.Principal.NTAccount]::new($UserId)
        ).Translate(
            [Security.Principal.SecurityIdentifier]
        ).Value
    }
    catch {
        return $UserId.Trim().ToLowerInvariant()
    }
}

function ConvertTo-WindowsScheduledTaskSignature {
    param(
        [Parameter(Mandatory)]
        $Action,

        [Parameter(Mandatory)]
        $Trigger,

        [Parameter(Mandatory)]
        $Principal,

        [Parameter(Mandatory)]
        $Settings
    )

    $actions = @(
        foreach ($item in @($Action)) {
            [ordered]@{
                Execute          = ([string]$item.Execute).Trim()
                Arguments        = ([string]$item.Arguments).Trim()
                WorkingDirectory = ([string]$item.WorkingDirectory).Trim()
            }
        }
    )

    $triggers = @(
        foreach ($item in @($Trigger)) {
            $className = [string] $item.CimClass.CimClassName
            $signature = [ordered]@{
                Class   = $className
                Enabled = [bool] $item.Enabled
            }

            if ($className -eq "MSFT_TaskLogonTrigger") {
                $signature.UserId = ConvertTo-WindowsTaskUserIdentity `
                    -UserId ([string]$item.UserId)

                $signature.Delay = [string] $item.Delay
            }
            elseif ($className -eq "MSFT_TaskWeeklyTrigger") {
                $signature.DaysOfWeek = [int] $item.DaysOfWeek
                $signature.WeeksInterval = [int] $item.WeeksInterval

                $startBoundary = [string] $item.StartBoundary
                $parsed = [DateTimeOffset]::MinValue

                if (
                    [DateTimeOffset]::TryParse(
                        $startBoundary,
                        [ref]$parsed
                    )
                ) {
                    $signature.StartTime = $parsed.ToLocalTime().ToString("HH:mm:ss")
                }
                else {
                    $signature.StartTime = $startBoundary
                }
            }
            else {
                $signature.StartBoundary = [string] $item.StartBoundary
                $signature.EndBoundary = [string] $item.EndBoundary
            }

            [pscustomobject] $signature
        }
    )

    $signature = [ordered]@{
        Actions   = $actions
        Triggers  = $triggers
        Principal = [ordered]@{
            UserId    = ConvertTo-WindowsTaskUserIdentity `
                -UserId ([string]$Principal.UserId)
            LogonType = [string] $Principal.LogonType
            RunLevel  = [string] $Principal.RunLevel
        }
        Settings  = [ordered]@{
            StartWhenAvailable          = [bool] $Settings.StartWhenAvailable
            DisallowStartIfOnBatteries  = [bool] $Settings.DisallowStartIfOnBatteries
            StopIfGoingOnBatteries      = [bool] $Settings.StopIfGoingOnBatteries
            MultipleInstances           = [string] $Settings.MultipleInstances
            ExecutionTimeLimit          = [string] $Settings.ExecutionTimeLimit
            AllowHardTerminate          = [bool] $Settings.AllowHardTerminate
            Enabled                     = [bool] $Settings.Enabled
            Hidden                      = [bool] $Settings.Hidden
            RunOnlyIfIdle               = [bool] $Settings.RunOnlyIfIdle
            WakeToRun                   = [bool] $Settings.WakeToRun
        }
    }

    return $signature |
    ConvertTo-Json `
        -Compress `
        -Depth 8
}

function Test-WindowsScheduledTaskDesiredState {
    param(
        [Parameter(Mandatory)]
        $ExistingTask,

        [Parameter(Mandatory)]
        $Action,

        [Parameter(Mandatory)]
        $Trigger,

        [Parameter(Mandatory)]
        $Principal,

        [Parameter(Mandatory)]
        $Settings
    )

    $currentSignature = ConvertTo-WindowsScheduledTaskSignature `
        -Action $ExistingTask.Actions `
        -Trigger $ExistingTask.Triggers `
        -Principal $ExistingTask.Principal `
        -Settings $ExistingTask.Settings

    $desiredSignature = ConvertTo-WindowsScheduledTaskSignature `
        -Action $Action `
        -Trigger $Trigger `
        -Principal $Principal `
        -Settings $Settings

    return $currentSignature -ceq $desiredSignature
}

function Set-WindowsScheduledTaskDesiredState {
    param(
        [Parameter(Mandatory)]
        [string] $TaskName,

        [Parameter(Mandatory)]
        $Action,

        [Parameter(Mandatory)]
        $Trigger,

        [Parameter(Mandatory)]
        $Principal,

        [Parameter(Mandatory)]
        $Settings
    )

    $existingTask = Get-ScheduledTask `
        -TaskName $TaskName `
        -ErrorAction SilentlyContinue

    if (
        $existingTask -and
        (
            Test-WindowsScheduledTaskDesiredState `
                -ExistingTask $existingTask `
                -Action $Action `
                -Trigger $Trigger `
                -Principal $Principal `
                -Settings $Settings
        )
    ) {
        Write-Host (
            "[CURRENT] Scheduled Task unverändert: {0}" -f
            $TaskName
        ) -ForegroundColor Green

        return $false
    }

    if ($existingTask) {
        Write-Host "[UPDATE] Scheduled Task: $TaskName"

        Set-ScheduledTask `
            -TaskName $TaskName `
            -Action $Action `
            -Trigger $Trigger `
            -Principal $Principal `
            -Settings $Settings |
        Out-Null
    }
    else {
        Write-Host "[CREATE] Scheduled Task: $TaskName"

        Register-ScheduledTask `
            -TaskName $TaskName `
            -Action $Action `
            -Trigger $Trigger `
            -Principal $Principal `
            -Settings $Settings |
        Out-Null
    }

    Write-Host (
        "[OK] Aufgabe '{0}' eingerichtet." -f
        $TaskName
    ) -ForegroundColor Green

    return $true
}

function Get-WindowsDesktopStateFingerprint {
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    $files = [Collections.Generic.List[IO.FileInfo]]::new()

    foreach ($path in @(
            "dotfiles\komorebi\komorebi.json",
            "dotfiles\komorebi\komorebi.bar.json",
            "dotfiles\komorebi\applications.json",
            "dotfiles\komorebi\whkdrc",
            "dotfiles\zebar\settings.json"
        )) {
        $fullPath = Join-Path $RepositoryPath $path

        if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
            $files.Add(
                (Get-Item -LiteralPath $fullPath)
            )
        }
    }

    $zebarProject = Join-Path `
        $RepositoryPath `
        "dotfiles\zebar\windows-setup-bar"

    if (Test-Path -LiteralPath $zebarProject -PathType Container) {
        foreach ($file in @(
                Get-ChildItem `
                    -LiteralPath $zebarProject `
                    -File `
                    -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.Name -ne ".gitignore"
                }

                Get-ChildItem `
                    -LiteralPath (Join-Path $zebarProject "src") `
                    -Recurse `
                    -File `
                    -ErrorAction SilentlyContinue
            )) {
            $files.Add($file)
        }
    }

    $fileFingerprint = if ($files.Count -gt 0) {
        Get-FileSetFingerprint `
            -RootPath $RepositoryPath `
            -Files $files.ToArray()
    }
    else {
        "<no-desktop-files>"
    }

    $runtimeEntries = foreach ($name in @(
            "komorebic",
            "whkd",
            "masir",
            "zebar"
        )) {
        $command = Get-Command `
            -Name $name `
            -CommandType Application `
            -ErrorAction SilentlyContinue

        if (-not $command) {
            "{0}|<missing>" -f $name
            continue
        }

        $item = Get-Item `
            -LiteralPath $command.Source `
            -ErrorAction Stop

        "{0}|{1}|{2}|{3}|{4}" -f
            $name,
            $command.Source,
            $item.Length,
            $item.LastWriteTimeUtc.Ticks,
            $item.VersionInfo.ProductVersion
    }

    return Get-TextFingerprint `
        -Text (
            $fileFingerprint +
            "`n" +
            ($runtimeEntries -join "`n")
        )
}

function Test-WindowsDesktopStateFingerprint {
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath,

        [Parameter(Mandatory)]
        [string] $Fingerprint
    )

    $statePath = Join-Path `
        $RepositoryPath `
        ".generated\state\desktop\desired.sha256"

    if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
        return $false
    }

    $stored = (
        Get-Content `
            -LiteralPath $statePath `
            -Raw
    ).Trim()

    return $stored -eq $Fingerprint
}

function Save-WindowsDesktopStateFingerprint {
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath,

        [Parameter(Mandatory)]
        [string] $Fingerprint
    )

    $stateDirectory = Join-Path `
        $RepositoryPath `
        ".generated\state\desktop"

    if (-not (Test-Path -LiteralPath $stateDirectory -PathType Container)) {
        New-Item `
            -ItemType Directory `
            -Path $stateDirectory `
            -Force |
        Out-Null
    }

    Set-Content `
        -LiteralPath (Join-Path $stateDirectory "desired.sha256") `
        -Value $Fingerprint `
        -Encoding utf8NoBOM `
        -NoNewline
}

function Test-WindowsDesktopCoreEnvironmentRunning {
    foreach ($processName in @(
            "komorebi",
            "whkd",
            "masir",
            "zebar"
        )) {
        if (
            -not (
                Get-Process `
                    -Name $processName `
                    -ErrorAction SilentlyContinue
            )
        ) {
            return $false
        }
    }

    return $true
}

function Test-WindowsVolumeOsdRunning {
    $processes = @(
        Get-CimInstance `
            -ClassName Win32_Process `
            -Filter "Name = 'pwsh.exe'" `
            -ErrorAction SilentlyContinue |
        Where-Object {
            $_.CommandLine -like "*modules\VolumeOsd.ps1*" -or
            $_.CommandLine -like "*\.generated\volume-osd\Start-VolumeOsd.ps1*"
        }
    )

    return $processes.Count -gt 0
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

    Get-CimInstance `
        -ClassName Win32_Process `
        -Filter "Name = 'pwsh.exe'" `
        -ErrorAction SilentlyContinue |
    Where-Object {
        $_.CommandLine -like "*modules\VolumeOsd.ps1*" -or
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
        "modules\VolumeOsd.ps1"

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
        $_.CommandLine -like "*modules\VolumeOsd.ps1*" -or
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
                $_.CommandLine -like "*modules\VolumeOsd.ps1*" -or
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
