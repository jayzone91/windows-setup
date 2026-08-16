$parts = @(
    "01-Test-WingetPackage.ps1"
    "02-Install-ChocolateyPackage.ps1"
    "03-Initialize-PackageManagers.ps1"
    "04-Update-MicrosoftStoreApps.ps1"
)

foreach ($part in $parts) {
    $partPath = Join-Path $PSScriptRoot $part

    if (-not (Test-Path -LiteralPath $partPath -PathType Leaf)) {
        throw "Modulteil nicht gefunden: $partPath"
    }

    . $partPath
}
