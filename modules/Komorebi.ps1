function Set-KomorebiConfiguration {
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )


    Write-Host ""
    Write-Host "========================================"
    Write-Host " komorebi"
    Write-Host "========================================"


    #
    # Lizenzhinweis
    #

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


    #
    # Installation prüfen
    #

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
        "[FOUND] komorebi: {0}" `
            -f $komorebic.Source
    )

    Write-Host (
        "[FOUND] whkd: {0}" `
            -f $whkd.Source
    )


    #
    # Config-Verzeichnis für whkd
    #

    $userConfigDirectory = Join-Path `
        $env:USERPROFILE `
        ".config"

    if (-not (Test-Path $userConfigDirectory)) {

        New-Item `
            -ItemType Directory `
            -Path $userConfigDirectory `
            -Force |
        Out-Null


        Write-Host "[CREATE] $userConfigDirectory"
    }


    #
    # Repo-Konfiguration
    #

    $repositoryConfigDirectory = Join-Path `
        $RepositoryPath `
        "dotfiles\komorebi"


    if (-not (Test-Path $repositoryConfigDirectory)) {

        Write-Host (
            "[SKIP] komorebi-Konfiguration ist noch nicht im Repository."
        )

        Write-Host (
            "[INFO] Symlinks werden eingerichtet, sobald " +
            "dotfiles\komorebi vorhanden ist."
        )

        return
    }


    $links = @(

        @{
            Name   = "komorebi.json"
            Source = Join-Path `
                $repositoryConfigDirectory `
                "komorebi.json"
            Target = Join-Path `
                $env:USERPROFILE `
                "komorebi.json"
        },

        @{
            Name   = "komorebi.bar.json"
            Source = Join-Path `
                $repositoryConfigDirectory `
                "komorebi.bar.json"
            Target = Join-Path `
                $env:USERPROFILE `
                "komorebi.bar.json"
        },

        @{
            Name   = "applications.json"
            Source = Join-Path `
                $repositoryConfigDirectory `
                "applications.json"
            Target = Join-Path `
                $env:USERPROFILE `
                "applications.json"
        },

        @{
            Name   = "whkdrc"
            Source = Join-Path `
                $repositoryConfigDirectory `
                "whkdrc"
            Target = Join-Path `
                $userConfigDirectory `
                "whkdrc"
        }

    )


    Write-Host ""
    Write-Host "[CONFIG] komorebi Symlinks"


    foreach ($link in $links) {

        if (-not (Test-Path $link.Source)) {

            Write-Host (
                "[SKIP] {0} noch nicht im Repository vorhanden." `
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
                "[REMOVE] Bestehende Datei: {0}" `
                    -f $link.Target
            )


            Remove-Item `
                -Path $link.Target `
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


    Write-Host "[OK] komorebi-Konfiguration vorbereitet." `
        -ForegroundColor Green
}
