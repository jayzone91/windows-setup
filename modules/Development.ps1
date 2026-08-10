function Install-CodexCli {

    Write-Host ""
    Write-Host "========================================"
    Write-Host " OpenAI Codex CLI"
    Write-Host "========================================"


    if (Get-Command codex -ErrorAction SilentlyContinue) {

        Write-Host "[OK] Codex CLI bereits installiert."

        return
    }


    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {

        Write-Warning `
            "npm wurde nicht gefunden. Codex CLI kann nicht installiert werden."

        return
    }


    Write-Host "[INSTALL] @openai/codex"

    npm install -g @openai/codex

    if ($LASTEXITCODE -ne 0) {
        throw "Codex CLI konnte nicht installiert werden."
    }

    if (Get-Command codex -ErrorAction SilentlyContinue) {

        Write-Host "[OK] Codex CLI installiert."

    }
    else {

        Write-Warning `
            "Codex CLI wurde installiert, aber ist nicht verfügbar."

    }

}


$script:NeovimStashIssue = $null


function Set-NeovimCompilerEnvironment {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Neovim Compiler Environment"
    Write-Host "========================================"

    $zigCommand = Get-Command zig -ErrorAction SilentlyContinue

    if (-not $zigCommand) {
        throw "Zig wurde nicht gefunden."
    }

    $scoopCommand = Get-Command scoop -ErrorAction SilentlyContinue

    if (-not $scoopCommand) {
        throw "Scoop wurde nicht gefunden."
    }

    # Tree-sitter verwendet den Compiler aus CC. Ohne explizite Auswahl
    # fällt der Windows-Buildpfad auf cl.exe zurück. Die Scoop-Shims stellen
    # deshalb echte cc/c++-Kommandos bereit, die Zig verwenden.
    $compilerShims = @(
        @{
            Name      = "cc"
            Arguments = @("cc")
        },
        @{
            Name      = "c++"
            Arguments = @("c++")
        }
    )

    foreach ($shim in $compilerShims) {
        $existingCommand = Get-Command `
            -Name $shim.Name `
            -CommandType Application `
            -ErrorAction SilentlyContinue

        $scoopShimRoot = Join-Path `
            ([Environment]::GetFolderPath("UserProfile")) `
            "scoop\shims"

        $isScoopShim = (
            $existingCommand -and
            $existingCommand.Source.StartsWith(
                $scoopShimRoot,
                [System.StringComparison]::OrdinalIgnoreCase
            )
        )

        if ($existingCommand -and -not $isScoopShim) {
            throw (
                "Compiler-Kommando '{0}' existiert bereits außerhalb der " +
                "Scoop-Shims: {1}. Automatische Überschreibung wird verweigert."
            ) -f $shim.Name, $existingCommand.Source
        }

        if ($isScoopShim) {
            $removeShimArguments = @(
                "shim",
                "rm",
                $shim.Name
            )

            & $scoopCommand.Path @removeShimArguments

            if ($LASTEXITCODE -ne 0) {
                throw (
                    "Bestehender Scoop-Shim '{0}' konnte nicht entfernt werden."
                ) -f $shim.Name
            }
        }

        $addShimArguments = @(
            "shim",
            "add",
            $shim.Name,
            $zigCommand.Source
        ) + @($shim.Arguments)

        & $scoopCommand.Path @addShimArguments

        if ($LASTEXITCODE -ne 0) {
            throw (
                "Scoop-Shim '{0}' für Zig konnte nicht erstellt werden."
            ) -f $shim.Name
        }
    }

    $compilerEnvironment = [ordered]@{
        CC                   = "cc"
        CXX                  = "c++"
        CRATE_CC_NO_DEFAULTS = "1"
    }

    foreach ($entry in $compilerEnvironment.GetEnumerator()) {
        $currentUserValue = [Environment]::GetEnvironmentVariable(
            $entry.Key,
            "User"
        )

        if ($currentUserValue -ne $entry.Value) {
            [Environment]::SetEnvironmentVariable(
                $entry.Key,
                $entry.Value,
                "User"
            )

            Write-Host (
                "[CONFIG] Benutzer-Umgebungsvariable {0} = {1}" `
                    -f $entry.Key, $entry.Value
            )
        }

        Set-Item `
            -Path ("Env:{0}" -f $entry.Key) `
            -Value $entry.Value
    }

    # Frühere Wrapper-Erkennung wird nicht mehr benötigt, weil CC jetzt
    # direkt auf das echte ausführbare Kommando 'cc' zeigt.
    [Environment]::SetEnvironmentVariable(
        "CC_KNOWN_WRAPPER_CUSTOM",
        $null,
        "User"
    )

    Remove-Item `
        -Path "Env:CC_KNOWN_WRAPPER_CUSTOM" `
        -ErrorAction SilentlyContinue

    $ccCommand = Get-Command `
        -Name "cc" `
        -CommandType Application `
        -ErrorAction SilentlyContinue

    $cxxCommand = Get-Command `
        -Name "c++" `
        -CommandType Application `
        -ErrorAction SilentlyContinue

    if (-not $ccCommand) {
        throw "Der Compiler-Shim 'cc' ist nicht verfügbar."
    }

    if (-not $cxxCommand) {
        throw "Der Compiler-Shim 'c++' ist nicht verfügbar."
    }

    & cc --version *> $null

    if ($LASTEXITCODE -ne 0) {
        throw "Der Zig-C-Compiler über 'cc' konnte nicht ausgeführt werden."
    }

    & c++ --version *> $null

    if ($LASTEXITCODE -ne 0) {
        throw "Der Zig-C++-Compiler über 'c++' konnte nicht ausgeführt werden."
    }

    Write-Host (
        "[OK] Zig-Compiler konfiguriert: CC=cc, CXX=c++."
    ) -ForegroundColor Green
}

