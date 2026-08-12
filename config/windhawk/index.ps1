$ErrorActionPreference = "Stop"

$modFiles = @(
    "01-windows-11-taskbar-styler.psd1"
    "02-windows-11-start-menu-styler.psd1"
    "03-windows-11-notification-center-styler.psd1"
    "04-taskbar-auto-hide-speed.psd1"
    "05-lock-keys-notifier.psd1"
)

$config = @{
    Mods = @()
}

foreach ($modFile in $modFiles) {
    $path = Join-Path $PSScriptRoot $modFile

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Windhawk-Konfiguration nicht gefunden: $path"
    }

    $data = Import-PowerShellDataFile -LiteralPath $path
    $config.Mods += @($data.Mods)
}

return $config