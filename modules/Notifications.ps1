function Send-WindowsSetupNotifications {

    param(
        [Parameter(Mandatory)]
        [bool] $RebootRequired,

        [Parameter(Mandatory)]
        $RepositoryStatus
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
    # Neustart
    #

    if ($RebootRequired) {

        New-BurntToastNotification `
            -Text @(
            "Windows Setup"
            "Ein Neustart des Computers ist erforderlich."
        )


        Write-Host "[NOTIFY] Neustart erforderlich."
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


    if (
        -not $RebootRequired -and
        -not $RepositoryStatus.HasChanges -and
        $RepositoryStatus.UnpushedCommits -eq 0
    ) {

        Write-Host "[OK] Keine Desktop-Benachrichtigung erforderlich."
    }
}
