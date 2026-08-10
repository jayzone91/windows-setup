function Get-WindhawkRelease {
    [CmdletBinding()]
    param()

    Write-Host "[INFO] Ermittle aktuelle Windhawk-2.x-Version."

    $releases = Invoke-RestMethod `
        -Uri "https://api.github.com/repos/ramensoftware/windhawk/releases" `
        -Headers @{
        Accept = "application/vnd.github+json"
    }

    $stableReleases = @(
        $releases |
        Where-Object {
            -not $_.draft -and
            -not $_.prerelease -and
            $_.tag_name -match '^v?2\.'
        }
    )

    $prereleases = @(
        $releases |
        Where-Object {
            -not $_.draft -and
            $_.prerelease -and
            $_.tag_name -match '^v?2\.'
        }
    )

    if ($stableReleases.Count -gt 0) {
        $release = $stableReleases |
        Sort-Object {
            [version](
                $_.tag_name `
                    -replace '^v', '' `
                    -replace '-.*$', ''
            )
        } -Descending |
        Select-Object -First 1

        Write-Host (
            "[OK] Stabile Windhawk-Version gefunden: " +
            $release.tag_name
        ) -ForegroundColor Green

        return $release
    }

    if ($prereleases.Count -gt 0) {
        $release = $prereleases |
        Sort-Object published_at -Descending |
        Select-Object -First 1

        Write-Host (
            "[INFO] Keine stabile Windhawk-2.x-Version vorhanden. " +
            "Verwende Pre-Release: " +
            $release.tag_name
        )

        return $release
    }

    throw "Keine Windhawk-2.x-Version auf GitHub gefunden."
}


function Get-WindhawkCliPath {
    [CmdletBinding()]
    param()

    $paths = @(
        "$env:ProgramFiles\Windhawk\windhawk-cli.exe"
        "${env:ProgramFiles(x86)}\Windhawk\windhawk-cli.exe"
    )

    foreach ($path in $paths) {
        if ($path -and (Test-Path $path)) {
            return $path
        }
    }

    $command = Get-Command `
        -Name "windhawk-cli.exe" `
        -ErrorAction SilentlyContinue

    if ($command) {
        return $command.Source
    }

    return $null
}


function Get-InstalledWindhawkVersion {
    [CmdletBinding()]
    param()

    $cli = Get-WindhawkCliPath

    if (-not $cli) {
        return $null
    }

    try {
        $output = & $cli --version 2>$null

        if ($LASTEXITCODE -ne 0) {
            return $null
        }

        $versionText = [string]$output

        if ($versionText -match '(\d+\.\d+\.\d+(?:-[^\s]+)?)') {
            return $Matches[1]
        }
    }
    catch {
        return $null
    }

    return $null
}


