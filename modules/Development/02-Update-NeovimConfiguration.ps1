function Update-NeovimConfiguration {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingPositionalParameters",
        "",
        Justification = "Git ist ein natives CLI-Programm; die verwendeten Argumente folgen der regulären Git-Syntax."
    )]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Neovim Configuration"
    Write-Host "========================================"

    $script:NeovimStashIssue = $null

    $submodulePath = Join-Path $RepositoryPath "external\nvim"
    $gitModulesPath = Join-Path $RepositoryPath ".gitmodules"

    if (-not (Test-Path -LiteralPath $gitModulesPath -PathType Leaf)) {
        throw "Submodule-Konfiguration fehlt: $gitModulesPath"
    }

    & git -C $RepositoryPath submodule sync -- external/nvim

    if ($LASTEXITCODE -ne 0) {
        throw "Neovim-Submodule-URL konnte nicht synchronisiert werden."
    }

    $isInitialized = $false

    if (Test-Path -LiteralPath $submodulePath -PathType Container) {
        $insideWorkTree = (
            @(
                & git -C $submodulePath `
                    rev-parse `
                    --is-inside-work-tree 2>$null
            ) -join "`n"
        ).Trim()

        $isInitialized = (
            $LASTEXITCODE -eq 0 -and
            $insideWorkTree -eq "true"
        )
    }

    if (-not $isInitialized) {
        & git -C $RepositoryPath `
            submodule update `
            --init `
            -- external/nvim

        if ($LASTEXITCODE -ne 0) {
            throw "Neovim-Submodule konnte nicht initialisiert werden."
        }
    }
    else {
        Write-Host "[OK] Neovim-Submodule ist bereits initialisiert."
    }

    if (-not (Test-GitHubAvailability)) {
        if ($isInitialized) {
            Write-Warning (
                "GitHub nicht erreichbar. Neovim-Remote-Update wird übersprungen; " +
                "der vorhandene lokale Stand wird weiterverwendet."
            )

            $nvimConfigPath = Join-Path $env:LOCALAPPDATA "nvim"

            Set-DirectoryJunction `
                -Path $nvimConfigPath `
                -Target $submodulePath

            return
        }

        Write-Warning (
            "GitHub nicht erreichbar und Neovim-Submodule noch nicht initialisiert. " +
            "Neovim-Konfigurationsschritt wird übersprungen."
        )

        return
    }

    $originalHead = (
        @(
            & git -C $submodulePath rev-parse HEAD
        ) -join "`n"
    ).Trim()

    if ($LASTEXITCODE -ne 0 -or -not $originalHead) {
        throw "Aktueller Neovim-Commit konnte nicht ermittelt werden."
    }

    $originalBranch = (
        @(
            & git -C $submodulePath branch --show-current
        ) -join "`n"
    ).Trim()

    Write-Host "[CHECK] Neovim origin/main"

    $gitFetchOutput = @(
        & git -C $submodulePath fetch origin main 2>&1
    )

    if ($LASTEXITCODE -ne 0) {
        $message = "Neovim-Fetch fehlgeschlagen."

        if ($gitFetchOutput.Count -gt 0) {
            $message += " {0}" -f ($gitFetchOutput -join " ")
        }

        Write-Warning (
            $message +
            " Der vorhandene lokale Stand wird weiterverwendet."
        )

        $nvimConfigPath = Join-Path $env:LOCALAPPDATA "nvim"

        Set-DirectoryJunction `
            -Path $nvimConfigPath `
            -Target $submodulePath

        return
    }

    if ($script:WindowsSetupOutputMode -eq "Log") {
        foreach ($line in $gitFetchOutput) {
            Write-Host $line
        }
    }

    $remoteHead = (
        @(
            & git -C $submodulePath rev-parse origin/main
        ) -join "`n"
    ).Trim()

    if ($LASTEXITCODE -ne 0 -or -not $remoteHead) {
        throw "Neovim origin/main konnte nicht ermittelt werden."
    }

    if ($originalHead -eq $remoteHead) {
        Write-Host (
            "[CURRENT] Neovim ist bereits aktuell: {0}" -f
            $originalHead.Substring(0, [Math]::Min(12, $originalHead.Length))
        ) -ForegroundColor Green

        $nvimConfigPath = Join-Path $env:LOCALAPPDATA "nvim"

        Set-DirectoryJunction `
            -Path $nvimConfigPath `
            -Target $submodulePath

        return
    }

    & git -C $submodulePath `
        merge-base `
        --is-ancestor `
        $originalHead `
        $remoteHead

    $ancestorExitCode = $LASTEXITCODE

    if ($ancestorExitCode -eq 1) {
        throw (
            "Neovim kann nicht per Fast-Forward aktualisiert werden. " +
            "Lokaler HEAD und origin/main sind divergiert oder der lokale " +
            "HEAD ist neuer. Automatisches Zurücksetzen wird verweigert."
        )
    }

    if ($ancestorExitCode -ne 0) {
        throw "Neovim-Fast-Forward-Prüfung ist fehlgeschlagen."
    }

    Write-Host (
        "[UPDATE] Neovim: {0} -> {1}" -f
        $originalHead.Substring(0, [Math]::Min(12, $originalHead.Length)),
        $remoteHead.Substring(0, [Math]::Min(12, $remoteHead.Length))
    ) -ForegroundColor Cyan

    $originalStatus = @(
        & git -C $submodulePath `
            status `
            --porcelain `
            --untracked-files=all
    )

    if ($LASTEXITCODE -ne 0) {
        throw "Git-Status des Neovim-Submodules konnte nicht ermittelt werden."
    }

    $stashCreated = $false
    $stashRef = $null
    $stashCommit = $null
    $stashMessage = $null

    if ($originalStatus.Count -gt 0) {
        $stashMessage = (
            "windows-setup bootstrap {0}" `
                -f (Get-Date -Format "yyyy-MM-ddTHH:mm:ssK")
        )

        Write-Host (
            "[STASH] Neovim enthält lokale Änderungen. " +
            "Sie werden nur für das anstehende Update gesichert."
        ) -ForegroundColor Yellow

        & git -C $submodulePath `
            stash push `
            --include-untracked `
            --message $stashMessage

        if ($LASTEXITCODE -ne 0) {
            throw "Lokale Neovim-Änderungen konnten nicht gestashed werden."
        }

        $stashCommit = (
            @(
                & git -C $submodulePath rev-parse refs/stash
            ) -join "`n"
        ).Trim()

        if ($LASTEXITCODE -ne 0 -or -not $stashCommit) {
            throw "Der erzeugte Neovim-Stash konnte nicht ermittelt werden."
        }

        $stashRef = "stash@{0}"
        $stashCreated = $true

        Write-Host (
            "[OK] Neovim-Änderungen gesichert: {0} ({1})" `
                -f $stashRef, $stashCommit
        ) -ForegroundColor Green
    }

    $updateError = $null

    try {
        & git -C $submodulePath `
            show-ref `
            --verify `
            --quiet `
            refs/heads/main

        $mainBranchExists = $LASTEXITCODE -eq 0

        if ($mainBranchExists) {
            & git -C $submodulePath checkout main
        }
        else {
            & git -C $submodulePath `
                checkout `
                -b main `
                --track origin/main
        }

        if ($LASTEXITCODE -ne 0) {
            throw (
                "Neovim-Submodule konnte nicht auf Branch main " +
                "gewechselt werden."
            )
        }

        & git -C $submodulePath pull --ff-only origin main

        if ($LASTEXITCODE -ne 0) {
            throw (
                "Neovim-Submodule konnte nicht per " +
                "git pull --ff-only aktualisiert werden."
            )
        }

        Write-Host "[OK] Neovim-Submodule aktualisiert." `
            -ForegroundColor Green
    }
    catch {
        $updateError = $_.Exception.Message
    }

    if ($stashCreated) {
        Write-Host (
            "[STASH] Stelle lokale Neovim-Änderungen aus {0} wieder her..." `
                -f $stashRef
        )

        & git -C $submodulePath stash pop --index $stashRef
        $stashRestoreExitCode = $LASTEXITCODE

        if ($stashRestoreExitCode -eq 0) {
            Write-Host (
                "[OK] Lokale Neovim-Änderungen wurden wiederhergestellt."
            ) -ForegroundColor Green
        }
        else {
            $currentHead = (
                @(
                    & git -C $submodulePath rev-parse HEAD 2>$null
                ) -join "`n"
            ).Trim()

            $currentBranch = (
                @(
                    & git -C $submodulePath `
                        branch `
                        --show-current 2>$null
                ) -join "`n"
            ).Trim()

            $stashListEntry = @(
                & git -C $submodulePath `
                    stash list `
                    --format="%gd | %H | %gs"
            ) | Where-Object {
                $_ -match [regex]::Escape($stashCommit)
            } | Select-Object -First 1

            $stashStat = @(
                & git -C $submodulePath `
                    stash show `
                    --stat `
                    $stashRef 2>$null
            )

            $stashFiles = @(
                & git -C $submodulePath `
                    stash show `
                    --name-status `
                    $stashRef 2>$null
            )

            $currentStatus = @(
                & git -C $submodulePath `
                    status `
                    --short `
                    --branch 2>$null
            )

            $script:NeovimStashIssue = [pscustomobject]@{
                SubmodulePath   = $submodulePath
                StashRef        = $stashRef
                StashCommit     = $stashCommit
                StashMessage    = $stashMessage
                StashListEntry  = [string] $stashListEntry
                OriginalHead    = $originalHead
                OriginalBranch  = $originalBranch
                CurrentHead     = $currentHead
                CurrentBranch   = $currentBranch
                OriginalStatus  = @($originalStatus)
                CurrentStatus   = @($currentStatus)
                StashStat       = @($stashStat)
                StashFiles      = @($stashFiles)
                RestoreExitCode = $stashRestoreExitCode
                UpdateError     = $updateError
            }

            Write-Warning (
                "Der Neovim-Stash konnte nicht konfliktfrei " +
                "wiederhergestellt werden. Details folgen am Ende des Bootstrap."
            )
        }
    }

    if ($updateError -and -not $script:NeovimStashIssue) {
        throw $updateError
    }

    $nvimConfigPath = Join-Path $env:LOCALAPPDATA "nvim"

    Set-DirectoryJunction `
        -Path $nvimConfigPath `
        -Target $submodulePath
}

function Test-NeovimRequirements {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Neovim Requirements"
    Write-Host "========================================"

    $nvimCommand = Get-Command nvim -ErrorAction SilentlyContinue
    if (-not $nvimCommand) {
        throw "Neovim wurde nicht gefunden."
    }

    $nvimVersionLine = (& nvim --version | Select-Object -First 1)
    if ($nvimVersionLine -notmatch 'NVIM v(?<version>\d+\.\d+\.\d+)') {
        throw "Neovim-Version konnte nicht ermittelt werden: $nvimVersionLine"
    }

    $nvimVersion = [version] $Matches.version
    if ($nvimVersion -lt [version] '0.12.0') {
        throw "Neovim 0.12.0 oder neuer erforderlich, gefunden: $nvimVersion"
    }

    foreach ($command in @('tar', 'curl', 'tree-sitter', 'zig', 'cc', 'c++')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            throw "Neovim-Anforderung fehlt im PATH: $command"
        }
    }

    $treeSitterVersionLine = (& tree-sitter --version | Select-Object -First 1)
    if ($treeSitterVersionLine -notmatch '(?<version>\d+\.\d+\.\d+)') {
        throw "tree-sitter-cli-Version konnte nicht ermittelt werden: $treeSitterVersionLine"
    }

    $treeSitterVersion = [version] $Matches.version
    if ($treeSitterVersion -lt [version] '0.26.1') {
        throw "tree-sitter-cli 0.26.1 oder neuer erforderlich, gefunden: $treeSitterVersion"
    }

    & cc --version *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Zig C-Compiler über 'cc' konnte nicht ausgeführt werden."
    }

    & c++ --version *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Zig C++-Compiler über 'c++' konnte nicht ausgeführt werden."
    }

    Write-Host (
        (
            "[OK] Neovim-Anforderungen erfüllt: Neovim {0}, " +
            "tree-sitter {1}, Compiler Zig."
        ) -f $nvimVersion, $treeSitterVersion
    ) -ForegroundColor Green
}