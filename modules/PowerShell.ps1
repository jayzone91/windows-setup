function Set-PowerShellPreferences {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " PowerShell 7"
    Write-Host "========================================"

    $profileSource = Join-Path `
        $PSScriptRoot `
        "..\dotfiles\powershell\Microsoft.PowerShell_profile.ps1"

    $starshipSource = Join-Path `
        $PSScriptRoot `
        "..\dotfiles\starship\starship.toml"

    $pwshDocuments = Join-Path `
        $HOME `
        "Documents\PowerShell"

    $profileDestination = Join-Path `
        $pwshDocuments `
        "Microsoft.PowerShell_profile.ps1"

    $starshipDirectory = Join-Path `
        $HOME `
        ".config"

    $starshipDestination = Join-Path `
        $starshipDirectory `
        "starship.toml"

    foreach ($directory in @(
            $pwshDocuments,
            $starshipDirectory
        )) {
        if (-not (Test-Path $directory)) {
            New-Item `
                -Path $directory `
                -ItemType Directory `
                -Force | Out-Null
        }
    }

    if (-not (Test-Path $profileSource)) {
        throw "PowerShell-Profil nicht gefunden: $profileSource"
    }

    if (-not (Test-Path $starshipSource)) {
        throw "Starship-Konfiguration nicht gefunden: $starshipSource"
    }

    # ------------------------------------------------------------
    # PowerShell Profil verlinken
    # ------------------------------------------------------------

    if (Test-Path $profileDestination) {
        Remove-Item `
            -Path $profileDestination `
            -Force
    }

    New-Item `
        -ItemType SymbolicLink `
        -Path $profileDestination `
        -Target $profileSource | Out-Null

    Write-Host "[OK] PowerShell-Profil verlinkt." `
        -ForegroundColor Green

    # ------------------------------------------------------------
    # Starship config verlinken
    # ------------------------------------------------------------

    if (Test-Path $starshipDestination) {
        Remove-Item `
            -Path $starshipDestination `
            -Force
    }

    New-Item `
        -ItemType SymbolicLink `
        -Path $starshipDestination `
        -Target $starshipSource | Out-Null

    Write-Host "[OK] Starship-Konfiguration verlinkt." `
        -ForegroundColor Green
}
