#Requires -Version 7.0

$ErrorActionPreference = "Stop"

$RepositoryRoot = Split-Path `
    -Path $PSScriptRoot `
    -Parent

$BootstrapPath = Join-Path `
    $RepositoryRoot `
    "bootstrap.ps1"

if (-not (Test-Path -LiteralPath $BootstrapPath -PathType Leaf)) {
    throw "bootstrap.ps1 wurde nicht gefunden: $BootstrapPath"
}

$pwsh = (
    Get-Command `
        -Name "pwsh" `
        -ErrorAction Stop
).Source

$stopwatch = [Diagnostics.Stopwatch]::StartNew()

try {
    Push-Location $RepositoryRoot

    & $pwsh `
        -NoProfile `
        -ExecutionPolicy Bypass `
        -File $BootstrapPath

    $exitCode = $LASTEXITCODE
}
finally {
    $stopwatch.Stop()
    Pop-Location
}

Write-Host ""
Write-Host (
    "Bootstrap-Laufzeit: {0:mm\:ss\.ff}" -f
    $stopwatch.Elapsed
)

Write-Host (
    "TotalSeconds: {0:N2}" -f
    $stopwatch.Elapsed.TotalSeconds
)

if ($exitCode -ne 0) {
    throw (
        "Bootstrap-Performance-Lauf ist mit Exit-Code {0} fehlgeschlagen." -f
        $exitCode
    )
}