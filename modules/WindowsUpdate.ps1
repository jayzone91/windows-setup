function Install-WindowsUpdates {

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Updates"
    Write-Host "========================================"


    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {

        Write-Warning (
            "PSWindowsUpdate ist nicht installiert. " +
            "Windows Updates werden übersprungen."
        )

        return
    }


    Import-Module `
        PSWindowsUpdate `
        -ErrorAction Stop


    Write-Host "[CHECK] Suche nach Windows Updates..."


    $results = @(
        Get-WindowsUpdate `
            -MicrosoftUpdate `
            -UpdateType Software `
            -Install `
            -AcceptAll `
            -IgnoreReboot `
            -ErrorAction Stop
    )


    $installedUpdates = @(
        $results |
        Where-Object {
            $_.Result -eq "Installed"
        }
    )


    if ($installedUpdates.Count -eq 0) {

        Write-Host "[CURRENT] Keine Windows Updates installiert." `
            -ForegroundColor Green
    }
    else {

        Write-Host ""
        Write-Host (
            "[OK] {0} Windows Update(s) installiert:" `
                -f $installedUpdates.Count
        ) `
            -ForegroundColor Green


        foreach ($update in $installedUpdates) {

            Write-Host (
                "  - {0} {1}" `
                    -f `
                    $update.KB,
                $update.Title
            )
        }
    }


    if (Test-PendingReboot) {

        $script:WindowsUpdateRebootRequired = $true


        Write-Host ""
        Write-Host (
            "[INFO] Windows Updates erfordern einen Neustart."
        ) `
            -ForegroundColor Yellow
    }
}
