function Install-IntelDriverSupport {
    Write-Step "Intel Driver & Support Assistant"

    Install-WingetPackage `
        -Id "Intel.IntelDriverAndSupportAssistant" `
        -Name "Intel Driver & Support Assistant"
}

function Get-IntelDsaUpdates {
    $sessionPath = "C:\ProgramData\Intel\DSA\Data\session.xml"

    if (-not (Test-Path $sessionPath)) {
        throw "Intel DSA session.xml wurde nicht gefunden."
    }

    [xml]$session = Get-Content $sessionPath -Raw

    #
    # Geräte ermitteln, für die DSA NeedsUpdate meldet.
    #
    # Wir lesen bewusst die IDs aus der Session und verbinden
    # sie anschließend mit den SoftwareConfiguration-Paketen.
    #

    $updateIds = $session.SelectNodes("//*") |
    Where-Object {
        $_.InnerText -match "NeedsUpdate"
    } |
    ForEach-Object {

        if ($_.InnerText -match '(\d{6})NeedsUpdate') {
            $driverMatches[1]
        }
    } |
    Sort-Object -Unique

    if (-not $updateIds) {
        return @()
    }

    #
    # SoftwareConfiguration-Nodes finden.
    #

    $softwareNodes = $session.SelectNodes(
        "//*[local-name()='SoftwareConfiguration']"
    )

    $results = foreach ($software in $softwareNodes) {

        $idNode = $software.SelectSingleNode(
            "./*[local-name()='Id']"
        )

        if (-not $idNode) {
            continue
        }

        $id = $idNode.InnerText

        if ($id -notin $updateIds) {
            continue
        }

        $name = $software.SelectSingleNode(
            "./*[local-name()='Name']"
        ).InnerText

        $version = $software.SelectSingleNode(
            "./*[local-name()='Version']"
        ).InnerText

        $releaseDate = $software.SelectSingleNode(
            "./*[local-name()='DisplayReleaseDate']"
        ).InnerText

        $fileNode = $software.SelectSingleNode(
            "./*[local-name()='Files']/*[local-name()='SoftwareConfigurationFile']"
        )

        if (-not $fileNode) {
            continue
        }

        $downloadUrl = $fileNode.SelectSingleNode(
            "./*[local-name()='Url']"
        ).InnerText

        $hash = $fileNode.SelectSingleNode(
            "./*[local-name()='Hash']"
        ).InnerText

        $size = $fileNode.SelectSingleNode(
            "./*[local-name()='Size']"
        ).InnerText

        $fileName = [System.IO.Path]::GetFileName(
            ([uri]$downloadUrl).AbsolutePath
        )

        [PSCustomObject]@{
            Id          = $id
            Name        = $name
            Version     = $version
            ReleaseDate = [datetime]$releaseDate
            FileName    = $fileName
            DownloadUrl = $downloadUrl
            Hash        = $hash
            Size        = [long]$size
        }
    }

    return @($results)
}


function Get-IntelDriverPackage {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingBrokenHashAlgorithms",
        "",
        Justification = "Intel DSA liefert den Paket-Hash als SHA1; der Wert wird ausschließlich zur Integritätsprüfung gegen Intels eigenen Hash verwendet."
    )]
    param(
        [Parameter(Mandatory)]
        $Update
    )

    $downloadDirectory = Join-Path $env:TEMP "windows-setup\intel"

    if (-not (Test-Path $downloadDirectory)) {
        New-Item `
            -Path $downloadDirectory `
            -ItemType Directory `
            -Force | Out-Null
    }

    $destination = Join-Path `
        $downloadDirectory `
        $Update.FileName

    Write-Host ""
    Write-Host "[DOWNLOAD] $($Update.Name)" -ForegroundColor Cyan
    Write-Host "           Version $($Update.Version)"

    Invoke-WebRequest `
        -Uri $Update.DownloadUrl `
        -OutFile $destination

    $actualHash = (
        Get-FileHash `
            -Path $destination `
            -Algorithm SHA1
    ).Hash.ToLower()

    $expectedHash = $Update.Hash.ToLower()

    if ($actualHash -ne $expectedHash) {
        Remove-Item $destination -Force

        throw "Hash-Prüfung fehlgeschlagen: $($Update.FileName)"
    }

    Write-Host "[OK] Download und Hash-Prüfung erfolgreich." `
        -ForegroundColor Green

    return $destination
}

function Install-IntelDriverPackage {
    param(
        [Parameter(Mandatory)]
        $Update,

        [Parameter(Mandatory)]
        [string]$InstallerPath
    )

    $arguments = $null

    switch -Wildcard ($Update.FileName) {

        "WiFi-*-Driver64-Win10-Win11.exe" {
            $arguments = @(
                "-q"
                "-norestart"
            )
        }

        "BT-*-64UWD-Win10-Win11.exe" {
            $arguments = @(
                "/quiet"
                "/norestart"
            )
        }

        default {
            Write-Warning "Keine Installationsregel für $($Update.FileName) vorhanden."
            return $false
        }
    }

    Write-Host ""
    Write-Host "[INSTALL] $($Update.Name)" -ForegroundColor Cyan
    Write-Host "          Version $($Update.Version)"

    $process = Start-Process `
        -FilePath $InstallerPath `
        -ArgumentList $arguments `
        -Wait `
        -PassThru

    switch ($process.ExitCode) {

        0 {
            Write-Host "[OK] Installation abgeschlossen." `
                -ForegroundColor Green
        }

        3010 {
            Write-Host "[OK] Installation abgeschlossen." `
                -ForegroundColor Green

            Write-Host "[REBOOT] Neustart erforderlich." `
                -ForegroundColor Yellow

            $script:DriverRebootRequired = $true
        }

        1641 {
            throw (
                "$($Update.Name) hat trotz Reboot-Unterdrückung " +
                "einen Neustart ausgelöst."
            )
        }

        default {
            throw (
                "Installation von $($Update.Name) fehlgeschlagen. " +
                "ExitCode: $($process.ExitCode)"
            )
        }
    }

    return $true
}

function Install-IntelDsaUpdates {
    Write-Step "Intel Treiberupdates"

    $updates = @(Get-IntelDsaUpdates)

    if ($updates.Count -eq 0) {
        Write-Host "[OK] Keine Intel-Treiberupdates verfügbar." `
            -ForegroundColor Green

        return
    }

    Write-Host ""
    Write-Host "$($updates.Count) Intel-Update(s) gefunden:"

    foreach ($update in $updates) {
        Write-Host ""
        Write-Host "  $($update.Name)"
        Write-Host "  Version: $($update.Version)"
        Write-Host "  Datum:   $($update.ReleaseDate.ToShortDateString())"
    }

    foreach ($update in $updates) {

        $installer = Get-IntelDriverPackage -Update $update

        try {
            Install-IntelDriverPackage `
                -Update $update `
                -InstallerPath $installer
        }
        finally {
            if (Test-Path $installer) {
                Remove-Item $installer -Force
            }
        }
    }

    Write-Host ""
    Write-Host "[OK] Intel-Treiberupdates verarbeitet." `
        -ForegroundColor Green
}
