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

function ConvertTo-WindowsTaskDurationSignature {
    param(
        [AllowNull()]
        $Value
    )

    if ($null -eq $Value) {
        return [TimeSpan]::Zero.Ticks
    }

    if ($Value -is [TimeSpan]) {
        return ([TimeSpan]$Value).Ticks
    }

    $text = ([string]$Value).Trim()

    if ([string]::IsNullOrWhiteSpace($text)) {
        return [TimeSpan]::Zero.Ticks
    }

    try {
        return [System.Xml.XmlConvert]::ToTimeSpan($text).Ticks
    }
    catch {
        return $text.ToUpperInvariant()
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

                $signature.Delay = ConvertTo-WindowsTaskDurationSignature `
                    -Value $item.Delay
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
            ExecutionTimeLimit          = ConvertTo-WindowsTaskDurationSignature `
                -Value $Settings.ExecutionTimeLimit
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

    if ($currentSignature -ceq $desiredSignature) {
        return $true
    }

    Write-WindowsScheduledTaskSignatureDifference `
        -TaskName ([string]$ExistingTask.TaskName) `
        -CurrentSignature $currentSignature `
        -DesiredSignature $desiredSignature

    return $false
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
            $_.CommandLine -like "*modules\VolumeOsd\index.ps1*" -or
            $_.CommandLine -like "*\.generated\volume-osd\Start-VolumeOsd.ps1*"
        }
    )

    return $processes.Count -gt 0
}