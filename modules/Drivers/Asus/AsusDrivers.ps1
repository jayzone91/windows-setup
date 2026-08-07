function Install-AsusDriverUpdates {
    param(
        [string[]]$DriverNames,

        [switch]$DownloadOnly
    )

    Write-Step "ASUS Treiberupdates"

    #
    # Bewusst freigegebene Pakete.
    #
    # RST bleibt zunächst ausgeschlossen.
    #
    # TODO: Später entfernen!

    $allowedDrivers = @(
        "Intel Chipset Driver"
        "Intel I225_I226 LAN Driver"
        "Intel Serial IO Software"
        "Management Engine Interface"
        "Realtek Audio Driver"
    )

    $updates = @(
        Get-AsusDriverUpdates |
        Where-Object {
            $_.NeedsUpdate -eq $true -and
            $_.Name -in $allowedDrivers
        }
    )

    #
    # Optional nur bestimmte Treiber verarbeiten.
    #
    if ($DriverNames) {
        $updates = @(
            $updates |
            Where-Object {
                $_.Name -in $DriverNames
            }
        )
    }

    if ($updates.Count -eq 0) {
        Write-Host "[OK] Keine freigegebenen ASUS-Treiberupdates verfügbar." `
            -ForegroundColor Green

        return
    }

    Write-Host ""
    Write-Host "$($updates.Count) ASUS-Update(s) gefunden:"

    foreach ($update in $updates) {
        Write-Host ""
        Write-Host "  $($update.Name)"
        Write-Host "  Installiert: $($update.InstalledVersion)"
        Write-Host "  Verfügbar:   $($update.AvailableVersion)"
        Write-Host "  Datum:        $($update.ReleaseDate)"
    }

    foreach ($update in $updates) {

        $zipFile = $null
        $packageDirectory = $null

        try {
            $zipFile = Get-AsusDriverPackage `
                -Update $update

            $packageDirectory = Expand-AsusDriverPackage `
                -Update $update `
                -ZipPath $zipFile

            if ($DownloadOnly) {
                Write-Host ""
                Write-Host (
                    "[DOWNLOAD ONLY] $($update.Name): " +
                    $packageDirectory
                ) -ForegroundColor Yellow

                continue
            }

            Install-AsusDriverPackage `
                -Update $update `
                -PackageDirectory $packageDirectory
        }
        finally {

            #
            # Bei DownloadOnly behalten wir die entpackten Dateien
            # absichtlich zur Untersuchung.
            #

            if (-not $DownloadOnly) {

                if (
                    $packageDirectory -and
                    (Test-Path $packageDirectory)
                ) {
                    Remove-Item `
                        -Path $packageDirectory `
                        -Recurse `
                        -Force `
                        -ErrorAction SilentlyContinue
                }

                if (
                    $zipFile -and
                    (Test-Path $zipFile)
                ) {
                    Remove-Item `
                        -Path $zipFile `
                        -Force `
                        -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Write-Host ""
    Write-Host "[OK] ASUS-Treiberupdates verarbeitet." `
        -ForegroundColor Green
}

