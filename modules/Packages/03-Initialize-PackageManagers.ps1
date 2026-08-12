function Initialize-PackageManagers {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Packages
    )

    Reset-WingetPackageQueues

    Install-Chocolatey
    Install-Scoop

    Initialize-ScoopBuckets `
        -Packages $Packages
}


function Install-PackageGroup {
    param(
        [Parameter(Mandatory)]
        [array]$Packages,

        [Parameter(Mandatory)]
        [string]$GroupName
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " $GroupName"
    Write-Host "========================================"

    foreach ($package in $Packages) {
        if (-not $package.ContainsKey("Source")) {
            throw (
                "Paket '{0}' hat keine Source definiert." `
                    -f $package.Name
            )
        }

        $source = [string]$package.Source
        $installLocation = $null
        $version = $null
        $update = $true

        if ($package.ContainsKey("InstallLocation")) {
            $installLocation = [string]$package.InstallLocation
        }

        if ($package.ContainsKey("Version")) {
            $version = [string]$package.Version
        }

        if ($package.ContainsKey("Update")) {
            $update = [bool]$package.Update
        }

        switch ($source) {
            { $_ -in @("winget", "msstore") } {
                Install-WingetPackage `
                    -Id $package.Id `
                    -Name $package.Name `
                    -Source $source `
                    -InstallLocation $installLocation `
                    -Version $version `
                    -Update $update

                break
            }

            "chocolatey" {
                Install-ChocolateyPackage `
                    -Id $package.Id `
                    -Name $package.Name `
                    -Update $update

                break
            }

            "scoop" {
                if (-not $package.ContainsKey("Bucket")) {
                    throw (
                        "Scoop-Paket '{0}' hat keinen Bucket definiert." `
                            -f $package.Name
                    )
                }

                Install-ScoopPackage `
                    -Id $package.Id `
                    -Name $package.Name `
                    -Bucket $package.Bucket `
                    -Update $update

                break
            }

            default {
                throw (
                    "Unbekannte Paketquelle '{0}' für Paket '{1}'." `
                        -f `
                        $source,
                    $package.Name
                )
            }
        }
    }
}


function Clear-PackageManagerCaches {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingPositionalParameters",
        "",
        Justification = "Scoop ist eine native CLI und verwendet positionsbasierte Argumente."
    )]
    param()
Write-Host ""
    Write-Host "========================================"
    Write-Host " Paketmanager Cleanup"
    Write-Host "========================================"

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "[CLEAN] Chocolatey HTTP-Cache"

        & choco cache remove --expired

        if ($LASTEXITCODE -ne 0) {
            Write-Warning (
                "Chocolatey-Cache konnte nicht vollständig bereinigt werden."
            )
        }
    }

    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        $scoopRoot = if ($env:SCOOP) {
            $env:SCOOP
        }
        else {
            Join-Path $env:USERPROFILE "scoop"
        }

        $scoopCache = Join-Path $scoopRoot "cache"

        if (Test-Path $scoopCache) {
            Write-Host "[CLEAN] Scoop Download-Cache"

            & scoop cache rm *

            if ($LASTEXITCODE -ne 0) {
                Write-Warning (
                    "Scoop-Download-Cache konnte nicht bereinigt werden."
                )
            }
        }
        else {
            Write-Host "[SKIP] Scoop Download-Cache ist leer."
        }

        Write-Host "[CLEAN] Alte Scoop-App-Versionen"

        & scoop cleanup *

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Alte Scoop-Versionen konnten nicht bereinigt werden."
        }
    }

    Write-Host (
        "[SKIP] Winget besitzt aktuell keinen unterstützten " +
        "allgemeinen Cache-Cleanup-Befehl."
    )
}
