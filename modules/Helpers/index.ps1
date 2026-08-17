$parts = @(
    "01-Test-DirectoryJunctionTarget.ps1"
    "02-Set-FileSymbolicLink.ps1"
    "03-Test-GitHubAvailability.ps1"
)

foreach ($part in $parts) {
    $partPath = Join-Path $PSScriptRoot $part

    if (-not (Test-Path -LiteralPath $partPath -PathType Leaf)) {
        throw "Modulteil nicht gefunden: $partPath"
    }

    . $partPath
}