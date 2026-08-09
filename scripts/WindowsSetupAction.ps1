#Requires -Version 7.0

param(
    [Parameter(Mandatory)]
    [ValidateSet(
        "WindowsUpdateReboot"
    )]
    [string] $Action
)

$ErrorActionPreference = "Stop"


function Test-IsAdministrator {

    $identity =
    [Security.Principal.WindowsIdentity]::GetCurrent()

    $principal =
    [Security.Principal.WindowsPrincipal]::new(
        $identity
    )

    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}


function Invoke-Elevated {

    param(
        [Parameter(Mandatory)]
        [string] $Action
    )

    $pwsh = (
        Get-Process `
            -Id $PID
    ).Path

    Start-Process `
        -FilePath $pwsh `
        -Verb RunAs `
        -ArgumentList @(
        "-NoProfile"
        "-ExecutionPolicy"
        "Bypass"
        "-File"
        "`"$PSCommandPath`""
        "-Action"
        $Action
    )
}


if (-not (Test-IsAdministrator)) {

    Invoke-Elevated `
        -Action $Action

    exit
}


switch ($Action) {

    "WindowsUpdateReboot" {

        if (-not (
                Get-Module `
                    -ListAvailable `
                    -Name PSWindowsUpdate
            )) {

            throw "PSWindowsUpdate ist nicht installiert."
        }


        Import-Module `
            PSWindowsUpdate `
            -ErrorAction Stop


        $status =
        Get-WURebootStatus `
            -Silent `
            -ErrorAction Stop


        if (-not $status.RebootRequired) {

            Add-Type -AssemblyName PresentationFramework

            [System.Windows.MessageBox]::Show(
                "Windows Update benötigt aktuell keinen Neustart.",
                "Windows Setup",
                "OK",
                "Information"
            ) |
            Out-Null

            exit
        }


        Get-WURebootStatus `
            -AutoReboot `
            -Confirm:$false `
            -ErrorAction Stop
    }
}
