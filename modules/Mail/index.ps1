$parts = @(
    "Thunderbird.ps1"
    "Provisioning.State.ps1"
    "Provisioning.ps1"
    "Outlook.ps1"
)

foreach ($part in $parts) {
    $partPath = Join-Path $PSScriptRoot $part

    if (-not (Test-Path -LiteralPath $partPath -PathType Leaf)) {
        throw "Mail-Modulteil nicht gefunden: $partPath"
    }

    . $partPath
}