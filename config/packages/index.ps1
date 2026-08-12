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

        $packages[$key] = $data[$key]
    }
}

return $packages