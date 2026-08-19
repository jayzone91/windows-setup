$parts = @(
    "01-Set-BrowserConfiguration.ps1"
    "02-Get-MissingZenMods.ps1"
    "03-Install-ZenMod.ps1"
    "04-Set-ZenTheme.ps1"
)

foreach ($part in $parts) {
    $partPath = Join-Path $PSScriptRoot $part

    if (-not (Test-Path -LiteralPath $partPath -PathType Leaf)) {
        throw "Modulteil nicht gefunden: $partPath"
    }

    . $partPath
}