function Register-FindMyMouseGameExclusionsScheduledTask {
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryPath
    )

    $taskName = "Windows Setup Find My Mouse Game Exclusions"
    $pwsh = Get-WindowsSetupPwshPath
    $scriptPath = Join-Path `
        $RepositoryPath `
        "scripts\Refresh-FindMyMouseGameExclusions.ps1"

    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        throw "Find-My-Mouse-Refresh-Skript fehlt: $scriptPath"
    }

    $action = New-ScheduledTaskAction `
        -Execute $pwsh `
        -Argument (
            '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f
            $scriptPath
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