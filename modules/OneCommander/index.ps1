$parts = @(
    "01-Get-OneCommanderSettingsPath.ps1"
    "02-Set-OneCommanderDefaultFileManager.ps1"
    "03-Test-OneCommanderRegistryValue.ps1"
)

foreach ($part in $parts) {
    $partPath = Join-Path $PSScriptRoot $part

    if (-not (Test-Path -LiteralPath $partPath -PathType Leaf)) {
        throw "Modulteil nicht gefunden: $partPath"
    }

    . $partPath
}