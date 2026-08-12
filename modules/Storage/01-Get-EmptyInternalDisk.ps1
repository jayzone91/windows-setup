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
        $Config,

        [Parameter(Mandatory)]
        [string] $RepositoryPath
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
            -Config $Config `
            -RepositoryPath $RepositoryPath

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

    Write-WindowsSetupInteractive
    Write-WindowsSetupInteractive `
        -Message "Gefundener leerer Datenträger:"
    Write-WindowsSetupInteractive

    Write-WindowsSetupInteractive `
        -Message ("  Disk:          {0}" -f $disk.Number)
    Write-WindowsSetupInteractive `
        -Message ("  Modell:        {0}" -f $disk.FriendlyName)
    Write-WindowsSetupInteractive `
        -Message ("  Bus:           {0}" -f $disk.BusType)
    Write-WindowsSetupInteractive `
        -Message ("  Größe:         {0:N1} GB" -f ($disk.Size / 1GB))
    Write-WindowsSetupInteractive `
        -Message "  Partitionen:   keine"
    Write-WindowsSetupInteractive `
        -Message ("  Boot-Disk:     {0}" -f $disk.IsBoot)
    Write-WindowsSetupInteractive `
        -Message ("  System-Disk:   {0}" -f $disk.IsSystem)

    Write-WindowsSetupInteractive
    Write-WindowsSetupInteractive `
        -Message "Geplante Änderungen:"
    Write-WindowsSetupInteractive

    Write-WindowsSetupInteractive `
        -Message (
            "  {0}:  {1} GB  ReFS Dev Drive  Label: {2}" `
                -f `
                $Config.DevDrive.Letter,
            $Config.DevDrive.SizeGB,
            $Config.DevDrive.Label
        )

    Write-WindowsSetupInteractive `
        -Message (
            "  {0}:  ~{1} GB  NTFS            Label: {2}" `
                -f `
                $Config.GamesDrive.Letter,
            $gamesSizeGB,
            $Config.GamesDrive.Label
        )

    Write-WindowsSetupInteractive
    Write-WindowsSetupInteractive `
        -Message (
            "WARNUNG: Der ausgewählte Datenträger wird partitioniert und formatiert."
        )
    Write-WindowsSetupInteractive

    $confirmation = Read-WindowsSetupPrompt `
        -Prompt "Änderungen wirklich durchführen? [Y/N]"


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
        -Config $Config `
        -RepositoryPath $RepositoryPath
}

function Set-DevDriveConfiguration {

    param(
        [Parameter(Mandatory)]
        $Config,

        [Parameter(Mandatory)]
        [string] $RepositoryPath
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
        -Paths $Config.Paths `
        -RepositoryPath $RepositoryPath
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