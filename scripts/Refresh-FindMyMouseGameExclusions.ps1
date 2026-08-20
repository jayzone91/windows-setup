$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot

Start-Sleep -Seconds 10

. (Join-Path $root "modules\index.ps1")

$storage = Import-PowerShellDataFile (
    Join-Path $root "config\storage.psd1"
)

$powerToys = Import-PowerShellDataFile (
    Join-Path $root "config\powertoys.psd1"
)

$installedGameExecutables = @(
    Get-InstalledGameExecutable `
        -StorageConfig $storage |
    Select-Object -ExpandProperty Executable -Unique
)

$excludedApps = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)

foreach ($app in @($powerToys.FindMyMouse.ExcludedApps)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$app)) {
        [void]$excludedApps.Add(([string]$app).Trim())
    }
}

foreach ($app in $installedGameExecutables) {
    if (-not [string]::IsNullOrWhiteSpace([string]$app)) {
        [void]$excludedApps.Add(([string]$app).Trim())
    }
}

$desired = (
    @($excludedApps) |
    Sort-Object
) -join [Environment]::NewLine

$settingsPath = Join-Path `
    $env:LOCALAPPDATA `
    "Microsoft\PowerToys\FindMyMouse\settings.json"

if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
    throw "Find-My-Mouse-Konfiguration fehlt: $settingsPath"
}

$settings = Get-Content -LiteralPath $settingsPath -Raw |
    ConvertFrom-Json -Depth 100

if ([string]$settings.properties.excluded_apps.value -eq $desired) {
    exit 0
}

$settings.properties.excluded_apps.value = $desired

Write-PowerToysJson `
    -Path $settingsPath `
    -Object $settings