function Install-Windhawk {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windhawk"
    Write-Host "========================================"
    Write-Host ""

    $release = Get-WindhawkRelease

    $targetVersion = $release.tag_name -replace '^v', ''

    $installedVersion = Get-InstalledWindhawkVersion

    if ($installedVersion) {
        Write-Host (
            "[INFO] Installierte Version: " +
            $installedVersion
        )

        Write-Host (
            "[INFO] Gewünschte Version: " +
            $targetVersion
        )

        if ($installedVersion -eq $targetVersion) {
            Write-Host (
                "[OK] Windhawk ist bereits aktuell."
            ) -ForegroundColor Green

            return
        }
    }
    else {
        Write-Host "[INFO] Windhawk 2.x ist nicht installiert."
    }


    $architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture

    if ($architecture -notin @(
            [System.Runtime.InteropServices.Architecture]::X64,
            [System.Runtime.InteropServices.Architecture]::Arm64
        )) {
        throw (
            "Nicht unterstützte Architektur für Windhawk: " +
            $architecture
        )
    }

    $preferredAssetNames = @(
        "windhawk_setup.exe"
        "windhawk_setup_offline.exe"
    )

    $asset = $null

    foreach ($assetName in $preferredAssetNames) {
        $asset = $release.assets |
        Where-Object {
            $_.name -ieq $assetName
        } |
        Select-Object -First 1

        if ($asset) {
            break
        }
    }

    if (-not $asset) {
        $installerAssets = @(
            $release.assets |
            Where-Object {
                $_.name -match '(?i)^windhawk.*setup.*\.exe$' -and
                $_.name -notmatch '(?i)portable'
            }
        )

        if ($installerAssets.Count -eq 1) {
            $asset = $installerAssets[0]
        }
    }

    if (-not $asset) {
        Write-Host "[INFO] Verfügbare Release-Assets:"

        foreach ($releaseAsset in $release.assets) {
            Write-Host (
                "  - " +
                $releaseAsset.name
            )
        }

        throw (
            "Kein geeigneter Windhawk-Installer im Release " +
            "$($release.tag_name) gefunden."
        )
    }


    Write-Host (
        "[INFO] Installer: " +
        $asset.name
    )

    $tempDirectory = Join-Path `
        $env:TEMP `
        "windows-setup-windhawk"

    if (-not (Test-Path $tempDirectory)) {
        New-Item `
            -ItemType Directory `
            -Path $tempDirectory `
            -Force |
        Out-Null
    }

    $installerPath = Join-Path `
        $tempDirectory `
        $asset.name

    try {
        Write-Host "[INFO] Lade Windhawk herunter."

        Invoke-WebRequest `
            -Uri $asset.browser_download_url `
            -OutFile $installerPath `
            -UseBasicParsing

        Write-Host "[INFO] Installiere Windhawk."

        $process = Start-Process `
            -FilePath $installerPath `
            -ArgumentList "/S" `
            -Wait `
            -PassThru

        if ($process.ExitCode -ne 0) {
            throw (
                "Windhawk-Installer wurde mit ExitCode " +
                "$($process.ExitCode) beendet."
            )
        }

        Start-Sleep -Seconds 2

        $cli = Get-WindhawkCliPath

        if (-not $cli) {
            throw (
                "Windhawk wurde installiert, aber " +
                "windhawk-cli.exe wurde nicht gefunden."
            )
        }

        $actualVersion = Get-InstalledWindhawkVersion

        Write-Host (
            "[OK] Windhawk installiert: " +
            $actualVersion
        ) -ForegroundColor Green
    }
    finally {
        if (Test-Path $installerPath) {
            Remove-Item `
                -Path $installerPath `
                -Force `
                -ErrorAction SilentlyContinue
        }
    }
}

function Get-WindhawkInstalledMods {
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    $cli = Get-WindhawkCliPath

    if (-not $cli) {
        throw "windhawk-cli.exe wurde nicht gefunden."
    }

    $response = & $cli --json mod list |
    ConvertFrom-Json

    if (-not $response.success) {
        throw "Installierte Windhawk-Mods konnten nicht gelesen werden."
    }

    if ($response.data.mods) {
        return , @($response.data.mods)
    }

    return , @()
}


function Test-WindhawkModInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ModId
    )

    $mods = Get-WindhawkInstalledMods

    return @(
        $mods |
        Where-Object {
            $_.id -eq $ModId
        }
    ).Count -gt 0
}


function Install-WindhawkMod {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ModId
    )

    $cli = Get-WindhawkCliPath

    if (-not $cli) {
        throw "windhawk-cli.exe wurde nicht gefunden."
    }

    if (Test-WindhawkModInstalled -ModId $ModId) {
        Write-Host "[INFO] Windhawk-Mod vorhanden: $ModId"

        & $cli mod update $ModId

        if ($LASTEXITCODE -ne 0) {
            Write-Warning (
                "Windhawk-Mod konnte nicht aktualisiert werden: " +
                $ModId
            )
        }

        & $cli mod enable $ModId

        return
    }

    Write-Host "[INSTALL] Windhawk-Mod: $ModId"

    & $cli mod install $ModId

    if ($LASTEXITCODE -ne 0) {
        throw "Windhawk-Mod konnte nicht installiert werden: $ModId"
    }

    & $cli mod enable $ModId

    if ($LASTEXITCODE -ne 0) {
        throw "Windhawk-Mod konnte nicht aktiviert werden: $ModId"
    }
}


function ConvertTo-WindhawkSettingPairs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Settings,

        [string] $Prefix = ""
    )

    $pairs = [System.Collections.Generic.List[string]]::new()

    foreach ($key in $Settings.Keys) {
        $path = if ($Prefix) {
            "$Prefix.$key"
        }
        else {
            [string] $key
        }

        $value = $Settings[$key]

        if ($value -is [System.Collections.IDictionary]) {
            $nestedPairs = ConvertTo-WindhawkSettingPairs `
                -Settings $value `
                -Prefix $path

            foreach ($pair in $nestedPairs) {
                $pairs.Add($pair)
            }

            continue
        }

        if (
            $value -is [System.Collections.IEnumerable] -and
            $value -isnot [string]
        ) {
            $index = 0

            foreach ($item in $value) {
                $itemPath = "${path}[$index]"

                if ($item -is [System.Collections.IDictionary]) {
                    $nestedPairs = ConvertTo-WindhawkSettingPairs `
                        -Settings $item `
                        -Prefix $itemPath

                    foreach ($pair in $nestedPairs) {
                        $pairs.Add($pair)
                    }
                }
                else {
                    $itemValue = if ($item -is [bool]) {
                        $item.ToString().ToLowerInvariant()
                    }
                    elseif ($null -eq $item) {
                        ""
                    }
                    else {
                        [string] $item
                    }

                    $pairs.Add("$itemPath=$itemValue")
                }

                $index++
            }

            continue
        }

        $serializedValue = if ($value -is [bool]) {
            $value.ToString().ToLowerInvariant()
        }
        elseif ($null -eq $value) {
            ""
        }
        else {
            [string] $value
        }

        $pairs.Add("$path=$serializedValue")
    }

    return $pairs.ToArray()
}


function Set-WindhawkModSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ModId,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Settings
    )

    $cli = Get-WindhawkCliPath

    if (-not $cli) {
        throw "windhawk-cli.exe wurde nicht gefunden."
    }

    $pairs = @(
        ConvertTo-WindhawkSettingPairs `
            -Settings $Settings
    )

    if ($pairs.Count -eq 0) {
        return
    }

    Write-Host "[CONFIG] Windhawk-Mod Settings: $ModId"

    & $cli mod settings set $ModId @pairs

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Windhawk-Mod-Settings konnten nicht gesetzt werden: " +
            $ModId
        )
    }
}


