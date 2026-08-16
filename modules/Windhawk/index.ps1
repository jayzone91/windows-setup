$parts = @(
    "01-Get-WindhawkRelease.ps1"
    "02-ConvertTo-WindhawkSettingPairs.ps1"
    "03-WindhawkDevelopmentTools.ps1"
    "04-WindhawkLocalMod.ps1"
)

foreach ($part in $parts) {
    $partPath = Join-Path $PSScriptRoot $part

    if (-not (Test-Path -LiteralPath $partPath -PathType Leaf)) {
        throw "Modulteil nicht gefunden: $partPath"
    }

    . $partPath
}
