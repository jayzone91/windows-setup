function Send-WindowsSetupNotifications {

    param(
        [Parameter(Mandatory)]
        [bool] $WindowsUpdateRebootRequired,

        [Parameter(Mandatory)]
        [bool] $DriverRebootRequired,

        [Parameter(Mandatory)]
        [bool] $PendingReboot,

        [Parameter(Mandatory)]
        $RepositoryStatus,

        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )


    Write-Host ""
    Write-Host "========================================"
    Write-Host " Benachrichtigungen"
    Write-Host "========================================"


    if (-not (Get-Module -ListAvailable -Name BurntToast)) {

        Write-Warning (
            "BurntToast ist nicht installiert. " +
            "Desktop-Benachrichtigungen werden übersprungen."
        )

        return
    }


    Import-Module `
        BurntToast `
        -ErrorAction Stop


    #
    # Windows Update Neustart
    #
    if ($WindowsUpdateRebootRequired) {

        Register-WindowsSetupProtocol `
            -RepositoryPath $RepositoryPath


        $restartButton =
        New-BTButton `
            -Content "Jetzt neu starten" `
            -Arguments "windows-setup://windows-update-reboot" `
            -ActivationType Protocol


        $laterButton =
        New-BTButton `
            -Dismiss `
            -Content "Später"


        New-BurntToastNotification `
            -Text @(
            "Windows Update"
            "Installierte Updates benötigen einen Neustart."
        ) `
            -Button @(
            $restartButton
            $laterButton
        )


        Write-Host (
            "[NOTIFY] Windows Update benötigt einen Neustart."
        )
    }

    #
    # Treiber-Neustart
    #
    if (
        $DriverRebootRequired -and
        -not $WindowsUpdateRebootRequired
    ) {

        New-BurntToastNotification `
            -Text @(
            "Windows Setup – Treiber"
            "Ein installierter Treiber benötigt einen Neustart."
        )


        Write-Host (
            "[NOTIFY] Treiber benötigt einen Neustart."
        )
    }


    #
    # Git
    #

    if (
        $RepositoryStatus.HasChanges -or
        $RepositoryStatus.UnpushedCommits -gt 0
    ) {

        $messageParts = @()


        if ($RepositoryStatus.HasChanges) {

            $changedCount =
            $RepositoryStatus.ChangedFiles.Count


            $messageParts += (
                "{0} lokale Datei(en) geändert." `
                    -f $changedCount
            )


            if ($changedCount -gt 0) {

                $preview = @(
                    $RepositoryStatus.ChangedFiles |
                    Select-Object -First 3
                )


                if ($preview.Count -gt 0) {

                    $messageParts += (
                        "Geändert: {0}" `
                            -f ($preview -join ", ")
                    )
                }
            }
        }


        if ($RepositoryStatus.UnpushedCommits -gt 0) {

            $messageParts += (
                "{0} Commit(s) noch nicht gepusht." `
                    -f $RepositoryStatus.UnpushedCommits
            )
        }


        $messageParts +=
        "Änderungen prüfen und ggf. committen/pushen."


        New-BurntToastNotification `
            -Text @(
            "Windows Setup – Repository"
            ($messageParts -join " ")
        )


        Write-Host "[NOTIFY] Repository benötigt Aufmerksamkeit."
    }

    #
    # Sonstiger Pending Reboot
    #
    if (
        $PendingReboot -and
        -not $WindowsUpdateRebootRequired -and
        -not $DriverRebootRequired
    ) {

        New-BurntToastNotification `
            -Text @(
            "Windows Setup"
            (
                "Windows meldet einen ausstehenden Neustart. " +
                "Die Ursache wurde nicht Windows Update oder " +
                "einem installierten Treiber zugeordnet."
            )
        )


        Write-Host (
            "[NOTIFY] Windows meldet einen sonstigen ausstehenden Neustart."
        )
    }

    if (
        -not $WindowsUpdateRebootRequired -and
        -not $DriverRebootRequired -and
        -not $PendingReboot -and
        -not $RepositoryStatus.HasChanges -and
        $RepositoryStatus.UnpushedCommits -eq 0
    ) {

        Write-Host "[OK] Keine Desktop-Benachrichtigung erforderlich."
    }
}

function Register-WindowsSetupProtocol {

    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )


    $actionScript = Join-Path `
        $RepositoryPath `
        "scripts\WindowsSetupAction.ps1"


    if (-not (Test-Path $actionScript)) {
        throw (
            "Windows Setup Action Script nicht gefunden: " +
            $actionScript
        )
    }


    $pwsh = (
        Get-Command `
            pwsh.exe `
            -ErrorAction Stop
    ).Source


    $protocolPath =
    "HKCU:\Software\Classes\windows-setup"


    $commandPath = Join-Path `
        $protocolPath `
        "shell\open\command"


    New-Item `
        -Path $commandPath `
        -Force |
    Out-Null


    Set-Item `
        -Path $protocolPath `
        -Value "URL:Windows Setup Protocol"


    New-ItemProperty `
        -Path $protocolPath `
        -Name "URL Protocol" `
        -PropertyType String `
        -Value "" `
        -Force |
    Out-Null


    $command = (
        "`"$pwsh`" " +
        "-NoProfile " +
        "-ExecutionPolicy Bypass " +
        "-File `"$actionScript`" " +
        "-Action WindowsUpdateReboot"
    )


    Set-Item `
        -Path $commandPath `
        -Value $command


    Write-Host (
        "[OK] Windows Setup URI-Protokoll registriert."
    ) -ForegroundColor Green
}
