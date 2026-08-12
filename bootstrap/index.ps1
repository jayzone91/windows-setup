$parts = @(
    "01-Setup.ps1"
    "02-Setup.ps1"
)

foreach ($part in $parts) {
    $partPath = Join-Path $PSScriptRoot $part

    if (-not (Test-Path -LiteralPath $partPath -PathType Leaf)) {
        throw "Bootstrap-Teil nicht gefunden: $partPath"
    }

    . $partPath
}