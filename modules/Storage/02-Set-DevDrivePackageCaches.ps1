function Set-DevDrivePackageCaches {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingPositionalParameters",
        "",
        Justification = "npm, pnpm und yarn sind externe CLI-Programme und verwenden Positionsargumente als Teil ihrer regulären CLI-Syntax."
    )]
    param(
        [Parameter(Mandatory)]
        $Paths,

        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "[CONFIG] Dev Drive Package Caches"

    $available = [ordered]@{
        npm  = [bool](Get-Command npm -ErrorAction SilentlyContinue)
        pnpm = [bool](Get-Command pnpm -ErrorAction SilentlyContinue)
        yarn = [bool](Get-Command yarn -ErrorAction SilentlyContinue)
        bun  = [bool](Get-Command bun -ErrorAction SilentlyContinue)
        go   = [bool](Get-Command go -ErrorAction SilentlyContinue)
    }

    $pnpmHome = Join-Path $env:LOCALAPPDATA "pnpm"
    $pnpmBin = Join-Path $pnpmHome "bin"

    $stateInput = @(
        "npm=$($Paths.NpmCache)|$($available.npm)"
        "pnpm=$($Paths.PnpmStore)|$($available.pnpm)"
        "yarn=$($Paths.YarnCache)|$($available.yarn)"
        "bun=$($Paths.BunCache)|$($available.bun)"
        "go-build=$($Paths.GoBuildCache)|$($available.go)"
        "go-mod=$($Paths.GoModCache)|$($available.go)"
        "pnpm-home=$pnpmHome"
    ) -join "`n"

    $fingerprint = Get-TextFingerprint -Text $stateInput
    $statePath = Join-Path `
        $RepositoryPath `
        ".generated\state\dev-drive-package-caches.sha256"

    $storedFingerprint = $null

    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        $storedFingerprint = (
            Get-Content -LiteralPath $statePath -Raw
        ).Trim()
    }

    if ($available.pnpm) {
        if (-not (Test-Path -LiteralPath $pnpmBin)) {
            New-Item `
                -Path $pnpmBin `
                -ItemType Directory `
                -Force |
            Out-Null
        }

        Set-UserEnvironmentVariable `
            -Name "PNPM_HOME" `
            -Value $pnpmHome

        Add-UserPathEntry -Path $pnpmBin
    }

    if ($available.bun) {
        Set-UserEnvironmentVariable `
            -Name "BUN_INSTALL_CACHE_DIR" `
            -Value $Paths.BunCache
    }

    if ($available.go) {
        Set-UserEnvironmentVariable `
            -Name "GOCACHE" `
            -Value $Paths.GoBuildCache

        Set-UserEnvironmentVariable `
            -Name "GOMODCACHE" `
            -Value $Paths.GoModCache
    }

    if ($storedFingerprint -eq $fingerprint) {
        Write-Host "[SKIP] Package-Cache-Konfiguration unverändert."
        return
    }

    if ($available.npm) {
        npm config set `
            cache `
            $Paths.NpmCache `
            --global

        if ($LASTEXITCODE -ne 0) {
            throw "npm Cache konnte nicht konfiguriert werden."
        }

        Write-Host "[SET] npm cache = $($Paths.NpmCache)"
    }

    if ($available.pnpm) {
        pnpm config set `
            store-dir `
            $Paths.PnpmStore `
            --global

        if ($LASTEXITCODE -ne 0) {
            throw "pnpm Store konnte nicht konfiguriert werden."
        }

        Write-Host "[SET] pnpm store = $($Paths.PnpmStore)"
    }

    if ($available.yarn) {
        yarn config set `
            cache-folder `
            $Paths.YarnCache

        if ($LASTEXITCODE -ne 0) {
            throw "Yarn Cache konnte nicht konfiguriert werden."
        }

        Write-Host "[SET] Yarn cache = $($Paths.YarnCache)"
    }

    $stateDirectory = Split-Path -Path $statePath -Parent

    if (-not (Test-Path -LiteralPath $stateDirectory)) {
        New-Item `
            -ItemType Directory `
            -Path $stateDirectory `
            -Force |
        Out-Null
    }

    Set-Content `
        -LiteralPath $statePath `
        -Value $fingerprint `
        -Encoding utf8NoBOM `
        -NoNewline

    Write-Host "[OK] Package Caches konfiguriert." `
        -ForegroundColor Green
}

function Set-UserEnvironmentVariable {

    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $Value
    )


    $currentUserValue = [Environment]::GetEnvironmentVariable(
        $Name,
        "User"
    )

    if ($currentUserValue -ne $Value) {
        [Environment]::SetEnvironmentVariable(
            $Name,
            $Value,
            "User"
        )

        Write-Host (
            "[SET] {0} = {1}" `
                -f `
                $Name,
            $Value
        )
    }

    Set-Item `
        -Path "Env:$Name" `
        -Value $Value
}

function Add-UserPathEntry {

    param(
        [Parameter(Mandatory)]
        [string] $Path
    )


    $userPath = [Environment]::GetEnvironmentVariable(
        "Path",
        "User"
    )


    $entries = @(
        $userPath -split ";" |
        Where-Object {
            $_
        }
    )


    if ($Path -notin $entries) {

        $newPath = (
            @(
                $entries
                $Path
            ) -join ";"
        )


        [Environment]::SetEnvironmentVariable(
            "Path",
            $newPath,
            "User"
        )


        Write-Host "[SET] User PATH += $Path"
    }


    $sessionEntries = @(
        $env:Path -split ";"
    )


    if ($Path -notin $sessionEntries) {
        $env:Path = "$Path;$env:Path"
    }
}

function Test-GamesDriveDirectories {

    param(
        [Parameter(Mandatory)]
        $Config
    )

    $gamesVolume = Get-Volume `
        -DriveLetter $Config.GamesDrive.Letter `
        -ErrorAction SilentlyContinue

    if (-not $gamesVolume) {
        return $false
    }

    if ($gamesVolume.FileSystem -ne "NTFS") {
        return $false
    }

    if (
        -not $Config.GameLibraries -or
        $Config.GameLibraries.Count -eq 0
    ) {
        return $false
    }

    foreach ($path in $Config.GameLibraries.Values) {
        if (
            -not (
                Test-Path `
                    -LiteralPath $path `
                    -PathType Container
            )
        ) {
            return $false
        }
    }

    return $true
}

function Initialize-GamesDriveDirectories {

    param(
        [Parameter(Mandatory)]
        $Config
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Games Drive Verzeichnisse"
    Write-Host "========================================"

    $gamesVolume = Get-Volume `
        -DriveLetter $Config.GamesDrive.Letter `
        -ErrorAction SilentlyContinue

    if (-not $gamesVolume) {
        Write-Warning (
            "Games Drive {0}: wurde nicht gefunden." `
                -f $Config.GamesDrive.Letter
        )

        return
    }

    if ($gamesVolume.FileSystem -ne "NTFS") {
        throw (
            "Laufwerk {0}: ist kein NTFS Volume." `
                -f $Config.GamesDrive.Letter
        )
    }

    foreach ($path in $Config.GameLibraries.Values) {
        if (Test-Path -LiteralPath $path) {
            Write-Host "[SKIP] $path bereits vorhanden."
            continue
        }

        New-Item `
            -Path $path `
            -ItemType Directory `
            -Force |
        Out-Null

        Write-Host "[CREATE] $path"
    }

    Write-Host "[OK] Games-Library-Verzeichnisse vorbereitet." `
        -ForegroundColor Green

    if (-not (Test-GamesDriveDirectories -Config $Config)) {
        throw (
            "Games-Library-Verzeichnisse konnten nicht vollständig " +
            "vorbereitet oder verifiziert werden."
        )
    }

}