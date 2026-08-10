function ConvertFrom-AsusIni {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $sections = [ordered]@{}
    $sectionName = $null

    foreach ($line in @(Get-Content -LiteralPath $Path -ErrorAction Stop)) {
        $trimmed = $line.Trim()

        if (
            [string]::IsNullOrWhiteSpace($trimmed) -or
            $trimmed.StartsWith(";") -or
            $trimmed.StartsWith("#")
        ) {
            continue
        }

        if ($trimmed -match '^\[(.+)\]$') {
            $sectionName = $Matches[1]
            $sections[$sectionName] = [ordered]@{}
            continue
        }

        if (-not $sectionName -or $trimmed -notmatch '^([^=]+)=(.*)$') {
            continue
        }

        $sections[$sectionName][$Matches[1].Trim()] = $Matches[2].Trim()
    }

    return $sections
}

function Get-AsusRlsFirmwareFindings {
    param(
        [string]$DeviceInfoPath = (
            "C:\ProgramData\ASUS\ROG Live Service\deviceinfo.ini"
        )
    )

    if (-not (Test-Path -LiteralPath $DeviceInfoPath -PathType Leaf)) {
        return @()
    }

    $ini = ConvertFrom-AsusIni -Path $DeviceInfoPath
    $findings = [System.Collections.Generic.List[object]]::new()

    foreach ($sectionName in $ini.Keys) {
        $section = $ini[$sectionName]
        $firmwareFlow = 0
        $firmwareCount = 0

        if ($section.Contains("FirmwareFlow")) {
            [void][int]::TryParse(
                [string]$section["FirmwareFlow"],
                [ref]$firmwareFlow
            )
        }

        if ($section.Contains("Firmware_Count")) {
            [void][int]::TryParse(
                [string]$section["Firmware_Count"],
                [ref]$firmwareCount
            )
        }

        if ($firmwareFlow -gt 0 -or $firmwareCount -gt 0) {
            $findings.Add(
                [PSCustomObject]@{
                    Component     = $sectionName
                    FirmwareFlow  = $firmwareFlow
                    FirmwareCount = $firmwareCount
                }
            )
        }
    }

    return @($findings)
}

