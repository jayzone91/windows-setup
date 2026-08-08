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

    $links = @(
        @{
            Name   = "settings.json"
            Source = Join-Path `
                $repositoryConfigDirectory `
                "settings.json"
            Target = Join-Path `
                $userZebarDirectory `
                "settings.json"
        },
        @{
            Name   = "windows-setup-bar"
            Source = Join-Path `
                $repositoryConfigDirectory `
                "windows-setup-bar"
            Target = Join-Path `
                $userZebarDirectory `
                "windows-setup-bar"
        }
    )

    foreach ($link in $links) {

        if (-not (Test-Path $link.Source)) {
            Write-Host (
                "[SKIP] {0} nicht im Repository vorhanden." `
                    -f $link.Name
            )

            continue
        }

        if (Test-Path $link.Target) {

            $targetItem = Get-Item `
                -Path $link.Target `
                -Force

            $isCorrectLink =
            $targetItem.LinkType -eq "SymbolicLink" -and
            $targetItem.Target -eq $link.Source

            if ($isCorrectLink) {
                Write-Host (
                    "[SKIP] {0} bereits korrekt verlinkt." `
                        -f $link.Name
                )

                continue
            }

            Write-Host (
                "[REMOVE] Bestehend: {0}" `
                    -f $link.Target
            )

            Remove-Item `
                -Path $link.Target `
                -Recurse `
                -Force
        }

        New-Item `
            -ItemType SymbolicLink `
            -Path $link.Target `
            -Target $link.Source |
        Out-Null

        Write-Host (
            "[LINK] {0} -> {1}" `
                -f $link.Target, $link.Source
        )
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
