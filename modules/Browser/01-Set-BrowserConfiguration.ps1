function Set-BrowserConfiguration {
    param(
        [Parameter(Mandatory)]
        $Config
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Browser"
    Write-Host "========================================"

    $configurationChanged = $false

    if ($Config.ChromeBeta) {
        $chromiumChanged = Set-ChromiumExtensions `
            -Extensions $Config.ChromeBeta.Extensions `
            -PolicyPath $Config.ChromeBeta.PolicyPath

        if ($chromiumChanged) {
            $configurationChanged = $true
        }
    }

    if ($Config.Zen) {
        $zenChanged = Set-ZenConfiguration `
            -Config $Config.Zen

        if ($zenChanged) {
            $configurationChanged = $true
        }

        if ($Config.Zen.Mods) {
            Set-ZenMods `
                -Mods $Config.Zen.Mods
        }

        $zenThemeChanged = Set-ZenTheme

        if ($zenThemeChanged) {
            $configurationChanged = $true
        }
    }

    Write-Host ""
    Write-Host "[OK] Browser Konfiguration abgeschlossen." `
        -ForegroundColor Green

    return $configurationChanged
}



function Set-ChromiumExtensions {
    param(
        [Parameter(Mandatory)]
        $Extensions,

        [Parameter(Mandatory)]
        $PolicyPath
    )

    Write-Host ""
    Write-Host "[CONFIG] Chromium Extensions"

    $extensionPath = Join-Path `
        $PolicyPath `
        "ExtensionInstallForcelist"

    $desired = [ordered]@{}
    $index = 1

    foreach ($extension in $Extensions) {
        $desired[[string]$index] = (
            "{0};https://clients2.google.com/service/update2/crx" -f
            $extension.Id
        )

        $index++
    }

    $current = [ordered]@{}

    if (Test-Path -LiteralPath $extensionPath) {
        $properties = Get-ItemProperty `
            -Path $extensionPath `
            -ErrorAction SilentlyContinue

        if ($properties) {
            foreach ($property in $properties.PSObject.Properties) {
                if ($property.Name -notmatch '^PS') {
                    $current[$property.Name] = [string]$property.Value
                }
            }
        }
    }

    $isCurrent = $current.Count -eq $desired.Count

    if ($isCurrent) {
        foreach ($entry in $desired.GetEnumerator()) {
            if (
                -not $current.Contains($entry.Key) -or
                $current[$entry.Key] -cne $entry.Value
            ) {
                $isCurrent = $false
                break
            }
        }
    }

    if ($isCurrent) {
        Write-Host "[SKIP] Chromium Extension-Policies unverändert." `
            -ForegroundColor Green

        return $false
    }

    if (Test-Path -LiteralPath $extensionPath) {
        Remove-Item `
            -LiteralPath $extensionPath `
            -Recurse `
            -Force
    }

    New-Item `
        -Path $extensionPath `
        -Force |
    Out-Null

    foreach ($entry in $desired.GetEnumerator()) {
        New-ItemProperty `
            -Path $extensionPath `
            -Name $entry.Key `
            -PropertyType String `
            -Value $entry.Value `
            -Force |
        Out-Null
    }

    Write-Host "[OK] Chromium Extension-Policies aktualisiert." `
        -ForegroundColor Green

    return $true
}

function Get-ZenInstallPath {

    $possiblePaths = @(
        "${env:ProgramFiles}\Zen Browser",
        "${env:ProgramFiles(x86)}\Zen Browser",
        "$env:LOCALAPPDATA\Programs\Zen Browser"
    )


    foreach ($path in $possiblePaths) {

        if (Test-Path $path) {

            $exe = Join-Path `
                $path `
                "zen.exe"


            if (Test-Path $exe) {
                return $path
            }
        }
    }


    return $null
}

function Read-ZenMarionettePacket {

    param(
        [Parameter(Mandatory)]
        [System.Net.Sockets.NetworkStream] $Stream
    )

    $lengthText = ""

    while ($true) {

        $byte = $Stream.ReadByte()

        if ($byte -eq -1) {
            throw "Marionette Verbindung wurde geschlossen."
        }

        $char = [char]$byte

        if ($char -eq ":") {
            break
        }

        $lengthText += $char
    }

    if (-not $lengthText) {
        throw "Ungültiges Marionette Paket."
    }

    $length = [int]$lengthText
    $buffer = [byte[]]::new($length)
    $offset = 0

    while ($offset -lt $length) {

        $read = $Stream.Read(
            $buffer,
            $offset,
            $length - $offset
        )

        if ($read -le 0) {
            throw "Marionette Paket wurde unvollständig übertragen."
        }

        $offset += $read
    }

    $json = [System.Text.Encoding]::UTF8.GetString($buffer)

    return $json | ConvertFrom-Json
}


function Send-ZenMarionettePacket {

    param(
        [Parameter(Mandatory)]
        [System.Net.Sockets.NetworkStream] $Stream,

        [Parameter(Mandatory)]
        $Packet
    )

    $json = $Packet |
    ConvertTo-Json `
        -Compress `
        -Depth 30

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)

    $prefix = [System.Text.Encoding]::ASCII.GetBytes(
        "$($bytes.Length):"
    )

    $Stream.Write(
        $prefix,
        0,
        $prefix.Length
    )

    $Stream.Write(
        $bytes,
        0,
        $bytes.Length
    )

    $Stream.Flush()
}



function Get-ZenProfilePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $zenRoot = Join-Path `
        $env:APPDATA `
        "zen"

    if (-not (Test-Path $zenRoot)) {
        return $null
    }

    #
    # 1. Aktives Installationsprofil aus installs.ini
    #
    $installsIni = Join-Path `
        $zenRoot `
        "installs.ini"

    if (Test-Path $installsIni) {

        $defaultPath = Get-Content `
            -Path $installsIni `
            -ErrorAction SilentlyContinue |
        Where-Object {
            $_ -match '^Default=(.+)$'
        } |
        Select-Object -First 1

        if ($defaultPath -match '^Default=(.+)$') {

            $profilePath = Join-Path `
                $zenRoot `
                $Matches[1]

            if (Test-Path $profilePath) {
                return $profilePath
            }
        }
    }

    #
    # 2. Install-Sektion aus profiles.ini
    #
    $profilesIni = Join-Path `
        $zenRoot `
        "profiles.ini"

    if (Test-Path $profilesIni) {

        $lines = @(
            Get-Content `
                -Path $profilesIni `
                -ErrorAction SilentlyContinue
        )

        $insideInstallSection = $false

        foreach ($line in $lines) {

            $trimmed = $line.Trim()

            if ($trimmed -match '^\[Install.+\]$') {
                $insideInstallSection = $true
                continue
            }

            if ($trimmed -match '^\[.+\]$') {
                $insideInstallSection = $false
                continue
            }

            if (
                $insideInstallSection -and
                $trimmed -match '^Default=(.+)$'
            ) {

                $profilePath = Join-Path `
                    $zenRoot `
                    $Matches[1]

                if (Test-Path $profilePath) {
                    return $profilePath
                }
            }
        }
    }

    #
    # 3. Fallback:
    # Wenn genau ein Profil eine zen-themes.json besitzt,
    # ist dieses Profil für unsere Mod-Prüfung eindeutig.
    #
    $modFiles = @(
        Get-ChildItem `
            -Path $zenRoot `
            -Filter "zen-themes.json" `
            -Recurse `
            -File `
            -Force `
            -ErrorAction SilentlyContinue
    )

    if ($modFiles.Count -eq 1) {
        return $modFiles[0].Directory.FullName
    }

    Write-Warning (
        "Aktives Zen-Profil konnte nicht eindeutig ermittelt werden."
    )

    return $null
}