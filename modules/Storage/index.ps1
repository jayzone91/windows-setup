$parts = @(
    "01-Get-EmptyInternalDisk.ps1"
    "02-Set-DevDrivePackageCaches.ps1"
)

foreach ($part in $parts) {
    $partPath = Join-Path $PSScriptRoot $part

    if (-not (Test-Path -LiteralPath $partPath -PathType Leaf)) {
        throw "Modulteil nicht gefunden: $partPath"
    }

    . $partPath
}