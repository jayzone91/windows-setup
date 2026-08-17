# @raycast.schemaVersion 1
# @raycast.title FancyZones: Dev
# @raycast.mode silent
# @raycast.description FancyZones-Layout Dev aktivieren
$ErrorActionPreference = 'Stop'

$searchRoots = @(
    "$env:LOCALAPPDATA\PowerToys",
    "$env:ProgramFiles\PowerToys",
    "$env:LOCALAPPDATA\Microsoft\PowerToys"
) | Where-Object {
    -not [string]::IsNullOrWhiteSpace($_) -and
    (Test-Path -LiteralPath $_ -PathType Container)
}

$cli = $searchRoots |
    ForEach-Object {
        Get-ChildItem `
            -LiteralPath $_ `
            -Filter 'FancyZonesCLI.exe' `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue
    } |
    Select-Object -First 1

if (-not $cli) {
    throw 'FancyZonesCLI.exe wurde nicht gefunden.'
}
& $cli.FullName set-layout '{2C70E257-FD89-4B25-B3BA-F1CE9FCA60F6}'

if ($LASTEXITCODE -ne 0) {
    throw "FancyZonesCLI fehlgeschlagen. ExitCode=$LASTEXITCODE"
}