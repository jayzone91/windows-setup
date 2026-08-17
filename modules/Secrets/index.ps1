$parts = @(
    "Age.ps1"
)

foreach ($part in $parts) {
    $partPath = Join-Path $PSScriptRoot $part

    if (-not (Test-Path -LiteralPath $partPath -PathType Leaf)) {
        throw "Secrets-Modulteil nicht gefunden: $partPath"
    }

    . $partPath
}