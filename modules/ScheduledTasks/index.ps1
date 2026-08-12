$parts = @(
    "01-ConvertTo-WindowsTaskUserIdentity.ps1"
    "02-Restart-WindowsVolumeOsd.ps1"
    "03-Stop-WindowsDesktopEnvironment.ps1"
)

foreach ($part in $parts) {
    $partPath = Join-Path $PSScriptRoot $part

    if (-not (Test-Path -LiteralPath $partPath -PathType Leaf)) {
        throw "Modulteil nicht gefunden: $partPath"
    }

    . $partPath
}