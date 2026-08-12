$parts = @(
    "01-Set-PowerShellPreferences.ps1"
    "02-Test-PowerShellCode.ps1"
    "03-CSharpCode.ps1"
)

foreach ($part in $parts) {
    $partPath = Join-Path $PSScriptRoot $part

    if (-not (Test-Path -LiteralPath $partPath -PathType Leaf)) {
        throw "Modulteil nicht gefunden: $partPath"
    }

    . $partPath
}