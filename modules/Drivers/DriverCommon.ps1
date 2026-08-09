function Write-Step {
    param([string]$Message)

    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity

    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Get-PendingRebootStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $reasons = @()

    $cbsPath =
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\" +
    "Component Based Servicing\RebootPending"

    if (Test-Path $cbsPath) {
        $reasons += "ComponentBasedServicing"
    }


    $windowsUpdatePath =
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\" +
    "WindowsUpdate\Auto Update\RebootRequired"

    if (Test-Path $windowsUpdatePath) {
        $reasons += "WindowsUpdate"
    }


    $sessionManagerPath =
    "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"

    $sessionManager = Get-ItemProperty `
        -Path $sessionManagerPath `
        -Name PendingFileRenameOperations `
        -ErrorAction SilentlyContinue

    $pendingFileRenames = @()

    if (
        $sessionManager -and
        $sessionManager.PendingFileRenameOperations
    ) {
        $pendingFileRenames = @(
            $sessionManager.PendingFileRenameOperations
        )

        $reasons += "PendingFileRenameOperations"
    }


    return [PSCustomObject]@{
        RebootRequired          = $reasons.Count -gt 0
        Reasons                 = $reasons
        PendingFileRenames      = $pendingFileRenames
        ComponentBasedServicing = (
            $reasons -contains "ComponentBasedServicing"
        )
        WindowsUpdate           = (
            $reasons -contains "WindowsUpdate"
        )
        FileRenameOperations    = (
            $reasons -contains "PendingFileRenameOperations"
        )
    }
}


function Test-PendingReboot {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return (
        Get-PendingRebootStatus
    ).RebootRequired
}