function Get-AsusRlsSoftwareUpdates {
    param(
        [string]$LogRoot = (
            "C:\ProgramData\ASUS\ARMOURY CRATE Diagnosis\ROG Live Service"
        )
    )

    if (-not (Test-Path -LiteralPath $LogRoot -PathType Container)) {
        return @()
    }

    $log = Get-ChildItem `
        -LiteralPath $LogRoot `
        -Filter "ROGLiveService_*.log" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $log) {
        return @()
    }

    $lines = @(Get-Content -LiteralPath $log.FullName -ErrorAction Stop)

    # RLS schreibt SetDeviceInfo mehrfach in dasselbe Log. Frühere
    # Snapshots können dabei noch den Zustand vor einer Installation
    # enthalten, z. B. 0/2.0.14. Für die Entscheidung darf deshalb
    # ausschließlich der zuletzt geschriebene Snapshot einer
    # Komponente verwendet werden.
    #
    # Ein Snapshot beginnt mit "Name(displayname)" und läuft bis zum
    # nächsten solchen Eintrag. Innerhalb eines Mainboard-Snapshots
    # können mehrere FrameworkPluginVersion-Zeilen vorkommen; diese
    # müssen gemeinsam erhalten bleiben.
    $latestSnapshots = @{}
    $currentComponent = $null
    $currentVersions = $null

    foreach ($line in $lines) {
        if (
            $line -match (
                '\[SetDeviceInfo\]\s+Name\(displayname\)\s*:\s*' +
                '(.+?)\s+\('
            )
        ) {
            $currentComponent = $Matches[1].Trim()
            $currentVersions = [System.Collections.Generic.List[object]]::new()

            $latestSnapshots[$currentComponent] = $currentVersions
            continue
        }

        if (
            -not $currentComponent -or
            $null -eq $currentVersions -or
            $line -notmatch (
                '\[SetDeviceInfo\]\s+' +
                '([A-Za-z]+(?:Plugin)?Version)\s*' +
                '\(L/S\)\s*:\s*([^/\s]+)/([^\s]+)'
            )
        ) {
            continue
        }

        $currentVersions.Add(
            [PSCustomObject]@{
                Kind             = $Matches[1].Trim()
                InstalledVersion = $Matches[2].Trim()
                AvailableVersion = $Matches[3].Trim()
            }
        )
    }

    $updates = [System.Collections.Generic.List[object]]::new()

    foreach ($component in $latestSnapshots.Keys) {
        foreach ($versionState in @($latestSnapshots[$component])) {
            $localVersion = $versionState.InstalledVersion
            $serverVersion = $versionState.AvailableVersion

            if (
                [string]::IsNullOrWhiteSpace($localVersion) -or
                [string]::IsNullOrWhiteSpace($serverVersion) -or
                $serverVersion -eq "0" -or
                $localVersion -eq $serverVersion
            ) {
                continue
            }

            $needsUpdate = $false

            if ($localVersion -eq "0") {
                $needsUpdate = $true
            }
            else {
                try {
                    $needsUpdate = (
                        [version]$serverVersion -gt
                        [version]$localVersion
                    )
                }
                catch {
                    Write-Verbose (
                        "ASUS-Version nicht vergleichbar: " +
                        "$component / $($versionState.Kind) / " +
                        "$localVersion -> $serverVersion"
                    )

                    continue
                }
            }

            if (-not $needsUpdate) {
                continue
            }

            $updates.Add(
                [PSCustomObject]@{
                    Component        = $component
                    Kind             = $versionState.Kind
                    InstalledVersion = $localVersion
                    AvailableVersion = $serverVersion
                    Confidence       = "ASUS-RLS"
                    SourceLog        = $log.FullName
                }
            )
        }
    }

    return @($updates)
}
function Get-AsusCoreServiceUpdates {
    param(
        [string]$LogPath = (
            "C:\ProgramData\ASUS\ARMOURY CRATE Diagnosis\" +
            "ASUS Update\AsusUpdate.log"
        )
    )

    if (-not (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
        return @()
    }

    $raw = Get-Content -LiteralPath $LogPath -Raw -ErrorAction Stop
    $requestMatches = @(
        [regex]::Matches(
            $raw,
            '<request protocol="3\.0".*?</request>',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
    )
    $responseMatches = @(
        [regex]::Matches(
            $raw,
            '<response protocol="3\.0".*?</response>',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
    )

    if ($requestMatches.Count -eq 0 -or $responseMatches.Count -eq 0) {
        return @()
    }

    try {
        [xml]$request = $requestMatches[-1].Value
        [xml]$response = $responseMatches[-1].Value
    }
    catch {
        Write-Verbose "ASUS-Omaha-XML konnte nicht gelesen werden: $_"
        return @()
    }

    $requestVersions = @{}

    foreach ($app in @($request.request.app)) {
        if ($app.appid -and $app.version) {
            $requestVersions[[string]$app.appid] = [string]$app.version
        }
    }

    $updates = [System.Collections.Generic.List[object]]::new()

    foreach ($app in @($response.response.app)) {
        $appId = [string]$app.appid

        if (
            -not $appId -or
            -not $requestVersions.ContainsKey($appId) -or
            -not $app.updatecheck -or
            [string]$app.updatecheck.status -ne "ok" -or
            -not $app.updatecheck.manifest.version
        ) {
            continue
        }

        $installedVersion = $requestVersions[$appId]
        $availableVersion = [string]$app.updatecheck.manifest.version
        $needsUpdate = $false

        try {
            $needsUpdate = (
                [version]$availableVersion -gt
                [version]$installedVersion
            )
        }
        catch {
            $needsUpdate = (
                $availableVersion -ne
                $installedVersion
            )
        }

        if (-not $needsUpdate) {
            continue
        }

        $name = $appId
        $registryPaths = @(
            "HKLM:\SOFTWARE\WOW6432Node\ASUS\Update\Clients\$appId"
            "HKLM:\SOFTWARE\ASUS\Update\Clients\$appId"
        )

        foreach ($registryPath in $registryPaths) {
            if (-not (Test-Path -LiteralPath $registryPath)) {
                continue
            }

            $client = Get-ItemProperty `
                -LiteralPath $registryPath `
                -ErrorAction SilentlyContinue

            if ($client -and $client.name) {
                $name = [string]$client.name
                break
            }
        }

        $updates.Add(
            [PSCustomObject]@{
                Component        = $name
                Kind             = "CoreService"
                InstalledVersion = $installedVersion
                AvailableVersion = $availableVersion
                Confidence       = "ASUS-Omaha"
                SourceLog        = $LogPath
            }
        )
    }

    return @($updates)
}

function Show-AsusArmouryCrateUpdates {
    Write-Step "ASUS Armoury Crate Update-Status"

    $rlsRoot = "C:\ProgramData\ASUS\ROG Live Service"

    if (-not (Test-Path -LiteralPath $rlsRoot -PathType Container)) {
        Write-Host (
            "[INFO] Keine ROG-Live-Service-Metadaten gefunden. " +
            "ASUS-Komponentenstatus wird übersprungen."
        ) -ForegroundColor DarkGray

        return
    }

    $firmware = @(Get-AsusRlsFirmwareFindings)
    $software = @(
        Get-AsusRlsSoftwareUpdates
        Get-AsusCoreServiceUpdates
    )

    $software = @(
        $software |
        Where-Object {
            $_.Component -notmatch '(?i)\bIntel\b' -and
            $_.Component -notmatch '(?i)\bBIOS\b' -and
            $_.Component -notmatch '(?i)\bFirmware\b'
        } |
        Group-Object Component, Kind, AvailableVersion |
        ForEach-Object {
            $_.Group |
            Select-Object -First 1
        }
    )

    $latestRlsLog = Get-ChildItem `
        -LiteralPath (
            "C:\ProgramData\ASUS\ARMOURY CRATE Diagnosis\ROG Live Service"
        ) `
        -Filter "ROGLiveService_*.log" `
        -File `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($latestRlsLog) {
        $age = (Get-Date) - $latestRlsLog.LastWriteTime

        $metadataStatus = (
            "[INFO] ASUS-Metadatenstand: {0:yyyy-MM-dd HH:mm:ss} " +
            "({1:N1} h alt)"
        ) -f $latestRlsLog.LastWriteTime, $age.TotalHours

        Write-Host $metadataStatus -ForegroundColor DarkGray

        if ($age.TotalHours -gt 26) {
            Write-Warning (
                "Die letzten ROG-Live-Service-Daten sind älter als 26 Stunden. " +
                "Armoury Crate sollte den Status bei nächster Gelegenheit " +
                "aktualisieren."
            )
        }
    }

    if ($software.Count -eq 0) {
        Write-Host (
            "[OK] Keine Nicht-Intel-Softwareupdates in den aktuellen " +
            "ASUS/RLS-Daten erkannt."
        ) -ForegroundColor Green
    }
    else {
        Write-Host ""
        Write-Host (
            "$($software.Count) ASUS-Softwareupdate(s) erkannt:"
        ) -ForegroundColor Yellow

        foreach ($update in $software) {
            Write-Host ""
            Write-Host "  $($update.Component) / $($update.Kind)"
            Write-Host "  Installiert: $($update.InstalledVersion)"
            Write-Host "  Verfügbar:   $($update.AvailableVersion)"
            Write-Host "  Quelle:       $($update.Confidence)"
        }

        Write-Host ""
        Write-Host (
            "[INFO] Diese Updates werden derzeit nur gemeldet. " +
            "Die automatische Armoury-Crate-Installation bleibt " +
            "bis zur separaten Verifikation deaktiviert."
        ) -ForegroundColor Cyan
    }

    if ($firmware.Count -gt 0) {
        Write-Host ""
        Write-Warning (
            "ASUS meldet Firmware-Aktivität. Firmware/BIOS wird " +
            "bewusst nicht automatisch installiert."
        )

        foreach ($item in $firmware) {
            Write-Host (
                "  {0}: FirmwareFlow={1}, Firmware_Count={2}" -f
                $item.Component,
                $item.FirmwareFlow,
                $item.FirmwareCount
            ) -ForegroundColor Yellow
        }
    }
    else {
        Write-Host (
            "[OK] Keine aktive Firmware-Markierung in deviceinfo.ini."
        ) -ForegroundColor Green
    }
}