function Update-NeovimConfiguration {
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
            "Sie werden vor dem Update gesichert."
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
        & git -C $submodulePath fetch origin main

        if ($LASTEXITCODE -ne 0) {
            throw "Neovim-Submodule konnte origin/main nicht abrufen."
        }

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


function Show-NeovimMaintenanceStatus {
    if (-not $script:NeovimStashIssue) {
        return
    }

    $issue = $script:NeovimStashIssue

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host " Neovim Stash benötigt Aufmerksamkeit" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""

    Write-Warning (
        "Lokale Neovim-Änderungen konnten nach dem automatischen " +
        "Update nicht konfliktfrei wiederhergestellt werden."
    )

    Write-Host ""
    Write-Host "[STASH]"
    Write-Host ("  Repository:       {0}" -f $issue.SubmodulePath)
    Write-Host ("  Referenz:         {0}" -f $issue.StashRef)
    Write-Host ("  Commit:           {0}" -f $issue.StashCommit)
    Write-Host ("  Nachricht:        {0}" -f $issue.StashMessage)
    Write-Host ("  Restore ExitCode: {0}" -f $issue.RestoreExitCode)
    Write-Host ("  Ursprungs-Branch: {0}" -f $issue.OriginalBranch)
    Write-Host ("  Ursprungs-HEAD:   {0}" -f $issue.OriginalHead)
    Write-Host ("  Aktueller Branch: {0}" -f $issue.CurrentBranch)
    Write-Host ("  Aktueller HEAD:   {0}" -f $issue.CurrentHead)

    if ($issue.StashListEntry) {
        Write-Host ("  Stash-Liste:      {0}" -f $issue.StashListEntry)
    }

    if ($issue.UpdateError) {
        Write-Host ""
        Write-Host ("[UPDATE-FEHLER] {0}" -f $issue.UpdateError) `
            -ForegroundColor Red
    }

    if ($issue.OriginalStatus.Count -gt 0) {
        Write-Host ""
        Write-Host "[LOKALE ÄNDERUNGEN VOR DEM STASH]"
        foreach ($line in $issue.OriginalStatus) {
            Write-Host ("  {0}" -f $line)
        }
    }

    if ($issue.StashFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "[DATEIEN IM STASH]"
        foreach ($line in $issue.StashFiles) {
            Write-Host ("  {0}" -f $line)
        }
    }

    if ($issue.StashStat.Count -gt 0) {
        Write-Host ""
        Write-Host "[STASH STAT]"
        foreach ($line in $issue.StashStat) {
            Write-Host ("  {0}" -f $line)
        }
    }

    if ($issue.CurrentStatus.Count -gt 0) {
        Write-Host ""
        Write-Host "[AKTUELLER GIT-STATUS]"
        foreach ($line in $issue.CurrentStatus) {
            Write-Host ("  {0}" -f $line)
        }
    }

    Write-Host ""
    Write-Host "[WICHTIG]" -ForegroundColor Yellow
    Write-Host (
        "Das fehlgeschlagene 'stash pop' kann Teile der Änderungen " +
        "bereits in den Working Tree übernommen haben."
    )
    Write-Host (
        "Den Stash daher NICHT blind erneut anwenden. Zuerst Konflikte " +
        "und den aktuellen Git-Status prüfen."
    )

    Write-Host ""
    Write-Host "[DIAGNOSE-BEFEHLE]"
    Write-Host (
        '  git -C "{0}" status' `
            -f $issue.SubmodulePath
    )
    Write-Host (
        '  git -C "{0}" stash list' `
            -f $issue.SubmodulePath
    )
    Write-Host (
        '  git -C "{0}" stash show --stat "{1}"' `
            -f $issue.SubmodulePath, $issue.StashRef
    )
    Write-Host (
        '  git -C "{0}" stash show -p "{1}"' `
            -f $issue.SubmodulePath, $issue.StashRef
    )

    Write-Host ""
    Write-Host (
        "Wenn alle Konflikte aufgelöst und die lokalen Änderungen " +
        "vollständig geprüft wurden, kann der erhaltene Stash manuell " +
        "gelöscht werden:"
    )
    Write-Host (
        '  git -C "{0}" stash drop "{1}"' `
            -f $issue.SubmodulePath, $issue.StashRef
    )
}
