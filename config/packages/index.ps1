# ============================================================
# Paket-Konfiguration
# ============================================================
#
# Unterstützte Paketquellen:
#
#   Winget
#     Id     = Winget-Paket-ID
#     Source = "winget"
#
#   Microsoft Store
#     Id     = Store-Paket-ID
#     Source = "msstore"
#
#   Chocolatey
#     Id     = Chocolatey-Paketname
#     Source = "chocolatey"
#
#   Scoop
#     Id        = Scoop-Paketname
#     Source    = "scoop"
#     Bucket    = "extras"          # Pflichtfeld, auch "main" explizit angeben
#     BucketUrl = "https://..."     # nur für eigene / unbekannte Buckets
#
# Gemeinsame Optionen:
#
#   Name   = Anzeigename
#   Update = $true / $false
#
# Gaming-Launcher können zusätzlich verwenden:
#
#   GameLibrary = "Steam" # Schlüssel aus config/storage.psd1 -> GameLibraries#
# Winget unterstützt zusätzlich:
#
#   Version = "1.2.3"               # feste Version
#   InstallLocation = "%PROGRAMFILES%\App" # optionaler Installationspfad
#
# Beispiele:
#
# @{
#     Name   = "Git"
#     Id     = "Git.Git"
#     Source = "winget"
#     Update = $true
# }
#
# @{
#     Name   = "FileZilla Client"
#     Id     = "filezilla"
#     Source = "chocolatey"
#     Update = $true
# }
#
# @{
#     Name   = "Beispiel"
#     Id     = "example"
#     Source = "scoop"
#     Bucket = "versions"
#     Update = $true
# }
#
# Benötigte Scoop-Buckets werden automatisch aus allen
# Scoop-Paketdefinitionen ermittelt und vor der Paketinstallation
# hinzugefügt. Für bekannte Buckets reicht "Bucket". Für eigene
# Buckets zusätzlich "BucketUrl" angeben.
#
# Chocolatey und Scoop werden vom Bootstrap automatisch
# installiert und bei jedem Lauf selbst aktualisiert.
#
# ============================================================

$ErrorActionPreference = "Stop"

$groupFiles = @(
    "Base.psd1"
    "Drivers.psd1"
    "Tools.psd1"
    "HomeOffice.psd1"
    "Gaming.psd1"
    "Browser.psd1"
    "Development.psd1"
)

function Test-PackageDefinition {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Package,

        [Parameter(Mandatory)]
        [string]$GroupName
    )

    foreach ($requiredKey in @("Id", "Name", "Source", "Update")) {
        if (-not $Package.ContainsKey($requiredKey)) {
            throw "Package '$GroupName' fehlt Pflichtfeld '$requiredKey'."
        }
    }

    foreach ($stringKey in @("Id", "Name", "Source")) {
        if ([string]::IsNullOrWhiteSpace([string]$Package[$stringKey])) {
            throw "Package '$GroupName' enthält leeres Pflichtfeld '$stringKey'."
        }
    }

    if ($Package.Update -isnot [bool]) {
        throw "Package '$GroupName/$($Package.Name)' enthält ungültiges Update-Feld."
    }

    $supportedSources = @(
        "winget"
        "msstore"
        "chocolatey"
        "scoop"
    )

    if ($Package.Source -notin $supportedSources) {
        throw "Package '$GroupName/$($Package.Name)' verwendet unbekannte Source '$($Package.Source)'."
    }

    if ($Package.Source -eq "scoop") {
        if (
            -not $Package.ContainsKey("Bucket") -or
            [string]::IsNullOrWhiteSpace([string]$Package.Bucket)
        ) {
            throw "Scoop-Package '$GroupName/$($Package.Name)' benötigt Bucket."
        }
    }
}

$packages = @{}

foreach ($groupFile in $groupFiles) {
    $path = Join-Path $PSScriptRoot $groupFile

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Package-Konfiguration nicht gefunden: $path"
    }

    $data = Import-PowerShellDataFile -LiteralPath $path

    foreach ($key in $data.Keys) {
        if ($packages.ContainsKey($key)) {
            throw "Doppelte Package-Gruppe: $key"
        }

        foreach ($package in @($data[$key])) {
            if ($package -isnot [hashtable]) {
                throw "Package-Gruppe '$key' enthält einen ungültigen Eintrag."
            }

            Test-PackageDefinition `
                -Package $package `
                -GroupName $key
        }

        $packages[$key] = $data[$key]
    }
}

return $packages