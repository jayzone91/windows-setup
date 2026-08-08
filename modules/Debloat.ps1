function Set-WindowsDebloat {

    param(
        [Parameter(Mandatory)]
        $Config
    )


    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Debloat"
    Write-Host "========================================"


    Remove-DebloatAppxPackages `
        -Packages $Config.AppxPackages `
        -ProtectedPackages $Config.ProtectedPackages


    Set-DebloatRegistryTweaks `
        -Tweaks $Config.RegistryTweaks


    Write-Host ""
    Write-Host "[OK] Windows Debloat abgeschlossen." `
        -ForegroundColor Green
}


function Remove-DebloatAppxPackages {

    param(
        [Parameter(Mandatory)]
        $Packages,

        $ProtectedPackages = @()
    )


    Write-Host ""
    Write-Host "[CONFIG] AppX Pakete"


    #
    # Provisionierte Pakete einmalig über DISM ermitteln.
    #

    Write-Host "[INFO] Provisionierte AppX-Pakete werden ermittelt..."


    $dismOutput = @(
        & dism.exe `
            /Online `
            /Get-ProvisionedAppxPackages
    )


    if ($LASTEXITCODE -ne 0) {
        throw "Provisionierte AppX-Pakete konnten nicht ermittelt werden."
    }


    $provisionedPackages = @()


    $displayName = $null


    foreach ($line in $dismOutput) {

        if ($line -match "^Anzeigename\s*:\s*(.+)$") {

            $displayName = $Matches[1].Trim()

            continue
        }


        if ($line -match "^PackageName\s*:\s*(.+)$") {

            if ($displayName) {

                $provisionedPackages +=
                [PSCustomObject]@{
                    DisplayName = $displayName
                    PackageName = $Matches[1].Trim()
                }
            }


            $displayName = $null
        }
    }


    Write-Host (
        "[INFO] {0} provisionierte Pakete gefunden." `
            -f $provisionedPackages.Count
    )


    foreach ($packageName in $Packages) {

        if ($packageName -in $ProtectedPackages) {

            Write-Warning (
                "Geschütztes Paket wurde übersprungen: {0}" `
                    -f $packageName
            )

            continue
        }


        #
        # Installierte Pakete
        #

        $installedPackages = @(
            Get-AppxPackage `
                -Name $packageName `
                -ErrorAction SilentlyContinue
        )


        foreach ($package in $installedPackages) {

            Write-Host (
                "[REMOVE] {0}" `
                    -f $packageName
            )


            try {

                Remove-AppxPackage `
                    -Package $package.PackageFullName `
                    -ErrorAction Stop
            }
            catch {

                Write-Warning (
                    "Paket konnte nicht entfernt werden: {0}: {1}" `
                        -f `
                        $packageName,
                    $_.Exception.Message
                )
            }
        }


        #
        # Provisioniertes Paket
        #

        $provisionedMatches = @(
            $provisionedPackages |
            Where-Object {
                $_.DisplayName -eq $packageName
            }
        )


        foreach ($package in $provisionedMatches) {

            Write-Host (
                "[DEPROVISION] {0}" `
                    -f $packageName
            )


            & dism.exe `
                /Online `
                /Remove-ProvisionedAppxPackage `
                "/PackageName:$($package.PackageName)" `
                /NoRestart


            if ($LASTEXITCODE -ne 0) {

                Write-Warning (
                    "Provisioniertes Paket konnte nicht entfernt werden: {0}" `
                        -f $packageName
                )
            }
        }


        if (
            $installedPackages.Count -eq 0 -and
            $provisionedMatches.Count -eq 0
        ) {

            Write-Host (
                "[SKIP] {0} nicht vorhanden." `
                    -f $packageName
            )
        }
    }
}


function Set-DebloatRegistryTweaks {

    param(
        [Parameter(Mandatory)]
        $Tweaks
    )


    Write-Host ""
    Write-Host "[CONFIG] Consumer Features"


    foreach ($tweak in $Tweaks) {

        if (-not (Test-Path $tweak.Path)) {

            New-Item `
                -Path $tweak.Path `
                -Force |
            Out-Null
        }


        New-ItemProperty `
            -Path $tweak.Path `
            -Name $tweak.Name `
            -PropertyType $tweak.Type `
            -Value $tweak.Value `
            -Force |
        Out-Null


        Write-Host (
            "[SET] {0}\{1} = {2}" `
                -f `
                $tweak.Path,
            $tweak.Name,
            $tweak.Value
        )
    }
}
