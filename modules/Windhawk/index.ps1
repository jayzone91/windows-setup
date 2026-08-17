function Get-WindhawkCliPath {
    $candidates = @(
        (Join-Path $env:ProgramFiles "Windhawk\windhawk-cli.exe"),
        (Join-Path $env:ProgramFiles "Windhawk\Engine\windhawk-cli.exe")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    $found = Get-ChildItem `
        -LiteralPath (Join-Path $env:ProgramFiles "Windhawk") `
        -Filter "windhawk-cli.exe" `
        -File `
        -Recurse `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName

    return $found
}

function Get-LatestWindhawkAlphaRelease {
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    $repository = $Config.Release.Repository
    $uri = "https://api.github.com/repos/$repository/releases?per_page=30"

    $releases = Invoke-RestMethod `
        -Uri $uri `
        -Headers @{
            Accept       = "application/vnd.github+json"
            "User-Agent" = "windows-setup"
        } `
        -ErrorAction Stop

    $release = $releases |
        Where-Object {
            $_.prerelease -and
            $_.tag_name -match $Config.Release.TagPattern
        } |
        Sort-Object {
            [version]($_.tag_name -replace "^2\.0\.0-alpha\.", "2.0.0.")
        } -Descending |
        Select-Object -First 1

    if (-not $release) {
        throw "Keine passende Windhawk-2.0-Alpha-Version gefunden."
    }

    $asset = $release.assets |
        Where-Object name -eq $Config.Release.AssetName |
        Select-Object -First 1

    if (-not $asset) {
        throw "Windhawk-Installer-Asset fehlt: $($Config.Release.AssetName)"
    }

    [pscustomobject]@{
        Version     = $release.tag_name
        DownloadUrl = $asset.browser_download_url
    }
}

function Install-WindhawkAlpha {
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config
    )

    $release = Get-LatestWindhawkAlphaRelease -Config $Config
    $cli = Get-WindhawkCliPath

    if ($cli) {
        $installedVersion = (& $cli --version 2>$null | Select-Object -First 1)

        if ($LASTEXITCODE -eq 0 -and $installedVersion -match [regex]::Escape($release.Version)) {
            Write-Host "[SKIP] Windhawk $($release.Version) bereits installiert."
            return $cli
        }
    }

    Write-Host "[INSTALL] Windhawk $($release.Version)"

    $tempRoot = Join-Path $env:TEMP "windows-setup\windhawk"
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

    $installerPath = Join-Path $tempRoot "windhawk_setup.exe"

    Invoke-WebRequest `
        -Uri $release.DownloadUrl `
        -OutFile $installerPath `
        -Headers @{
            "User-Agent" = "windows-setup"
        } `
        -ErrorAction Stop

    $process = Start-Process `
        -FilePath $installerPath `
        -ArgumentList @("/S", "/STANDARD") `
        -Wait `
        -PassThru

    if ($process.ExitCode -ne 0) {
        throw "Windhawk-Installer fehlgeschlagen: ExitCode $($process.ExitCode)"
    }

    $cli = Get-WindhawkCliPath

    if (-not $cli) {
        throw "windhawk-cli.exe wurde nach der Installation nicht gefunden."
    }

    $cli
}

function Set-WindhawkResourceRedirect {
    param(
        [Parameter(Mandatory)]
        [string] $CliPath,

        [Parameter(Mandatory)]
        [hashtable] $Config,

        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    $modId = $Config.Mod.Id
    $themePath = Join-Path $RepositoryPath $Config.Mod.ThemeRelativePath

    if (-not (Test-Path -LiteralPath (Join-Path $themePath "theme.ini") -PathType Leaf)) {
        throw "Windhawk-Theme fehlt: $themePath"
    }

    $installedMods = & $CliPath --json mod list 2>$null

    if ($LASTEXITCODE -ne 0) {
        throw "Windhawk-Modliste konnte nicht gelesen werden."
    }

    if ($installedMods -notmatch [regex]::Escape($modId)) {
        Write-Host "[INSTALL] Windhawk-Mod: $modId"

        & $CliPath mod install $modId

        if ($LASTEXITCODE -ne 0) {
            throw "Windhawk-Mod konnte nicht installiert werden: $modId"
        }
    }
    else {
        Write-Host "[UPDATE] Windhawk-Mod: $modId"

        & $CliPath mod update $modId

        if ($LASTEXITCODE -ne 0) {
            throw "Windhawk-Mod konnte nicht aktualisiert werden: $modId"
        }
    }

    & $CliPath mod enable $modId

    if ($LASTEXITCODE -ne 0) {
        throw "Windhawk-Mod konnte nicht aktiviert werden: $modId"
    }

    $pairs = @()

    foreach ($setting in $Config.Mod.Settings) {
        $value = [string]$setting.Value

        if ($value -eq "{THEME_PATH}") {
            $value = $themePath
        }

        $pairs += "$($setting.Key)=$value"
    }

    & $CliPath mod settings set $modId @pairs

    if ($LASTEXITCODE -ne 0) {
        throw "Windhawk-Mod-Settings konnten nicht gesetzt werden: $modId"
    }

    Write-Host "[OK] Windhawk Resource Redirect konfiguriert." -ForegroundColor Green
}

function Initialize-Windhawk {
    param(
        [Parameter(Mandatory)]
        [hashtable] $Config,

        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    $cli = Install-WindhawkAlpha -Config $Config

    Set-WindhawkResourceRedirect `
        -CliPath $cli `
        -Config $Config `
        -RepositoryPath $RepositoryPath
}