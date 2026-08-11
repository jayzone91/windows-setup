function Test-GamingPackageInstalled {

    param(
        [Parameter(Mandatory)]
        [hashtable]$Package
    )

    if (-not $Package.ContainsKey("Source")) {
        throw (
            "Gaming-Paket '{0}' hat keine Source definiert." `
                -f $Package.Name
        )
    }

    switch ([string]$Package.Source) {
        { $_ -in @("winget", "msstore") } {
            return Test-WingetPackage -Id $Package.Id
        }

        "chocolatey" {
            if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                return $false
            }

            return Test-ChocolateyPackage -Id $Package.Id
        }

        "scoop" {
            if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                return $false
            }

            return Test-ScoopPackage -Id $Package.Id
        }

        default {
            throw (
                "Unbekannte Paketquelle '{0}' für Gaming-Paket '{1}'." `
                    -f `
                    $Package.Source,
                $Package.Name
            )
        }
    }
}


function Get-GamingLauncherStateName {

    param(
        [Parameter(Mandatory)]
        [string]$PackageId
    )

    $stateName = $PackageId.ToLowerInvariant()
    $stateName = $stateName -replace '[^a-z0-9]+', '-'
    $stateName = $stateName.Trim('-')

    if ([string]::IsNullOrWhiteSpace($stateName)) {
        throw "Aus der Paket-ID '$PackageId' konnte kein State-Name erzeugt werden."
    }

    return $stateName
}


function Initialize-GamingLauncherInstallPaths {

    param(
        [Parameter(Mandatory)]
        [array]$Packages,

        [Parameter(Mandatory)]
        $StorageConfig,

        [Parameter(Mandatory)]
        [string]$RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Gaming Launcher Installationspfade"
    Write-Host "========================================"

    if (-not (Test-GamesDriveDirectories -Config $StorageConfig)) {
        Write-Warning (
            "Die Gaming-Launcher-Initialisierung wird übersprungen, " +
            "weil nicht alle konfigurierten Games-Verzeichnisse " +
            "vorhanden und verifiziert sind."
        )

        return
    }

    Write-Host (
        "[OK] Alle konfigurierten Games-Verzeichnisse sind vorhanden."
    ) -ForegroundColor Green

    $stateDirectory = Join-Path `
        $RepositoryPath `
        ".generated\state\gaming-launchers"

    foreach ($package in $Packages) {
        if (-not $package.ContainsKey("GameLibrary")) {
            Write-Host (
                "[SKIP] {0} hat keine GameLibrary-Zuordnung." `
                    -f $package.Name
            )

            continue
        }

        $libraryKey = [string]$package.GameLibrary

        if (-not $StorageConfig.GameLibraries.ContainsKey($libraryKey)) {
            throw (
                "Gaming-Paket '{0}' verweist auf unbekannte GameLibrary '{1}'." `
                    -f `
                    $package.Name,
                $libraryKey
            )
        }

        if (-not (Test-GamingPackageInstalled -Package $package)) {
            Write-Host (
                "[SKIP] {0} ist nicht installiert." `
                    -f $package.Name
            )

            continue
        }

        $libraryPath = [string]$StorageConfig.GameLibraries[$libraryKey]
        $stateName = Get-GamingLauncherStateName -PackageId $package.Id

        $statePath = Join-Path `
            $stateDirectory `
            ("{0}.install-path.initialized" -f $stateName)

        if (Test-Path -LiteralPath $statePath -PathType Leaf) {
            Write-Host (
                "[OK] Installationspfad für {0} wurde bereits initialisiert." `
                    -f $package.Name
            ) -ForegroundColor Green

            continue
        }

        Write-Host ""
        Write-Host (
            "[ACTION] Bitte {0} einmalig öffnen und den " +
            "Standard-Installationspfad festlegen." `
                -f $package.Name
        ) -ForegroundColor Cyan

        Write-Host (
            "[INFO] Gewünschter Pfad: {0}" `
                -f $libraryPath
        ) -ForegroundColor Yellow

        Write-Host (
            "[INFO] Das Setup fährt für diesen Launcher erst nach " +
            "deiner Bestätigung fort."
        )

        do {
            $confirmation = Read-Host (
                "Ist der Installationspfad für '{0}' auf '{1}' gesetzt? [Y]" `
                    -f `
                    $package.Name,
                $libraryPath
            )

            if ($confirmation -cne "Y") {
                Write-Host (
                    "[WAIT] Bitte den Pfad in {0} festlegen und " +
                    "anschließend mit Y bestätigen." `
                        -f $package.Name
                ) -ForegroundColor Yellow
            }
        }
        until ($confirmation -ceq "Y")

        if (-not (Test-Path -LiteralPath $stateDirectory -PathType Container)) {
            New-Item `
                -ItemType Directory `
                -Path $stateDirectory `
                -Force |
            Out-Null
        }

        New-Item `
            -ItemType File `
            -Path $statePath `
            -Force |
        Out-Null

        Write-Host (
            "[OK] Installationspfad für {0} als initialisiert markiert." `
                -f $package.Name
        ) -ForegroundColor Green
    }
}