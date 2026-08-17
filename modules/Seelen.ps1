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

    $themeSource = Join-Path `
        $RepositoryPath `
        "dotfiles\seelen\themes\macos26-liquid-glass"

    if (-not (Test-Path -LiteralPath $themeSource -PathType Container)) {
        throw "Seelen-Theme nicht gefunden: $themeSource"
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

    $themeDestination = Join-Path `
        $destinationDirectory `
        "themes\macos26-liquid-glass"

    $themeChanged = -not (
        Test-DirectoryJunctionTarget `
            -Path $themeDestination `
            -Target $themeSource
    )

    $null = Set-DirectoryJunction `
        -Path $themeDestination `
        -Target $themeSource

    if ($themeChanged) {
        Write-Host "[OK] Seelen macOS-26-Theme aktualisiert." `
            -ForegroundColor Green
    }
    else {
        Write-Host "[SKIP] Seelen macOS-26-Theme bereits aktuell." `
            -ForegroundColor Green
    }

    $settingsChanged = -not (
        Test-FileSymbolicLinkTarget `
            -Path $destination `
            -Target $source
    )

    $null = Set-FileSymbolicLink `
        -Path $destination `
        -Target $source `
        -ReplaceExistingFile

    if ($settingsChanged) {
        Write-Host "[OK] Seelen settings.json aktualisiert." `
            -ForegroundColor Green
    }
    else {
        Write-Host "[SKIP] Seelen settings.json bereits aktuell." `
            -ForegroundColor Green
    }

    return ($themeChanged -or $settingsChanged)
}