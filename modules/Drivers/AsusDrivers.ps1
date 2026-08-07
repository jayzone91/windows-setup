function Get-AsusDriverUpdates {
    param(
        [string]$ManifestPath = "C:\Program Files (x86)\ASUS\file.idx"
    )

    if (-not (Test-Path $ManifestPath)) {
        throw "ASUS Manifest nicht gefunden: $ManifestPath"
    }

    [xml]$manifest = Get-Content `
        -Path $ManifestPath `
        -Encoding Unicode `
        -Raw

    # ------------------------------------------------------------
    # Aktuell vorhandene Geräte
    # ------------------------------------------------------------

    $devices = @(
        Get-PnpDevice -PresentOnly |
        Where-Object {
            $_.InstanceId
        } |
        Select-Object FriendlyName, InstanceId
    )

    # ------------------------------------------------------------
    # Installierte signierte Treiber einmalig einlesen
    # ------------------------------------------------------------

    $installedDrivers = @(
        Get-CimInstance Win32_PnPSignedDriver
    )

    # ------------------------------------------------------------
    # Nur echte Treiber für Windows 11
    # ------------------------------------------------------------

    $items = @(
        $manifest.product.item |
        Where-Object {
            $_.type -and
            $_.type.Trim() -eq "driver" -and
            $_.os -and
            $_.os -match "Win11"
        }
    )

    # ------------------------------------------------------------
    # Manifest gegen tatsächlich vorhandene Hardware matchen
    # ------------------------------------------------------------

    $driverMatches = foreach ($item in $items) {

        $matchedDevice = $null
        $matchedHwid = $null
        $matchedHwidNode = $null

        foreach ($hwidNode in @($item.hwid)) {

            $hwid = $null

            if ($hwidNode.'#text') {
                $hwid = $hwidNode.'#text'
            }
            elseif ($hwidNode.InnerText) {
                $hwid = $hwidNode.InnerText
            }

            if (-not $hwid) {
                continue
            }

            $hwid = $hwid.Trim()

            if ([string]::IsNullOrWhiteSpace($hwid)) {
                continue
            }

            foreach ($device in $devices) {

                #
                # ASUS verwendet teilweise nur den Basis-HWID.
                # Die Windows InstanceId enthält dahinter noch
                # zusätzliche Informationen.
                #
                if ($device.InstanceId -like "$hwid*") {
                    $matchedDevice = $device
                    $matchedHwid = $hwid
                    $matchedHwidNode = $hwidNode
                    break
                }
            }

            if ($matchedDevice) {
                break
            }
        }

        if (-not $matchedDevice) {
            continue
        }

        # --------------------------------------------------------
        # Installierten Treiber des gematchten Geräts finden
        # --------------------------------------------------------

        $installedDriver = $installedDrivers |
        Where-Object {
            $_.DeviceID -eq $matchedDevice.InstanceId
        } |
        Select-Object -First 1

        $installedVersion = $null

        if ($installedDriver -and $installedDriver.DriverVersion) {
            $installedVersion = $installedDriver.DriverVersion.Trim()
        }

        # --------------------------------------------------------
        # ASUS-Version bestimmen
        # --------------------------------------------------------

        $availableVersion = $null

        #
        # Bevorzugt verwenden wir die HWID-spezifische
        # Treiberversion.
        #
        if (
            $matchedHwidNode -and
            $matchedHwidNode.version
        ) {
            $availableVersion = $matchedHwidNode.version.Trim()
        }
        elseif ($item.version) {
            $availableVersion = $item.version.Trim()
        }

        # --------------------------------------------------------
        # Version vergleichen
        # --------------------------------------------------------

        $needsUpdate = $false
        $versionComparable = $false

        if ($installedVersion -and $availableVersion) {

            try {
                $installedVersionObject = [version]$installedVersion
                $availableVersionObject = [version]$availableVersion

                $versionComparable = $true

                $needsUpdate = (
                    $availableVersionObject -gt
                    $installedVersionObject
                )
            }
            catch {
                Write-Warning (
                    "Versionen konnten nicht verglichen werden: " +
                    "$installedVersion <-> $availableVersion " +
                    "($($item.name))"
                )
            }
        }
        elseif (-not $installedVersion -and $availableVersion) {

            #
            # Gerät vorhanden, aber kein installierter
            # signierter Treiber gefunden.
            #
            $needsUpdate = $true
        }

        # --------------------------------------------------------
        # Download-Informationen
        # --------------------------------------------------------

        $zipPath = $null
        $downloadUrl = $null

        if ($item.'zip-path') {
            $zipPath = $item.'zip-path'.Trim()

            if (-not [string]::IsNullOrWhiteSpace($zipPath)) {
                $downloadUrl = "https://dlcdnets.asus.com/$zipPath"
            }
        }

        # --------------------------------------------------------
        # Release Date
        # --------------------------------------------------------

        $releaseDate = $null

        if ($item.'release-date') {
            try {
                $releaseDate = (
                    [DateTimeOffset]::FromUnixTimeSeconds(
                        [long]$item.'release-date'
                    )
                ).LocalDateTime
            }
            catch {
                $releaseDate = $null
            }
        }

        # --------------------------------------------------------
        # Größe
        # --------------------------------------------------------

        $size = $null

        if ($item.size) {
            try {
                $size = [long]$item.size
            }
            catch {
                $size = $null
            }
        }

        # --------------------------------------------------------
        # Installationskommando
        # --------------------------------------------------------

        $execute = $null

        if ($item.execute) {
            $execute = $item.execute.Trim()
        }

        # --------------------------------------------------------
        # Ergebnis
        # --------------------------------------------------------

        [PSCustomObject]@{
            Name              = $item.name

            DeviceName        = $matchedDevice.FriendlyName
            DeviceId          = $matchedDevice.InstanceId
            MatchedHwid       = $matchedHwid

            InstalledVersion  = $installedVersion
            AvailableVersion  = $availableVersion

            NeedsUpdate       = $needsUpdate
            VersionComparable = $versionComparable

            ReleaseDate       = $releaseDate

            Size              = $size
            ZipPath           = $zipPath
            DownloadUrl       = $downloadUrl

            Execute           = $execute

            Index             = if ($item.index) {
                [int]$item.index
            }
            else {
                $null
            }
        }
    }

    # ------------------------------------------------------------
    # Das ASUS Manifest enthält ältere Versionen weiterhin.
    #
    # Pro Paket/Hardwarekombination behalten wir deshalb nur
    # den neuesten Eintrag.
    # ------------------------------------------------------------

    $latest = @(
        $driverMatches |
        Group-Object {
            "$($_.Name)|$($_.DeviceId)"
        } |
        ForEach-Object {

            $_.Group |
            Sort-Object `
            @{ Expression = "ReleaseDate"; Descending = $true },
            @{ Expression = "AvailableVersion"; Descending = $true } |
            Select-Object -First 1
        }
    )

    return $latest
}

