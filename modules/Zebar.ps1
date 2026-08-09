function Set-ZebarConfiguration {
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Zebar"
    Write-Host "========================================"

    $zebar = Get-Command `
        -Name "zebar" `
        -ErrorAction SilentlyContinue

    if (-not $zebar) {
        throw "zebar wurde nicht gefunden."
    }

    Write-Host (
        "[FOUND] Zebar: {0}" `
            -f $zebar.Source
    )

    $repositoryConfigDirectory = Join-Path `
        $RepositoryPath `
        "dotfiles\zebar"

    if (-not (Test-Path $repositoryConfigDirectory)) {
        Write-Host "[SKIP] Zebar-Konfiguration noch nicht im Repository."
        return
    }

    $userZebarDirectory = Join-Path `
        $env:USERPROFILE `
        ".glzr\zebar"

    if (-not (Test-Path $userZebarDirectory)) {
        New-Item `
            -ItemType Directory `
            -Path $userZebarDirectory `
            -Force |
        Out-Null

        Write-Host "[CREATE] $userZebarDirectory"
    }

    $settingsSource = Join-Path `
        $repositoryConfigDirectory `
        "settings.json"

    $settingsTarget = Join-Path `
        $userZebarDirectory `
        "settings.json"

    $widgetSource = Join-Path `
        $repositoryConfigDirectory `
        "windows-setup-bar"

    $widgetTarget = Join-Path `
        $userZebarDirectory `
        "windows-setup-bar"

    if (Test-Path $settingsSource) {
        Set-FileHardLink `
            -Path $settingsTarget `
            -Target $settingsSource `
            -ReplaceExistingFile
    }
    else {
        Write-Host "[SKIP] Zebar settings.json nicht im Repository vorhanden."
    }

    if (Test-Path $widgetSource) {
        Set-DirectoryJunction `
            -Path $widgetTarget `
            -Target $widgetSource
    }
    else {
        Write-Host "[SKIP] Zebar Widget-Verzeichnis nicht im Repository vorhanden."
    }

    $zebarProjectDirectory = Join-Path `
        $repositoryConfigDirectory `
        "windows-setup-bar"

    $packageJson = Join-Path `
        $zebarProjectDirectory `
        "package.json"

    if (-not (Test-Path $packageJson)) {
        throw "Zebar package.json wurde nicht gefunden: $packageJson"
    }

    $npmPath =
    Get-NpmExecutable

    Write-Host (
        "[FOUND] npm: {0}" `
            -f $npmPath
    )


    Write-Host ""
    Write-Host "[INFO] Installiere Zebar-Abhängigkeiten."

    Push-Location $zebarProjectDirectory

    try {
        & $npmPath ci

        if ($LASTEXITCODE -ne 0) {
            throw (
                "npm ci für Zebar ist fehlgeschlagen. " +
                "Exit-Code: $LASTEXITCODE"
            )
        }

        Write-Host "[OK] Zebar-Abhängigkeiten installiert." `
            -ForegroundColor Green

        Write-Host "[INFO] Erstelle Zebar-Bundle."

        & $npmPath run build

        if ($LASTEXITCODE -ne 0) {
            throw (
                "Zebar-Build ist fehlgeschlagen. " +
                "Exit-Code: $LASTEXITCODE"
            )
        }

        Write-Host "[OK] Zebar-Bundle erstellt." `
            -ForegroundColor Green
    }
    finally {
        Pop-Location
    }

    Write-Host "[OK] Zebar-Konfiguration vorbereitet." `
        -ForegroundColor Green
}


function Get-NpmExecutable {

    $command = Get-Command `
        -Name "npm.cmd" `
        -ErrorAction SilentlyContinue

    if ($command) {
        return $command.Source
    }


    $command = Get-Command `
        -Name "npm" `
        -ErrorAction SilentlyContinue

    if ($command) {
        return $command.Source
    }


    $candidatePaths = @(
        (Join-Path $env:ProgramFiles "nodejs\npm.cmd"),
        (Join-Path $env:APPDATA "npm\npm.cmd")
    )


    foreach ($candidatePath in $candidatePaths) {

        if (Test-Path $candidatePath) {
            return $candidatePath
        }
    }


    throw (
        "npm wurde nicht gefunden. " +
        "Node.js/npm muss vor der Zebar-Konfiguration installiert sein."
    )
}
