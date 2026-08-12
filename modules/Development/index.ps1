$parts = @(
    "01-Install-CodexCli.ps1"
    "02-Update-NeovimConfiguration.ps1"
    "03-Show-NeovimMaintenanceStatus.ps1"
)

foreach ($part in $parts) {
    $partPath = Join-Path $PSScriptRoot $part

    if (-not (Test-Path -LiteralPath $partPath -PathType Leaf)) {
        throw "Modulteil nicht gefunden: $partPath"
    }

    . $partPath
}