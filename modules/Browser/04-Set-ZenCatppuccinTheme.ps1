function Start-ZenBrowserForTheme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ZenExecutable
    )

    Start-Process `
        -FilePath $ZenExecutable |
    Out-Null

    for ($attempt = 1; $attempt -le 40; $attempt++) {
        if (Get-Process -Name "zen" -ErrorAction SilentlyContinue) {
            return
        }

        Start-Sleep `
            -Milliseconds 250
    }

    throw "Zen Browser wurde für die Catppuccin-Aktivierung nicht gestartet."
}


function Get-ZenCatppuccinFingerprint {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string] $SourceDirectory
    )

    $files = @(
        Get-ChildItem `
            -LiteralPath $SourceDirectory `
            -File `
            -Recurse `
            -Force |
        Sort-Object FullName
    )

    if ($files.Count -eq 0) {
        throw "Keine Zen-Catppuccin-Quelldateien gefunden: $SourceDirectory"
    }

    $lines = foreach ($file in $files) {
        $relativePath = [IO.Path]::GetRelativePath(
            $SourceDirectory,
            $file.FullName
        )

        $hash = Get-FileHash `
            -LiteralPath $file.FullName `
            -Algorithm SHA256

        "{0}|{1}" -f `
            $relativePath.Replace("\", "/"),
            $hash.Hash.ToLowerInvariant()
    }

    $payload = $lines -join "`n"
    $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
    $sha = [Security.Cryptography.SHA256]::Create()

    try {
        return (
            [Convert]::ToHexString(
                $sha.ComputeHash($bytes)
            )
        ).ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}


function Set-ZenCatppuccinTheme {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    Write-Host ""
    Write-Host "[CONFIG] Zen Catppuccin Mocha"

    $profilePath = Get-ZenProfilePath

    if (-not $profilePath) {
        Write-Warning (
            "Aktives Zen-Profil konnte für das Catppuccin-Theme nicht " +
            "eindeutig ermittelt werden."
        )

        return $false
    }

    $repositoryPath = [IO.Path]::GetFullPath(
        (Join-Path $PSScriptRoot "..\..")
    )

    $sourceDirectory = Join-Path `
        $repositoryPath `
        "dotfiles\zen\catppuccin-mocha-mauve"

    $websiteSourceDirectory = Join-Path `
        $sourceDirectory `
        "websites"

    $chromeDirectory = Join-Path `
        $profilePath `
        "chrome"

    $websiteDestinationDirectory = Join-Path `
        $chromeDirectory `
        "websites"

    $files = @(
        "userChrome.css"
        "userContent.css"
        "zen-logo-mocha.svg"
    )

    foreach ($file in $files) {
        $source = Join-Path `
            $sourceDirectory `
            $file

        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            throw "Zen Catppuccin Quelldatei fehlt: $source"
        }
    }

    if (
        -not (
            Test-Path `
                -LiteralPath $websiteSourceDirectory `
                -PathType Container
        )
    ) {
        throw (
            "Zen Catppuccin Website-Style-Verzeichnis fehlt: " +
            $websiteSourceDirectory
        )
    }

    $fingerprint = Get-ZenCatppuccinFingerprint `
        -SourceDirectory $sourceDirectory

    $stateDirectory = Join-Path `
        $repositoryPath `
        ".generated\state\zen"

    $statePath = Join-Path `
        $stateDirectory `
        "catppuccin-mocha-mauve.sha256"

    $currentFingerprint = $null

    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        $currentFingerprint = (
            Get-Content `
                -LiteralPath $statePath `
                -Raw `
                -Encoding UTF8
        ).Trim()
    }

    $contentChanged = $currentFingerprint -cne $fingerprint

    $zenInstallPath = Get-ZenInstallPath

    if (-not $zenInstallPath) {
        throw "Zen Browser wurde für das Catppuccin-Theme nicht gefunden."
    }

    $zenExe = Join-Path `
        $zenInstallPath `
        "zen.exe"

    #
    # Firefox/Zen wertet die Freigabe für userChrome/userContent sehr früh
    # beim Start aus. Wird die Policy erstmals im selben Bootstrap gesetzt,
    # benötigt sie einen vollständigen Startzyklus, bevor die Styles beim
    # darauffolgenden Start geladen werden können.
    #
    $initializationRequired = -not (
        Test-Path `
            -LiteralPath $statePath `
            -PathType Leaf
    )

    if ($initializationRequired -and $contentChanged) {
        Write-Host (
            "[INFO] Zen wird einmal vorinitialisiert, damit die " +
            "User-Styles-Policy beim ersten Theme-Start wirksam ist."
        )

        if (Get-Process -Name "zen" -ErrorAction SilentlyContinue) {
            Stop-ZenBrowser
        }

        Start-ZenBrowserForTheme `
            -ZenExecutable $zenExe

        Start-Sleep `
            -Seconds 2

        Stop-ZenBrowser
    }

    $linkChanged = $false

    foreach ($file in $files) {
        $source = Join-Path `
            $sourceDirectory `
            $file

        $destination = Join-Path `
            $chromeDirectory `
            $file

        if (Test-Path -LiteralPath $destination -PathType Leaf) {
            if (
                Test-FileHardLinkTarget `
                    -Path $destination `
                    -Target $source
            ) {
                Write-Host "[OK] Zen Theme-Datei bereits korrekt: $file" `
                    -ForegroundColor Green

                continue
            }
        }

        Set-FileHardLink `
            -Path $destination `
            -Target $source `
            -ReplaceExistingFile

        $linkChanged = $true
    }

    $junctionChanged = $true

    $existingWebsiteItem = Get-Item `
        -LiteralPath $websiteDestinationDirectory `
        -Force `
        -ErrorAction SilentlyContinue

    if (
        $existingWebsiteItem -and
        $existingWebsiteItem.PSIsContainer -and
        $existingWebsiteItem.LinkType -eq "Junction" -and
        [string] $existingWebsiteItem.Target -eq $websiteSourceDirectory
    ) {
        $junctionChanged = $false

        Write-Host "[OK] Zen Website-Style-Junction bereits korrekt." `
            -ForegroundColor Green
    }
    else {
        Set-DirectoryJunction `
            -Path $websiteDestinationDirectory `
            -Target $websiteSourceDirectory
    }

    $changed = (
        $contentChanged -or
        $linkChanged -or
        $junctionChanged
    )

    if ($changed) {
        Write-Host "[OK] Zen Catppuccin-Mocha-Theme aktualisiert." `
            -ForegroundColor Green

        if (Get-Process -Name "zen" -ErrorAction SilentlyContinue) {
            Write-Host (
                "[INFO] Zen wird für geänderte Catppuccin-Styles neu gestartet."
            )

            Stop-ZenBrowser
        }

        Start-ZenBrowserForTheme `
            -ZenExecutable $zenExe

        if (-not (Test-Path -LiteralPath $stateDirectory -PathType Container)) {
            New-Item `
                -Path $stateDirectory `
                -ItemType Directory `
                -Force |
            Out-Null
        }

        [IO.File]::WriteAllText(
            $statePath,
            $fingerprint + [Environment]::NewLine,
            [Text.UTF8Encoding]::new($false)
        )

        Write-Host "[OK] Zen Browser mit Catppuccin neu gestartet." `
            -ForegroundColor Green
    }
    else {
        Write-Host "[SKIP] Zen Catppuccin-Mocha-Theme unverändert." `
            -ForegroundColor Green
    }

    return $changed
}
