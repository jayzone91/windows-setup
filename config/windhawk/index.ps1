$ErrorActionPreference = "Stop"

$modFiles = @(
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
