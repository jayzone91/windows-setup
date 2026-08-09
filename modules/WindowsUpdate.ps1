function Install-WindowsUpdates {

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Updates"
    Write-Host "========================================"

    $status = [PSCustomObject]@{
        InstalledUpdates = @()
        RebootRequired   = $false
    }


    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {

        Write-Warning (
            "PSWindowsUpdate ist nicht installiert. " +
            "Windows Updates werden übersprungen."
        )

        return $status
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


    $status.InstalledUpdates = $installedUpdates


    if ($installedUpdates.Count -eq 0) {

        Write-Host (
            "[CURRENT] Keine Windows Updates installiert."
        ) -ForegroundColor Green
    }
    else {

        Write-Host ""

        Write-Host (
            "[OK] {0} Windows Update(s) installiert:" `
                -f $installedUpdates.Count
        ) -ForegroundColor Green


        foreach ($update in $installedUpdates) {

            Write-Host (
                "  - {0} {1}" `
                    -f `
                    $update.KB,
                $update.Title
            )
        }
    }


    #
    # Update-spezifischen Neustartstatus prüfen.
    #
    $rebootStatus =
    Get-WURebootStatus `
        -Silent `
        -ErrorAction Stop


    if ($rebootStatus.RebootRequired) {

        $status.RebootRequired = $true

        Write-Host ""

        Write-Host (
            "[REBOOT] Windows Update benötigt einen Neustart."
        ) -ForegroundColor Yellow
    }
    else {

        Write-Host (
            "[OK] Windows Update benötigt keinen Neustart."
        ) -ForegroundColor Green
    }


    return $status
}


function Restart-WindowsAfterUpdate {

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Update Neustart"
    Write-Host "========================================"


    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
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

        Write-Host (
            "[SKIP] Windows Update benötigt keinen Neustart."
        ) -ForegroundColor Green

        return
    }


    Write-Host (
        "[REBOOT] Windows wird über PSWindowsUpdate neu gestartet."
    ) -ForegroundColor Yellow


    Get-WURebootStatus `
        -AutoReboot `
        -ErrorAction Stop
}
