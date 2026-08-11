function Get-EmptyInternalDisk {

    $allowedBusTypes = @(
        "NVMe"
        "SATA"
        "SAS"
        "RAID"
    )

    $candidates = @(
        Get-Disk |
        Where-Object {

            -not $_.IsBoot -and
            -not $_.IsSystem -and
            -not $_IsReadOnly -and
            -not $_.IsOffline -and
            $_.BusType -in $allowedBusTypes
        } |
        Where-Object {

            $partitions = @(
                Get-Partition `
                    -DiskNumber $_.Number `
                    -ErrorAction SilentlyContinue
            )

            $partitions.Count -eq 0
        }
    )

    if ($candidates.Count -eq 0) {
        return $null
    }

    if ($candidates.Count -gt 1) {
        Write-Host ""
        Write-Host "Mehrere leere interne Datenträger gefunden:"

        foreach ($disk in $candidates) {

            Write-Host (
                "  Disk {0}: {1} ({2:N1} GB, {3})" `
                    -f `
                    $disk.Number,
                $disk.FriendlyName,
                ($disk.Size / 1GB),
                $disk.BusType
            )
        }


        throw (
            "Mehrere mögliche Ziel-Datenträger gefunden. " +
            "Aus Sicherheitsgründen wird nichts verändert."
        )
    }

    return $candidates[0]
}

function Initialize-DevelopmentStorage {

    param(
        [Parameter(Mandatory)]
        $Config
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Development Storage"
    Write-Host "========================================"

    #
    # Bereits vorhandenes Layout erkennen
    #

    $devVolume = Get-Volume -DriveLetter $Config.DevDrive.Letter -ErrorAction SilentlyContinue

    $gamesVolume = Get-Volume -DriveLetter $Config.GamesDrive.Letter -ErrorAction SilentlyContinue

    if ($devVolume -and $gamesVolume) {
        Write-Host (
            "[FOUND] Dev Drive {0}: und Games Drive {1}: bereits vorhanden." `
                -f `
                $Config.DevDrive.Letter,
            $Config.GamesDrive.Letter
        )


        Set-DevDriveConfiguration `
            -Config $Config

        return
    }

    #
    # Wenn nur einer der Buchstaben belegt ist, abbrechen.
    #
    if ($devVolume) {

        throw (
            "Laufwerksbuchstabe {0}: ist bereits belegt, " +
            "aber das erwartete Storage-Layout ist unvollständig." `
                -f $Config.DevDrive.Letter
        )
    }


    if ($gamesVolume) {

        throw (
            "Laufwerksbuchstabe {0}: ist bereits belegt, " +
            "aber das erwartete Storage-Layout ist unvollständig." `
                -f $Config.GamesDrive.Letter
        )
    }

    $disk = Get-EmptyInternalDisk

    if (-not $disk) {

        Write-Host "[SKIP] Keine leere interne SSD gefunden."
        return
    }

    #
    # Zusätzliche Sicherheitsprüfung
    #

    if ($disk.IsBoot -or $disk.IsSystem) {
        throw "Sicherheitsabbruch: System- oder Boot-Datenträger."
    }

    $devSizeBytes =
    [uint64]$Config.DevDrive.SizeGB * 1GB

    $minimumGamesBytes =
    [uint64]$Config.MinimumGamesSizeGB * 1GB

    $minimumRequired =
    $devSizeBytes + $minimumGamesBytes

    if ($disk.Size -lt $minimumRequired) {

        throw (
            "Datenträger zu klein. Benötigt werden mindestens {0} GB." `
                -f (
                $Config.DevDrive.SizeGB +
                $Config.MinimumGamesSizeGB
            )
        )
    }

    $gamesSizeGB =
    [math]::Round(
        ($disk.Size - $devSizeBytes) / 1GB,
        1
    )

    #
    # Planung anzeigen
    #

    Write-Host ""
    Write-Host "Gefundener leerer Datenträger:"
    Write-Host ""

    Write-Host (
        "  Disk:          {0}" `
            -f $disk.Number
    )

    Write-Host (
        "  Modell:        {0}" `
            -f $disk.FriendlyName
    )

    Write-Host (
        "  Bus:           {0}" `
            -f $disk.BusType
    )

    Write-Host (
        "  Größe:         {0:N1} GB" `
            -f ($disk.Size / 1GB)
    )

    Write-Host "  Partitionen:   keine"

    Write-Host (
        "  Boot-Disk:     {0}" `
            -f $disk.IsBoot
    )

    Write-Host (
        "  System-Disk:   {0}" `
            -f $disk.IsSystem
    )


    Write-Host ""
    Write-Host "Geplante Änderungen:"
    Write-Host ""

    Write-Host (
        "  {0}:  {1} GB  ReFS Dev Drive  Label: {2}" `
            -f `
            $Config.DevDrive.Letter,
        $Config.DevDrive.SizeGB,
        $Config.DevDrive.Label
    )

    Write-Host (
        "  {0}:  ~{1} GB  NTFS            Label: {2}" `
            -f `
            $Config.GamesDrive.Letter,
        $gamesSizeGB,
        $Config.GamesDrive.Label
    )


    Write-Host ""
    Write-Host (
        "WARNUNG: Der ausgewählte Datenträger wird partitioniert und formatiert."
    ) `
        -ForegroundColor Yellow


    Write-Host ""

    $confirmation = Read-Host (
        "Änderungen wirklich durchführen? [Y/N]"
    )


    if ($confirmation -cne "Y") {

        Write-Host "[SKIP] Storage-Einrichtung abgebrochen."
        return
    }

    #
    # Dev Drive
    #

    Write-Host ""
    Write-Host "[CREATE] Dev Drive"


    $devPartition = New-Partition `
        -DiskNumber $disk.Number `
        -Size $devSizeBytes `
        -DriveLetter $Config.DevDrive.Letter


    Format-Volume `
        -Partition $devPartition `
        -FileSystem ReFS `
        -NewFileSystemLabel $Config.DevDrive.Label `
        -DevDrive `
        -Confirm:$false |
    Out-Null


    #
    # Games
    #

    Write-Host "[CREATE] Games Drive"


    $gamesPartition = New-Partition `
        -DiskNumber $disk.Number `
        -UseMaximumSize `
        -DriveLetter $Config.GamesDrive.Letter


    Format-Volume `
        -Partition $gamesPartition `
        -FileSystem NTFS `
        -NewFileSystemLabel $Config.GamesDrive.Label `
        -Confirm:$false |
    Out-Null


    Write-Host "[OK] Partitionierung abgeschlossen." `
        -ForegroundColor Green


    Set-DevDriveConfiguration `
        -Config $Config
}

