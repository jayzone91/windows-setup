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

