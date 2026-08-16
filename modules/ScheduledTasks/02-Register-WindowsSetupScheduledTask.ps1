function Get-WindowsSetupPwshPath {
    [OutputType([string])]
    param()

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

function Register-WindowsSetupScheduledTask {
    [OutputType([bool])]
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
