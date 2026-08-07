function Set-NushellPreferences {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Nushell"
    Write-Host "========================================"

    if (-not (Get-Command nu -ErrorAction SilentlyContinue)) {
        throw "Nushell wurde nicht gefunden."
    }

    $sourceDirectory = Join-Path `
        $PSScriptRoot `
        "..\dotfiles\nushell"

    $configSource = Join-Path `
        $sourceDirectory `
        "config.nu"

    $envSource = Join-Path `
        $sourceDirectory `
        "env.nu"

    if (-not (Test-Path $configSource)) {
        throw "Nushell config.nu nicht gefunden: $configSource"
    }

    if (-not (Test-Path $envSource)) {
        throw "Nushell env.nu nicht gefunden: $envSource"
    }

    $configDirectory = Join-Path `
        $env:APPDATA `
        "nushell"

    $configDestination = Join-Path `
        $configDirectory `
        "config.nu"

    $envDestination = Join-Path `
        $configDirectory `
        "env.nu"

    if (-not (Test-Path $configDirectory)) {
        New-Item `
            -Path $configDirectory `
            -ItemType Directory `
            -Force | Out-Null
    }

    # ------------------------------------------------------------
    # config.nu
    # ------------------------------------------------------------

    if (Get-Item -LiteralPath $configDestination -Force -ErrorAction SilentlyContinue) {
        Remove-Item `
            -LiteralPath $configDestination `
            -Force
    }

    New-Item `
        -ItemType SymbolicLink `
        -Path $configDestination `
        -Target $configSource | Out-Null

    Write-Host "[OK] Nushell config.nu verlinkt." `
        -ForegroundColor Green

    # ------------------------------------------------------------
    # env.nu
    # ------------------------------------------------------------

    if (Get-Item -LiteralPath $envDestination -Force -ErrorAction SilentlyContinue) {
        Remove-Item `
            -LiteralPath $envDestination `
            -Force
    }

    New-Item `
        -ItemType SymbolicLink `
        -Path $envDestination `
        -Target $envSource | Out-Null

    Write-Host "[OK] Nushell env.nu verlinkt." `
        -ForegroundColor Green
}
