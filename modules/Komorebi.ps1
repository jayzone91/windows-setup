function Set-KomorebiConfiguration {
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " komorebi"
    Write-Host "========================================"

    $configurationChanged = $false

    Write-Host "[INFO] komorebi kann für persönliche Nutzung verwendet werden."
    Write-Host (
        "[INFO] Für die Nutzung am Arbeitsplatz ist laut komorebi " +
        "eine Commercial-Use-Lizenz erforderlich."
    )
    Write-Host (
        "[INFO] Lizenzinformationen: " +
        "https://lgug2z.com/software/komorebi"
    )
    Write-Host (
        "[INFO] Eine vorhandene Lizenz kann mit " +
        "'komorebic license <email>' registriert werden."
    )

    $komorebic = Get-Command `
        -Name "komorebic" `
        -ErrorAction SilentlyContinue

    if (-not $komorebic) {
        throw "komorebic wurde nicht gefunden."
    }

    $whkd = Get-Command `
        -Name "whkd" `
        -ErrorAction SilentlyContinue

    if (-not $whkd) {
        throw "whkd wurde nicht gefunden."
    }

    Write-Host (
        "[FOUND] komorebi: {0}" -f
        $komorebic.Source
    )

    Write-Host (
        "[FOUND] whkd: {0}" -f
        $whkd.Source
    )

    $userConfigDirectory = Join-Path `
        $env:USERPROFILE `
        ".config"

    if (-not (Test-Path -LiteralPath $userConfigDirectory -PathType Container)) {
        New-Item `
            -ItemType Directory `
            -Path $userConfigDirectory `
            -Force |
        Out-Null

        Write-Host "[CREATE] $userConfigDirectory"
        $configurationChanged = $true
    }

    $repositoryConfigDirectory = Join-Path `
        $RepositoryPath `
        "dotfiles\komorebi"

    if (-not (Test-Path -LiteralPath $repositoryConfigDirectory -PathType Container)) {
        Write-Host (
            "[SKIP] komorebi-Konfiguration ist noch nicht im Repository."
        )

        return $configurationChanged
    }

    $links = @(
        @{
            Name   = "komorebi.json"
            Source = Join-Path $repositoryConfigDirectory "komorebi.json"
            Target = Join-Path $env:USERPROFILE "komorebi.json"
        },
        @{
            Name   = "komorebi.bar.json"
            Source = Join-Path $repositoryConfigDirectory "komorebi.bar.json"
            Target = Join-Path $env:USERPROFILE "komorebi.bar.json"
        },
        @{
            Name   = "applications.json"
            Source = Join-Path $repositoryConfigDirectory "applications.json"
            Target = Join-Path $env:USERPROFILE "applications.json"
        },
        @{
            Name   = "whkdrc"
            Source = Join-Path $repositoryConfigDirectory "whkdrc"
            Target = Join-Path $userConfigDirectory "whkdrc"
        }
    )

    Write-Host ""
    Write-Host "[CONFIG] komorebi Hardlinks"

    foreach ($link in $links) {
        if (-not (Test-Path -LiteralPath $link.Source -PathType Leaf)) {
            Write-Host (
                "[SKIP] {0} noch nicht im Repository vorhanden." -f
                $link.Name
            )

            continue
        }

        if (
            -not (
                Test-FileHardLinkTarget `
                    -Path $link.Target `
                    -Target $link.Source
            )
        ) {
            $configurationChanged = $true
        }

        Set-FileHardLink `
            -Path $link.Target `
            -Target $link.Source `
            -ReplaceExistingFile
    }

    Write-Host "[OK] komorebi-Konfiguration vorbereitet." `
        -ForegroundColor Green

    return $configurationChanged
}
