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
                -Force |
            Out-Null
        }
    }

    if (-not (Test-Path $profileSource)) {
        throw "PowerShell-Profil nicht gefunden: $profileSource"
    }

    if (-not (Test-Path $starshipSource)) {
        throw "Starship-Konfiguration nicht gefunden: $starshipSource"
    }

    Set-FileHardLink `
        -Path $profileDestination `
        -Target $profileSource `
        -ReplaceExistingFile

    Set-FileHardLink `
        -Path $starshipDestination `
        -Target $starshipSource `
        -ReplaceExistingFile

    Write-Host "[OK] PowerShell- und Starship-Konfiguration verlinkt." `
        -ForegroundColor Green
}


function Install-PowerShellModules {

    param(
        [Parameter(Mandatory)]
        [string[]] $Modules
    )


    Write-Host ""
    Write-Host "========================================"
    Write-Host " PowerShell Module"
    Write-Host "========================================"


    foreach ($module in $Modules) {

        $installedModule = Get-Module `
            -ListAvailable `
            -Name $module |
        Sort-Object Version -Descending |
        Select-Object -First 1


        if ($installedModule) {

            Write-Host (
                "[SKIP] {0} bereits installiert ({1})." `
                    -f $module, $installedModule.Version
            )

            continue
        }


        Write-Host "[INSTALL] $module"


        Install-Module `
            -Name $module `
            -Scope CurrentUser `
            -Repository PSGallery `
            -Force `
            -AllowClobber


        Write-Host (
            "[OK] {0} installiert." `
                -f $module
        ) `
            -ForegroundColor Green
    }
}


function Test-PowerShellCode {

    param(
        [Parameter(Mandatory)]
        [string] $Path
    )


    Write-Host ""
    Write-Host "========================================"
    Write-Host " PowerShell Code Check"
    Write-Host "========================================"


    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {

        Write-Warning (
            "PSScriptAnalyzer ist nicht installiert. " +
            "Code-Prüfung wird übersprungen."
        )

        return
    }


    Import-Module `
        PSScriptAnalyzer `
        -ErrorAction Stop


    $settingsPath = Join-Path `
        $Path `
        "PSScriptAnalyzerSettings.psd1"


    $issues = @(
        Invoke-ScriptAnalyzer `
            -Path $Path `
            -Recurse `
            -Settings $settingsPath
    )


    if ($issues.Count -eq 0) {

        Write-Host "[OK] Keine PSScriptAnalyzer-Probleme gefunden." `
            -ForegroundColor Green

        return
    }


    $errors = @(
        $issues |
        Where-Object Severity -eq "Error"
    )


    $warnings = @(
        $issues |
        Where-Object Severity -eq "Warning"
    )


    $information = @(
        $issues |
        Where-Object Severity -eq "Information"
    )


    Write-Host (
        "[INFO] {0} Fehler, {1} Warnungen, {2} Hinweise gefunden." `
            -f `
            $errors.Count,
        $warnings.Count,
        $information.Count
    )


    $issues |
    Select-Object `
        Severity,
    RuleName,
    ScriptName,
    Line,
    Message |
    Format-Table `
        -AutoSize


    if ($errors.Count -gt 0) {
        Write-Warning "PSScriptAnalyzer hat Fehler gefunden."
    }
}
