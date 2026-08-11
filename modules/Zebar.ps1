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

    $packageLock = Join-Path `
        $zebarProjectDirectory `
        "package-lock.json"

    foreach ($requiredFile in @(
            $packageJson,
            $packageLock
        )) {
        if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
            throw "Erforderliche Zebar-Datei wurde nicht gefunden: $requiredFile"
        }
    }

    $npmPath = Get-NpmExecutable

    Write-Host (
        "[FOUND] npm: {0}" `
            -f $npmPath
    )

    $stateDirectory = Join-Path `
        $RepositoryPath `
        ".generated\state\zebar"

    if (-not (Test-Path -LiteralPath $stateDirectory)) {
        New-Item `
            -ItemType Directory `
            -Path $stateDirectory `
            -Force |
        Out-Null
    }

    $dependencyFiles = @(
        Get-Item -LiteralPath $packageJson
        Get-Item -LiteralPath $packageLock
    )

    $dependencyFingerprint = Get-FileSetFingerprint `
        -RootPath $zebarProjectDirectory `
        -Files $dependencyFiles

    $dependencyStatePath = Join-Path `
        $stateDirectory `
        "dependencies.sha256"

    $storedDependencyFingerprint = $null

    if (Test-Path -LiteralPath $dependencyStatePath -PathType Leaf) {
        $storedDependencyFingerprint = (
            Get-Content `
                -LiteralPath $dependencyStatePath `
                -Raw
        ).Trim()
    }

    $nodeModulesPath = Join-Path `
        $zebarProjectDirectory `
        "node_modules"

    $dependenciesChanged = (
        -not (Test-Path -LiteralPath $nodeModulesPath -PathType Container) -or
        $storedDependencyFingerprint -ne $dependencyFingerprint
    )

    Push-Location $zebarProjectDirectory

    try {
        if ($dependenciesChanged) {
            Write-Host "[INFO] Installiere geänderte Zebar-Abhängigkeiten."

            & $npmPath ci

            if ($LASTEXITCODE -ne 0) {
                throw (
                    "npm ci für Zebar ist fehlgeschlagen. " +
                    "Exit-Code: $LASTEXITCODE"
                )
            }

            Set-Content `
                -LiteralPath $dependencyStatePath `
                -Value $dependencyFingerprint `
                -Encoding utf8NoBOM `
                -NoNewline

            Write-Host "[OK] Zebar-Abhängigkeiten installiert." `
                -ForegroundColor Green
        }
        else {
            Write-Host "[SKIP] Zebar-Abhängigkeiten unverändert."
        }

        $buildInputFiles = @(
            Get-ChildItem `
                -LiteralPath $zebarProjectDirectory `
                -File `
                -ErrorAction Stop |
            Where-Object {
                $_.Name -notin @(
                    ".gitignore"
                )
            }

            Get-ChildItem `
                -LiteralPath (Join-Path $zebarProjectDirectory "src") `
                -Recurse `
                -File `
                -ErrorAction Stop
        )

        $buildFingerprint = Get-FileSetFingerprint `
            -RootPath $zebarProjectDirectory `
            -Files $buildInputFiles

        $buildStatePath = Join-Path `
            $stateDirectory `
            "build.sha256"

        $storedBuildFingerprint = $null

        if (Test-Path -LiteralPath $buildStatePath -PathType Leaf) {
            $storedBuildFingerprint = (
                Get-Content `
                    -LiteralPath $buildStatePath `
                    -Raw
            ).Trim()
        }

        $distDirectory = Join-Path `
            $zebarProjectDirectory `
            "dist"

        $buildOutputExists = (
            (Test-Path -LiteralPath $distDirectory -PathType Container) -and
            @(
                Get-ChildItem `
                    -LiteralPath $distDirectory `
                    -File `
                    -ErrorAction SilentlyContinue
            ).Count -gt 0
        )

        $buildChanged = (
            $dependenciesChanged -or
            -not $buildOutputExists -or
            $storedBuildFingerprint -ne $buildFingerprint
        )

        if ($buildChanged) {
            Write-Host "[INFO] Erstelle geändertes Zebar-Bundle."

            & $npmPath run build

            if ($LASTEXITCODE -ne 0) {
                throw (
                    "Zebar-Build ist fehlgeschlagen. " +
                    "Exit-Code: $LASTEXITCODE"
                )
            }

            Set-Content `
                -LiteralPath $buildStatePath `
                -Value $buildFingerprint `
                -Encoding utf8NoBOM `
                -NoNewline

            Write-Host "[OK] Zebar-Bundle erstellt." `
                -ForegroundColor Green
        }
        else {
            Write-Host "[SKIP] Zebar-Bundle unverändert."
        }
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
