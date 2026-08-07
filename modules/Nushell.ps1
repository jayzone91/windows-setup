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

    # Nushell selbst fragen, wo die Config liegt
    $configDestination = (& nu -c '$nu.config-path').Trim()
    $envDestination = (& nu -c '$nu.env-path').Trim()

    if (-not $configDestination) {
        throw "Nushell config-path konnte nicht ermittelt werden."
    }

    if (-not $envDestination) {
        throw "Nushell env-path konnte nicht ermittelt werden."
    }

    $configDirectory = Split-Path `
        $configDestination `
        -Parent

    if (-not (Test-Path $configDirectory)) {
        New-Item `
            -Path $configDirectory `
            -ItemType Directory `
            -Force | Out-Null
    }

    # ------------------------------------------------------------
    # config.nu
    # ------------------------------------------------------------

    if (Test-Path $configDestination) {
        Remove-Item `
            -Path $configDestination `
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

    if (Test-Path $envDestination) {
        Remove-Item `
            -Path $envDestination `
            -Force
    }

    New-Item `
        -ItemType SymbolicLink `
        -Path $envDestination `
        -Target $envSource | Out-Null

    Write-Host "[OK] Nushell env.nu verlinkt." `
        -ForegroundColor Green
}
