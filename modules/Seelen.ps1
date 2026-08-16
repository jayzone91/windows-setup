function Set-SeelenConfiguration {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Seelen UI"
    Write-Host "========================================"

    $source = Join-Path `
        $RepositoryPath `
        "dotfiles\seelen\settings.json"

    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Seelen-Konfiguration nicht gefunden: $source"
    }

    $destinationDirectory = Join-Path `
        $env:APPDATA `
        "com.seelen.seelen-ui"

    $destination = Join-Path `
        $destinationDirectory `
        "settings.json"

    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
        New-Item `
            -ItemType Directory `
            -Path $destinationDirectory `
            -Force |
        Out-Null
    }

    $changed = -not (
        Test-FileHardLinkTarget `
            -Path $destination `
            -Target $source
    )

    $null = Set-FileHardLink `
        -Path $destination `
        -Target $source `
        -ReplaceExistingFile

    if ($changed) {
        Write-Host "[OK] Seelen settings.json aktualisiert." `
            -ForegroundColor Green
    }
    else {
        Write-Host "[SKIP] Seelen settings.json bereits aktuell." `
            -ForegroundColor Green
    }

    return $changed
}