function Set-WindhawkModEnabledState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ModId,

        [Parameter(Mandatory)]
        [bool] $Enabled
    )

    $cli = Get-WindhawkCliPath

    if (-not $cli) {
        throw "windhawk-cli.exe wurde nicht gefunden."
    }

    if ($Enabled) {
        & $cli mod enable $ModId
    }
    else {
        & $cli mod disable $ModId
    }

    if ($LASTEXITCODE -ne 0) {
        $state = if ($Enabled) {
            "aktiviert"
        }
        else {
            "deaktiviert"
        }

        throw "Windhawk-Mod konnte nicht $state werden: $ModId"
    }
}


function Set-WindhawkConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Config
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windhawk Konfiguration"
    Write-Host "========================================"
    Write-Host ""

    if (-not $Config.Mods) {
        Write-Host "[INFO] Keine Windhawk-Mods konfiguriert."
        return
    }

    foreach ($mod in $Config.Mods) {
        if (-not $mod.Id) {
            throw "Windhawk-Mod ohne Id in der Konfiguration."
        }

        $name = if ($mod.Name) {
            $mod.Name
        }
        else {
            $mod.Id
        }

        Write-Host ""
        Write-Host "[MOD] $name ($($mod.Id))"

        if (-not (Test-WindhawkModInstalled -ModId $mod.Id)) {
            Install-WindhawkMod -ModId $mod.Id
        }
        else {
            Write-Host "[OK] Windhawk-Mod bereits installiert: $($mod.Id)"
        }

        if ($mod.Settings) {
            Set-WindhawkModSettings `
                -ModId $mod.Id `
                -Settings $mod.Settings
        }

        $enabled = if ($null -eq $mod.Enabled) {
            $true
        }
        else {
            [bool] $mod.Enabled
        }

        Set-WindhawkModEnabledState `
            -ModId $mod.Id `
            -Enabled $enabled
    }

    Write-Host ""
    Write-Host "[OK] Windhawk-Konfiguration angewendet." `
        -ForegroundColor Green
}
