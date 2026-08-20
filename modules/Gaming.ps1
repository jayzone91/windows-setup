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

        Write-WindowsSetupInteractive
        Write-WindowsSetupInteractive `
            -Message (
                "[ACTION] Bitte {0} einmalig öffnen und den " +
                "Standard-Installationspfad festlegen." `
                    -f $package.Name
            )

        Write-WindowsSetupInteractive `
            -Message ("[INFO] Gewünschter Pfad: {0}" -f $libraryPath)

        Write-WindowsSetupInteractive `
            -Message (
                "[INFO] Das Setup fährt für diesen Launcher erst nach " +
                "deiner Bestätigung fort."
            )

        do {
            $confirmation = Read-WindowsSetupPrompt `
                -Prompt (
                    "Ist der Installationspfad für '{0}' auf '{1}' gesetzt? [Y]" `
                        -f `
                        $package.Name,
                    $libraryPath
                )

            if ($confirmation -cne "Y") {
                Write-WindowsSetupInteractive `
                    -Message (
                        "[WAIT] Bitte den Pfad in {0} festlegen und " +
                        "anschließend mit Y bestätigen." `
                            -f $package.Name
                    )
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
function Get-InstalledGameExecutable {

    param(
        [Parameter(Mandatory)]
        $StorageConfig
    )

    if (
        -not $StorageConfig.ContainsKey("GameLibraries") -or
        $null -eq $StorageConfig.GameLibraries
    ) {
        throw "Storage-Konfiguration enthält keine GameLibraries."
    }

    $runningProcessNames = [Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )

    foreach ($process in @(Get-Process -ErrorAction SilentlyContinue)) {
        [void]$runningProcessNames.Add([string]$process.ProcessName)
    }

    $results = @()

    foreach (
        $entry in @(
            $StorageConfig.GameLibraries.GetEnumerator() |
            Where-Object {
                [string]$_.Key -ne "Root"
            } |
            Sort-Object Key
        )
    ) {
        $launcher = [string]$entry.Key
        $libraryPath = [string]$entry.Value

        if (
            [string]::IsNullOrWhiteSpace($libraryPath) -or
            -not (Test-Path -LiteralPath $libraryPath -PathType Container)
        ) {
            continue
        }

        $scanRoot = $libraryPath

        if ($launcher -eq "Steam") {
            $steamCommonPath = Join-Path $libraryPath "steamapps\common"

            if (Test-Path -LiteralPath $steamCommonPath -PathType Container) {
                $scanRoot = $steamCommonPath
            }
        }

        $scanRootFull = [IO.Path]::GetFullPath($scanRoot)

        foreach (
            $executable in @(
                Get-ChildItem `
                    -LiteralPath $scanRootFull `
                    -Filter "*.exe" `
                    -File `
                    -Recurse `
                    -ErrorAction SilentlyContinue
            )
        ) {
            $relativePath = [IO.Path]::GetRelativePath(
                $scanRootFull,
                $executable.FullName
            )

            $pathParts = @(
                $relativePath -split '[\\/]'
            )

            $game = if ($pathParts.Count -gt 1) {
                $pathParts[0]
            }
            else {
                "(LibraryRoot)"
            }

            $results += [pscustomobject]@{
                Launcher    = $launcher
                Game        = $game
                Executable  = $executable.Name
                ProcessName = $executable.BaseName
                Running     = $runningProcessNames.Contains(
                    $executable.BaseName
                )
                Path        = $executable.FullName
            }
        }
    }

    return @(
        $results |
        Sort-Object `
            @{ Expression = "Running"; Descending = $true },
            Launcher,
            Game,
            Executable,
            Path
    )
}

function Set-WindowsGameMode {

    param(
        [Parameter(Mandatory)]
        $Config
    )

    if (
        -not $Config.ContainsKey("Gaming") -or
        -not $Config.Gaming.ContainsKey("GameMode") -or
        -not $Config.Gaming.GameMode.ContainsKey("Enabled")
    ) {
        throw "Windows-Gaming-Konfiguration für GameMode.Enabled fehlt."
    }

    $path = "HKCU:\Software\Microsoft\GameBar"
    $desired = if ([bool]$Config.Gaming.GameMode.Enabled) { 1 } else { 0 }

    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -Path $path -Force | Out-Null
    }

    $gameBar = Get-ItemProperty `
        -LiteralPath $path `
        -ErrorAction Stop

    $current = $gameBar.AutoGameModeEnabled

    if ($current -eq $desired) {
        Write-Host "[OK] Windows Game Mode entspricht dem Desired State." `
            -ForegroundColor Green
        return $false
    }

    New-ItemProperty `
        -LiteralPath $path `
        -Name "AutoGameModeEnabled" `
        -PropertyType DWord `
        -Value $desired `
        -Force |
    Out-Null

    Write-Host "[OK] Windows Game Mode wurde konfiguriert." `
        -ForegroundColor Green

    return $true
}