function Get-AsusDriverPackage {
    param(
        [Parameter(Mandatory)]
        $Update
    )

    if (-not $Update.DownloadUrl) {
        throw "Keine Download-URL für $($Update.Name) vorhanden."
    }

    $downloadDirectory = Join-Path $env:TEMP "windows-setup\asus\downloads"

    if (-not (Test-Path $downloadDirectory)) {
        New-Item `
            -Path $downloadDirectory `
            -ItemType Directory `
            -Force | Out-Null
    }

    $fileName = [System.IO.Path]::GetFileName(
        ([uri]$Update.DownloadUrl).AbsolutePath
    )

    $destination = Join-Path $downloadDirectory $fileName

    Write-Host ""
    Write-Host "[DOWNLOAD] $($Update.Name)" -ForegroundColor Cyan
    Write-Host "           $($Update.AvailableVersion)"

    Invoke-WebRequest `
        -Uri $Update.DownloadUrl `
        -OutFile $destination `
        -UseBasicParsing

    if (-not (Test-Path $destination)) {
        throw "ASUS-Paket wurde nicht heruntergeladen: $($Update.Name)"
    }

    # Größe aus dem ASUS-Manifest prüfen
    if ($Update.Size) {
        $actualSize = (Get-Item $destination).Length

        if ($actualSize -ne [long]$Update.Size) {
            Remove-Item $destination -Force

            throw (
                "Dateigröße stimmt nicht überein: $($Update.Name). " +
                "Erwartet: $($Update.Size), erhalten: $actualSize"
            )
        }
    }

    Write-Host "[OK] Download erfolgreich." -ForegroundColor Green

    return $destination
}

function Expand-AsusDriverPackage {
    param(
        [Parameter(Mandatory)]
        $Update,

        [Parameter(Mandatory)]
        [string]$ZipPath
    )

    $safeName = $Update.Name -replace '[^\w\.-]', '_'

    $extractRoot = Join-Path `
        $env:TEMP `
        "windows-setup\asus\packages"

    $destination = Join-Path $extractRoot $safeName

    if (Test-Path $destination) {
        Remove-Item `
            -Path $destination `
            -Recurse `
            -Force
    }

    New-Item `
        -Path $destination `
        -ItemType Directory `
        -Force | Out-Null

    Write-Host "[EXTRACT] $($Update.Name)" -ForegroundColor Cyan

    Expand-Archive `
        -Path $ZipPath `
        -DestinationPath $destination `
        -Force

    Write-Host "[OK] Paket entpackt." -ForegroundColor Green

    return $destination
}

function Get-AsusInstallerCommand {
    param(
        [Parameter(Mandatory)]
        $Update,

        [Parameter(Mandatory)]
        [string]$PackageDirectory
    )

    if (-not $Update.Execute) {
        throw "Kein Installationsbefehl für $($Update.Name) vorhanden."
    }

    #
    # ASUS verwendet:
    #
    # .\AsusSetup.exe%%-s
    #
    # bzw.
    #
    # .\Install\AsusSetup.exe%%-s
    #
    # %% trennt Programm und Argumente.
    #

    $parts = $Update.Execute -split '%%', 2

    $relativeExecutable = $parts[0].Trim()

    $arguments = @()

    if ($parts.Count -gt 1 -and $parts[1]) {
        $arguments = @(
            $parts[1].Trim()
        )
    }

    $relativeExecutable = $relativeExecutable `
        -replace '^[.][\\/]', ''

    $executable = Join-Path `
        $PackageDirectory `
        $relativeExecutable

    if (-not (Test-Path $executable)) {

        #
        # Falls ASUS die ZIP-Struktur später ändert,
        # suchen wir AsusSetup.exe rekursiv.
        #

        $fileName = Split-Path `
            $relativeExecutable `
            -Leaf

        $found = Get-ChildItem `
            -Path $PackageDirectory `
            -Recurse `
            -File `
            -Filter $fileName `
            -ErrorAction SilentlyContinue |
        Select-Object -First 1

        if ($found) {
            $executable = $found.FullName
        }
        else {
            throw (
                "Installer nicht gefunden: " +
                "$relativeExecutable ($($Update.Name))"
            )
        }
    }

    [PSCustomObject]@{
        Executable = $executable
        Arguments  = $arguments
    }
}

function Test-AsusInstallerSignature {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $signature = Get-AuthenticodeSignature $Path

    if ($signature.Status -ne "Valid") {
        throw (
            "Ungültige Authenticode-Signatur: $Path " +
            "($($signature.Status))"
        )
    }

    Write-Host (
        "[OK] Signatur gültig: " +
        $signature.SignerCertificate.Subject
    ) -ForegroundColor Green
}

function Install-AsusDriverPackage {
    param(
        [Parameter(Mandatory)]
        $Update,

        [Parameter(Mandatory)]
        [string]$PackageDirectory
    )

    $command = Get-AsusInstallerCommand `
        -Update $Update `
        -PackageDirectory $PackageDirectory

    Write-Host ""
    Write-Host "[INSTALL] $($Update.Name)" -ForegroundColor Cyan
    Write-Host "          Installed: $($Update.InstalledVersion)"
    Write-Host "          Available: $($Update.AvailableVersion)"
    Write-Host "          Installer: $($command.Executable)"
    Write-Host "          Arguments: $($command.Arguments -join ' ')"

    Test-AsusInstallerSignature `
        -Path $command.Executable

    $process = Start-Process `
        -FilePath $command.Executable `
        -ArgumentList $command.Arguments `
        -WorkingDirectory (Split-Path $command.Executable -Parent) `
        -Wait `
        -PassThru

    #
    # ASUS Setup verwendet nicht zwingend MSI-Exitcodes.
    # 0 behandeln wir sicher als Erfolg.
    #
    if ($process.ExitCode -ne 0) {
        throw (
            "ASUS-Installation fehlgeschlagen: " +
            "$($Update.Name), ExitCode $($process.ExitCode)"
        )
    }

    Write-Host "[OK] Installation abgeschlossen." `
        -ForegroundColor Green

    if (Test-PendingReboot) {
        $script:DriverRebootRequired = $true

        Write-Host "[REBOOT] Neustart erforderlich." `
            -ForegroundColor Yellow
    }

    return $true
}

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
