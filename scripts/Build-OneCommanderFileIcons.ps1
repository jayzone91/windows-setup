function Build-OneCommanderFileIcons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath,

        [string] $UpstreamRef = "b6915da9f6889b683a110aa747de96c2820a537d"
    )

    $generatedRoot = Join-Path `
        $RepositoryPath `
        ".generated\onecommander"

    $sourceRoot = Join-Path `
        $generatedRoot `
        "Sources\vscode-icons"

    $renderedRoot = Join-Path `
        $generatedRoot `
        "Rendered\CatppuccinMocha"

    $fileIconsRoot = Join-Path `
        $generatedRoot `
        "FileIcons\CatppuccinMocha"


    $generatorRoot = Join-Path `
        $RepositoryPath `
        "scripts\onecommander-file-icons"

    $generatorScript = Join-Path `
        $generatorRoot `
        "build-file-icons.mjs"

    $generatorPackage = Join-Path `
        $generatorRoot `
        "package.json"

    if (-not (Test-Path $generatorScript)) {
        throw "OneCommander File-Icon-Generator fehlt: $generatorScript"
    }

    if (-not (Test-Path $generatorPackage)) {
        throw "package.json für den File-Icon-Generator fehlt: $generatorPackage"
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "git wurde nicht gefunden."
    }

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        throw "Node.js wurde nicht gefunden."
    }

    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        throw "npm wurde nicht gefunden."
    }

    New-Item `
        -ItemType Directory `
        -Path (Split-Path -Path $sourceRoot -Parent) `
        -Force |
    Out-Null

    #
    # Catppuccin vscode-icons als getrennte Upstream-Quelle verwalten.
    #
    if (-not (Test-Path (Join-Path $sourceRoot ".git"))) {
        Write-Host "[INSTALL] Klone catppuccin/vscode-icons."

        git clone `
            --no-checkout `
            --filter=blob:none `
            "https://github.com/catppuccin/vscode-icons.git" `
            $sourceRoot

        if ($LASTEXITCODE -ne 0) {
            throw "catppuccin/vscode-icons konnte nicht geklont werden."
        }
    }

    Push-Location $sourceRoot

    try {
        Write-Host "[INFO] Lade gepinnten vscode-icons-Stand: $UpstreamRef"

        git fetch `
            origin `
            $UpstreamRef `
            --depth 1

        if ($LASTEXITCODE -ne 0) {
            throw "vscode-icons Ref '$UpstreamRef' konnte nicht geladen werden."
        }

        git checkout `
            --force `
            --detach `
            FETCH_HEAD

        if ($LASTEXITCODE -ne 0) {
            throw "vscode-icons Ref '$UpstreamRef' konnte nicht ausgecheckt werden."
        }

        #
        # Das Upstream-Projekt bringt seine pnpm-Version über packageManager mit.
        # Corepack verwendet dadurch automatisch die passende Version.
        #
        if (-not (Get-Command corepack -ErrorAction SilentlyContinue)) {
            throw (
                "Corepack wurde nicht gefunden. " +
                "Es wird für den vscode-icons Build benötigt."
            )
        }

        Write-Host "[INFO] Installiere vscode-icons Build-Abhängigkeiten."

        corepack pnpm install `
            --frozen-lockfile

        if ($LASTEXITCODE -ne 0) {
            throw "pnpm install für vscode-icons ist fehlgeschlagen."
        }

        Write-Host "[INFO] Baue Catppuccin vscode-icons."

        corepack pnpm run build

        if ($LASTEXITCODE -ne 0) {
            throw "Build von catppuccin/vscode-icons ist fehlgeschlagen."
        }
    }
    finally {
        Pop-Location
    }

    #
    # Unser kleiner Renderer ist bewusst getrennt vom Upstream-Projekt.
    #
    Push-Location $generatorRoot

    try {
        if (-not (Test-Path (Join-Path $generatorRoot "node_modules\@resvg\resvg-js"))) {
            Write-Host "[INSTALL] Installiere SVG-Renderer für OneCommander."

            $npmPath = Get-Command `
                -Name "npm.cmd" `
                -ErrorAction SilentlyContinue

            if (-not $npmPath) {
                $npmPath = Get-Command `
                    -Name "npm" `
                    -ErrorAction SilentlyContinue
            }

            if (-not $npmPath) {
                throw "npm wurde nicht gefunden."
            }

            & $npmPath.Source `
                install `
                --no-audit `
                --no-fund

            if ($LASTEXITCODE -ne 0) {
                throw "npm install für den OneCommander Icon-Renderer ist fehlgeschlagen."
            }
        }
    }
    finally {
        Pop-Location
    }

    $themeRoot = Join-Path `
        $sourceRoot `
        "dist\mocha"

    $themeFile = Join-Path `
        $themeRoot `
        "theme.json"

    if (-not (Test-Path $themeFile)) {
        throw "Gebautes Catppuccin Mocha Theme wurde nicht gefunden: $themeFile"
    }

    Write-Host "[INFO] Erzeuge vollständiges OneCommander File-Icon-Pack."

    & node `
        $generatorScript `
        "--theme-root" $themeRoot `
        "--rendered-root" $renderedRoot `
        "--output-root" $fileIconsRoot

    if ($LASTEXITCODE -ne 0) {
        throw "OneCommander File-Icon-Generator ist fehlgeschlagen."
    }

    Write-Host (
        "[OK] OneCommander Catppuccin File-Icons erzeugt: " +
        $fileIconsRoot
    ) -ForegroundColor Green
}