function Set-DevDriveConfiguration {

    param(
        [Parameter(Mandatory)]
        $Config
    )


    Write-Host ""
    Write-Host "========================================"
    Write-Host " Dev Drive Konfiguration"
    Write-Host "========================================"


    $devVolume = Get-Volume `
        -DriveLetter $Config.DevDrive.Letter `
        -ErrorAction SilentlyContinue


    if (-not $devVolume) {

        Write-Warning (
            "Dev Drive {0}: wurde nicht gefunden." `
                -f $Config.DevDrive.Letter
        )

        return
    }


    if ($devVolume.FileSystem -ne "ReFS") {

        throw (
            "Laufwerk {0}: ist kein ReFS Volume." `
                -f $Config.DevDrive.Letter
        )
    }


    Initialize-DevDriveDirectories `
        -Paths $Config.Paths


    Set-DevDriveDefenderPerformanceMode


    Set-DevDrivePackageCaches `
        -Paths $Config.Paths
}


function Initialize-DevDriveDirectories {

    param(
        [Parameter(Mandatory)]
        $Paths
    )


    Write-Host ""
    Write-Host "[CONFIG] Dev Drive Verzeichnisse"


    foreach ($path in $Paths.Values) {

        if (-not (Test-Path $path)) {

            New-Item `
                -Path $path `
                -ItemType Directory `
                -Force |
            Out-Null


            Write-Host "[CREATE] $path"
        }
        else {

            Write-Host "[SKIP] $path bereits vorhanden."
        }
    }
}


function Set-DevDriveDefenderPerformanceMode {

    Write-Host ""
    Write-Host "[CONFIG] Microsoft Defender Dev Drive Performance Mode"


    $defenderStatus = Get-MpComputerStatus `
        -ErrorAction SilentlyContinue


    if (-not $defenderStatus) {

        Write-Warning (
            "Microsoft Defender Status konnte nicht ermittelt werden."
        )

        return
    }


    if (-not $defenderStatus.RealTimeProtectionEnabled) {

        Write-Warning (
            "Microsoft Defender Echtzeitschutz ist nicht aktiv."
        )

        return
    }


    Set-MpPreference `
        -PerformanceModeStatus Enabled


    Write-Host "[OK] Defender Performance Mode aktiviert." `
        -ForegroundColor Green
}


function Set-DevDrivePackageCaches {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingPositionalParameters",
        "",
        Justification = "npm und yarn sind externe CLI-Programme und verwenden Positionsargumente als Teil ihrer regulären CLI-Syntax."
    )]
    param(
        [Parameter(Mandatory)]
        $Paths
    )


    Write-Host ""
    Write-Host "[CONFIG] Dev Drive Package Caches"


    #
    # npm
    #

    if (Get-Command npm -ErrorAction SilentlyContinue) {

        npm config set `
            cache `
            $Paths.NpmCache `
            --global


        if ($LASTEXITCODE -ne 0) {
            throw "npm Cache konnte nicht konfiguriert werden."
        }


        Write-Host "[SET] npm cache = $($Paths.NpmCache)"
    }


    #
    # pnpm
    #

    if (Get-Command pnpm -ErrorAction SilentlyContinue) {

        #
        # pnpm Home und globales Bin-Verzeichnis
        #

        $pnpmHome = Join-Path `
            $env:LOCALAPPDATA `
            "pnpm"

        $pnpmBin = Join-Path `
            $pnpmHome `
            "bin"


        if (-not (Test-Path $pnpmBin)) {

            New-Item `
                -Path $pnpmBin `
                -ItemType Directory `
                -Force |
            Out-Null
        }


        Set-UserEnvironmentVariable `
            -Name "PNPM_HOME" `
            -Value $pnpmHome


        Add-UserPathEntry `
            -Path $pnpmBin


        #
        # pnpm Package Store auf Dev Drive
        #

        pnpm config set `
            store-dir `
            $Paths.PnpmStore `
            --global


        if ($LASTEXITCODE -ne 0) {
            throw "pnpm Store konnte nicht konfiguriert werden."
        }


        Write-Host "[SET] pnpm store = $($Paths.PnpmStore)"
    }


    #
    # Yarn Classic
    #

    if (Get-Command yarn -ErrorAction SilentlyContinue) {

        yarn config set `
            cache-folder `
            $Paths.YarnCache


        if ($LASTEXITCODE -ne 0) {
            throw "Yarn Cache konnte nicht konfiguriert werden."
        }


        Write-Host "[SET] Yarn cache = $($Paths.YarnCache)"
    }


    #
    # Bun
    #

    if (Get-Command bun -ErrorAction SilentlyContinue) {

        Set-UserEnvironmentVariable `
            -Name "BUN_INSTALL_CACHE_DIR" `
            -Value $Paths.BunCache
    }


    #
    # Go
    #

    if (Get-Command go -ErrorAction SilentlyContinue) {

        Set-UserEnvironmentVariable `
            -Name "GOCACHE" `
            -Value $Paths.GoBuildCache


        Set-UserEnvironmentVariable `
            -Name "GOMODCACHE" `
            -Value $Paths.GoModCache
    }


    Write-Host "[OK] Package Caches konfiguriert." `
        -ForegroundColor Green
}


function Set-UserEnvironmentVariable {

    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $Value
    )


    [Environment]::SetEnvironmentVariable(
        $Name,
        $Value,
        "User"
    )


    Set-Item `
        -Path "Env:$Name" `
        -Value $Value


    Write-Host (
        "[SET] {0} = {1}" `
            -f `
            $Name,
        $Value
    )
}

function Add-UserPathEntry {

    param(
        [Parameter(Mandatory)]
        [string] $Path
    )


    $userPath = [Environment]::GetEnvironmentVariable(
        "Path",
        "User"
    )


    $entries = @(
        $userPath -split ";" |
        Where-Object {
            $_
        }
    )


    if ($Path -notin $entries) {

        $newPath = (
            @(
                $entries
                $Path
            ) -join ";"
        )


        [Environment]::SetEnvironmentVariable(
            "Path",
            $newPath,
            "User"
        )


        Write-Host "[SET] User PATH += $Path"
    }


    $sessionEntries = @(
        $env:Path -split ";"
    )


    if ($Path -notin $sessionEntries) {
        $env:Path = "$Path;$env:Path"
    }
}

function Test-GamesDriveDirectories {

    param(
        [Parameter(Mandatory)]
        $Config
    )

    $gamesVolume = Get-Volume `
        -DriveLetter $Config.GamesDrive.Letter `
        -ErrorAction SilentlyContinue

    if (-not $gamesVolume) {
        return $false
    }

    if ($gamesVolume.FileSystem -ne "NTFS") {
        return $false
    }

    if (
        -not $Config.GameLibraries -or
        $Config.GameLibraries.Count -eq 0
    ) {
        return $false
    }

    foreach ($path in $Config.GameLibraries.Values) {
        if (
            -not (
                Test-Path `
                    -LiteralPath $path `
                    -PathType Container
            )
        ) {
            return $false
        }
    }

    return $true
}

function Initialize-GamesDriveDirectories {

    param(
        [Parameter(Mandatory)]
        $Config
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Games Drive Verzeichnisse"
    Write-Host "========================================"

    $gamesVolume = Get-Volume `
        -DriveLetter $Config.GamesDrive.Letter `
        -ErrorAction SilentlyContinue

    if (-not $gamesVolume) {
        Write-Warning (
            "Games Drive {0}: wurde nicht gefunden." `
                -f $Config.GamesDrive.Letter
        )

        return
    }

    if ($gamesVolume.FileSystem -ne "NTFS") {
        throw (
            "Laufwerk {0}: ist kein NTFS Volume." `
                -f $Config.GamesDrive.Letter
        )
    }

    foreach ($path in $Config.GameLibraries.Values) {
        if (Test-Path -LiteralPath $path) {
            Write-Host "[SKIP] $path bereits vorhanden."
            continue
        }

        New-Item `
            -Path $path `
            -ItemType Directory `
            -Force |
        Out-Null

        Write-Host "[CREATE] $path"
    }

    Write-Host "[OK] Games-Library-Verzeichnisse vorbereitet." `
        -ForegroundColor Green

    if (-not (Test-GamesDriveDirectories -Config $Config)) {
        throw (
            "Games-Library-Verzeichnisse konnten nicht vollständig " +
            "vorbereitet oder verifiziert werden."
        )
    }

}