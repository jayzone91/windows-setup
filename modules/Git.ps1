function Set-GitPreferences {

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Git"
    Write-Host "========================================"


    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "Git ist nicht installiert."
    }


    git --version


    #
    # Benutzerinformationen
    #

    $gitName = git config --global user.name
    $gitEmail = git config --global user.email


    if ([string]::IsNullOrWhiteSpace($gitName)) {

        $gitName = Read-WindowsSetupPrompt `
            -Prompt "Git Benutzername"

        if (-not [string]::IsNullOrWhiteSpace($gitName)) {

            git config --global user.name $gitName

            Write-Host "[OK] Git Benutzername gesetzt."
        }
    }
    else {
        Write-Host "[OK] Git Benutzername vorhanden: $gitName"
    }


    if ([string]::IsNullOrWhiteSpace($gitEmail)) {

        do {
            $gitEmail = Read-WindowsSetupPrompt `
                -Prompt "Git E-Mail"

            if ($gitEmail -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
                Write-Warning "Ungültige E-Mail-Adresse."
                $gitEmail = $null
            }

        } while ([string]::IsNullOrWhiteSpace($gitEmail))

        if (-not [string]::IsNullOrWhiteSpace($gitEmail)) {

            git config --global user.email $gitEmail

            Write-Host "[OK] Git E-Mail gesetzt."
        }
    }
    else {
        Write-Host "[OK] Git E-Mail vorhanden: $gitEmail"
    }



    #
    # Globale Gitignore
    #

    $ignoreSource = Join-Path `
        $PSScriptRoot `
        "..\dotfiles\git\.gitignore_global"


    $ignoreDestination = Join-Path `
        $HOME `
        ".gitignore_global"



    if (-not (Test-Path $ignoreSource)) {
        throw "Gitignore nicht gefunden: $ignoreSource"
    }


    Copy-Item `
        -Path $ignoreSource `
        -Destination $ignoreDestination `
        -Force


    git config --global core.excludesfile $ignoreDestination



    #
    # Standard Einstellungen
    #

    git config --global core.editor "code --wait"

    git config --global core.autocrlf false

    git config --global core.safecrlf warn

    git config --global init.defaultBranch main

    git config --global pull.rebase true

    git config --global fetch.prune true

    git config --global push.autoSetupRemote true

    git config --global credential.helper manager

    git config --global rerere.enabled true


    if (Get-Command git-lfs -ErrorAction SilentlyContinue) {
        git lfs install
        Write-Host "[OK] Git LFS aktiviert."
    }

    git config --global credential.helper manager

    Write-Host ""
    Write-Host "[OK] Git Konfiguration abgeschlossen." `
        -ForegroundColor Green


    Write-Host ""
    Write-Host "Aktuelle Konfiguration:"
    git config --global --list
}

function Get-WindowsSetupRepositoryStatus {

    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )


    $result = [PSCustomObject]@{
        HasChanges      = $false
        ChangedFiles    = @()
        UnpushedCommits = 0
    }


    $gitDirectory = Join-Path `
        $RepositoryPath `
        ".git"


    if (-not (Test-Path $gitDirectory)) {
        return $result
    }


    $statusLines = @(
        git `
            -C $RepositoryPath `
            status `
            --porcelain
    )


    if ($LASTEXITCODE -eq 0) {

        $result.HasChanges =
        $statusLines.Count -gt 0


        $result.ChangedFiles = @(
            foreach ($line in $statusLines) {

                if ($line.Length -gt 3) {
                    $line.Substring(3).Trim()
                }
            }
        )
    }


    $upstream = git `
        -C $RepositoryPath `
        rev-parse `
        --abbrev-ref `
        --symbolic-full-name `
        "@{u}" `
        2>$null


    if (
        $LASTEXITCODE -eq 0 -and
        -not [string]::IsNullOrWhiteSpace($upstream)
    ) {

        $count = git `
            -C $RepositoryPath `
            rev-list `
            --count `
            "$upstream..HEAD"


        if ($LASTEXITCODE -eq 0) {
            $result.UnpushedCommits = [int]$count
        }
    }


    return $result
}
