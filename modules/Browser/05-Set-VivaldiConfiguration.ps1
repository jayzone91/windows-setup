function Get-VivaldiResourcesPath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $applicationRoot = Join-Path `
        $env:LOCALAPPDATA `
        "Vivaldi\Application"

    if (-not (Test-Path -LiteralPath $applicationRoot -PathType Container)) {
        return $null
    }

    $versionDirectory = Get-ChildItem `
        -LiteralPath $applicationRoot `
        -Directory `
        -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match '^\d+\.\d+\.\d+\.\d+$' -and
        (
            Test-Path `
                -LiteralPath (
                    Join-Path `
                        $_.FullName `
                        "resources\vivaldi\window.html"
                ) `
                -PathType Leaf
        )
    } |
    Sort-Object {
        [version] $_.Name
    } -Descending |
    Select-Object -First 1

    if ($null -eq $versionDirectory) {
        return $null
    }

    return Join-Path `
        $versionDirectory.FullName `
        "resources\vivaldi"
}


function Test-FileContentEqual {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $Source,

        [Parameter(Mandatory)]
        [string] $Destination
    )

    if (-not (Test-Path -LiteralPath $Destination -PathType Leaf)) {
        return $false
    }

    $sourceHash = (
        Get-FileHash `
            -LiteralPath $Source `
            -Algorithm SHA256
    ).Hash

    $destinationHash = (
        Get-FileHash `
            -LiteralPath $Destination `
            -Algorithm SHA256
    ).Hash

    return $sourceHash -ceq $destinationHash
}


function Copy-VivaldiDesiredFile {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $Source,

        [Parameter(Mandatory)]
        [string] $Destination
    )

    if (Test-FileContentEqual -Source $Source -Destination $Destination) {
        return $false
    }

    $destinationDirectory = Split-Path `
        -Path $Destination `
        -Parent

    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
        New-Item `
            -ItemType Directory `
            -Path $destinationDirectory `
            -Force |
        Out-Null
    }

    Copy-Item `
        -LiteralPath $Source `
        -Destination $Destination `
        -Force

    return $true
}


function Backup-VivaldiUpstreamWindow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $InstalledWindowPath,

        [Parameter(Mandatory)]
        [string] $ResourcesPath,

        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    $versionDirectory = Split-Path `
        -Path (
            Split-Path `
                -Path $ResourcesPath `
                -Parent
        ) `
        -Parent

    $version = Split-Path `
        -Path $versionDirectory `
        -Leaf

    $backupDirectory = Join-Path `
        $RepositoryPath `
        ".generated\vivaldi\$version"

    $backupPath = Join-Path `
        $backupDirectory `
        "window.html.original"

    if (Test-Path -LiteralPath $backupPath -PathType Leaf) {
        return
    }

    $installedContent = Get-Content `
        -LiteralPath $InstalledWindowPath `
        -Raw

    if ($installedContent.Contains('src="safari.js"')) {
        return
    }

    New-Item `
        -ItemType Directory `
        -Path $backupDirectory `
        -Force |
    Out-Null

    Copy-Item `
        -LiteralPath $InstalledWindowPath `
        -Destination $backupPath `
        -Force
}


function Set-VivaldiConfiguration {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        $Config,

        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "[CONFIG] Vivaldi"

    $resourcesPath = Get-VivaldiResourcesPath

    if (-not $resourcesPath) {
        Write-Warning "Vivaldi-Ressourcenverzeichnis wurde nicht gefunden."
        return $false
    }

    $dotfilesRoot = Join-Path `
        $RepositoryPath `
        $Config.DotfilesPath

    $sourceWindow = Join-Path `
        $dotfilesRoot `
        "window.html"

    $sourceScript = Join-Path `
        $dotfilesRoot `
        "safari.js"

    $sourceCssDirectory = Join-Path `
        $RepositoryPath `
        $Config.CustomCssPath

    foreach ($requiredPath in @(
        $sourceWindow,
        $sourceScript,
        $sourceCssDirectory
    )) {
        if (-not (Test-Path -LiteralPath $requiredPath)) {
            throw "Vivaldi-Desired-State fehlt: $requiredPath"
        }
    }

    $installedWindow = Join-Path `
        $resourcesPath `
        "window.html"

    Backup-VivaldiUpstreamWindow `
        -InstalledWindowPath $installedWindow `
        -ResourcesPath $resourcesPath `
        -RepositoryPath $RepositoryPath

    $changed = $false

    if (
        Copy-VivaldiDesiredFile `
            -Source $sourceWindow `
            -Destination $installedWindow
    ) {
        $changed = $true
    }

    if (
        Copy-VivaldiDesiredFile `
            -Source $sourceScript `
            -Destination (
                Join-Path `
                    $resourcesPath `
                    "safari.js"
            )
    ) {
        $changed = $true
    }

    $installedCssDirectory = Join-Path `
        $resourcesPath `
        "safari-css"

    if (Test-Path -LiteralPath $installedCssDirectory) {
        $sourceFiles = @(
            Get-ChildItem `
                -LiteralPath $sourceCssDirectory `
                -File `
                -Recurse
        )

        foreach ($sourceFile in $sourceFiles) {
            $relativePath = [IO.Path]::GetRelativePath(
                $sourceCssDirectory,
                $sourceFile.FullName
            )

            $destination = Join-Path `
                $installedCssDirectory `
                $relativePath

            if (
                Copy-VivaldiDesiredFile `
                    -Source $sourceFile.FullName `
                    -Destination $destination
            ) {
                $changed = $true
            }
        }
    }

    $windowContent = Get-Content `
        -LiteralPath $installedWindow `
        -Raw

    if (-not $windowContent.Contains('src="safari.js"')) {
        throw "Vivaldi window.html enthält safari.js nach Restore nicht."
    }

    if (
        -not $windowContent.Contains(
            'chrome://vivaldi-data/css-mods/css'
        )
    ) {
        throw "Vivaldi window.html enthält den CSS-Mod-Loader nicht."
    }

    if ($changed) {
        Write-Host (
            "[OK] Vivaldi Safari-/Liquid-Glass-Mod aktualisiert."
        ) -ForegroundColor Green
    }
    else {
        Write-Host (
            "[SKIP] Vivaldi Safari-/Liquid-Glass-Mod unverändert."
        ) -ForegroundColor Green
    }

    Write-Host (
        "[INFO] Custom UI Modifications muss auf '{0}' zeigen." -f
        $sourceCssDirectory
    )

    return $changed
}