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

$performanceDirectory = Join-Path `
    $RepositoryRoot `
    ".generated\performance"

$tracePath = Join-Path `
    $performanceDirectory `
    "bootstrap-phases.tsv"

if (-not (Test-Path -LiteralPath $performanceDirectory -PathType Container)) {
    New-Item `
        -ItemType Directory `
        -Path $performanceDirectory `
        -Force |
    Out-Null
}

Remove-Item `
    -LiteralPath $tracePath `
    -Force `
    -ErrorAction SilentlyContinue

$previousTrace = $env:WINDOWS_SETUP_PERFORMANCE_TRACE
$previousTracePath = $env:WINDOWS_SETUP_PERFORMANCE_TRACE_PATH

$env:WINDOWS_SETUP_PERFORMANCE_TRACE = "1"
$env:WINDOWS_SETUP_PERFORMANCE_TRACE_PATH = $tracePath

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

    $env:WINDOWS_SETUP_PERFORMANCE_TRACE = $previousTrace
    $env:WINDOWS_SETUP_PERFORMANCE_TRACE_PATH = $previousTracePath
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

if (Test-Path -LiteralPath $tracePath -PathType Leaf) {
    Write-Host ""
    Write-Host "Bootstrap-Phasen:"

    foreach ($line in Get-Content -LiteralPath $tracePath) {
        $parts = $line -split "`t"

        if ($parts.Count -eq 3) {
            Write-Host (
                "{0,-40} {1,8}s  gesamt {2,8}s" -f
                $parts[0],
                $parts[1],
                $parts[2]
            )
        }
    }
}

if ($exitCode -ne 0) {
    throw (
        "Bootstrap-Performance-Lauf ist mit Exit-Code {0} fehlgeschlagen." -f
        $exitCode
    )
}