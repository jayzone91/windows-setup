# @raycast.schemaVersion 1
# @raycast.title FancyZones: Normal
# @raycast.mode silent
# @raycast.description FancyZones-Layout Normal aktivieren
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
& $cli.FullName set-layout '{AB73B386-0093-40E4-965A-9CE84E674E21}'

if ($LASTEXITCODE -ne 0) {
    throw "FancyZonesCLI fehlgeschlagen. ExitCode=$LASTEXITCODE"
}