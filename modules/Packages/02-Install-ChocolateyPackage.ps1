function Install-ChocolateyPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$Name,

        [bool]$Update = $true
    )

    Write-Host ""
    Write-Host "[CHECK] $Name"

    $isInstalled = Test-ChocolateyPackage -Id $Id

    if (-not $isInstalled) {
        Write-Host "[INSTALL] $Name" -ForegroundColor Cyan

        & choco install `
            $Id `
            --yes `
            --no-progress

        if ($LASTEXITCODE -notin @(0, 1641, 3010)) {
            throw "Chocolatey-Installation fehlgeschlagen: $Name"
        }

        Write-Host "[OK] $Name installiert." `
            -ForegroundColor Green

        return
    }

    Write-Host "[OK] $Name ist installiert." `
        -ForegroundColor Green

    if (-not $Update) {
        Write-Host "[SKIP] Update-Prüfung deaktiviert."
        return
    }

    Write-Host "[UPDATE] Prüfe auf Updates..."

    & choco upgrade `
        $Id `
        --yes `
        --no-progress

    if ($LASTEXITCODE -notin @(0, 2, 1641, 3010)) {
        throw "Chocolatey-Update fehlgeschlagen: $Name"
    }

    Write-Host "[OK] Chocolatey-Update-Prüfung abgeschlossen." `
        -ForegroundColor Green
}


function Test-ScoopPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    & scoop prefix $Id *> $null

    return $LASTEXITCODE -eq 0
}


function Install-ScoopPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Bucket,

        [bool]$Update = $true
    )

    Write-Host ""
    Write-Host "[CHECK] $Name"

    $isInstalled = Test-ScoopPackage -Id $Id

    if (-not $isInstalled) {
        Write-Host "[INSTALL] $Name" -ForegroundColor Cyan

        $packageReference = "{0}/{1}" -f $Bucket, $Id

        & scoop install $packageReference

        if ($LASTEXITCODE -ne 0) {
            throw "Scoop-Installation fehlgeschlagen: $Name"
        }

        Write-Host "[OK] $Name installiert." `
            -ForegroundColor Green

        return
    }

    Write-Host "[OK] $Name ist installiert." `
        -ForegroundColor Green

    if (-not $Update) {
        Write-Host "[SKIP] Update-Prüfung deaktiviert."
        return
    }

    Write-Host "[UPDATE] Prüfe auf Updates..."

    & scoop update $Id

    if ($LASTEXITCODE -ne 0) {
        throw "Scoop-Update fehlgeschlagen: $Name"
    }

    Write-Host "[OK] Scoop-Update-Prüfung abgeschlossen." `
        -ForegroundColor Green
}


function Install-Chocolatey {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Chocolatey"
    Write-Host "========================================"

    $chocolateyInstall = if ($env:ChocolateyInstall) {
        $env:ChocolateyInstall
    }
    else {
        [Environment]::GetEnvironmentVariable(
            "ChocolateyInstall",
            "Machine"
        )
    }

    $chocoExecutable = if ($chocolateyInstall) {
        Join-Path $chocolateyInstall "bin\choco.exe"
    }
    else {
        Join-Path $env:ProgramData "chocolatey\bin\choco.exe"
    }

    if (-not (Test-Path $chocoExecutable)) {
        Write-Host "[INSTALL] Chocolatey" -ForegroundColor Cyan

        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.ServicePointManager]::SecurityProtocol -bor `
            [Net.SecurityProtocolType]::Tls12

        $installerPath = Join-Path `
            ([System.IO.Path]::GetTempPath()) `
            "chocolatey-install.ps1"

        try {
            Invoke-WebRequest `
                -Uri "https://community.chocolatey.org/install.ps1" `
                -OutFile $installerPath

            & $installerPath

            if ($LASTEXITCODE -ne 0) {
                throw (
                    "Chocolatey-Installer meldet ExitCode {0}." `
                        -f $LASTEXITCODE
                )
            }
        }
        finally {
            if (Test-Path $installerPath) {
                Remove-Item `
                    -Path $installerPath `
                    -Force `
                    -ErrorAction SilentlyContinue
            }
        }

        Update-SessionPath
    }
    else {
        Write-Host "[OK] Chocolatey ist installiert." `
            -ForegroundColor Green
    }

    Update-SessionPath

    if (-not (Test-Path $chocoExecutable)) {
        $chocolateyInstall = [Environment]::GetEnvironmentVariable(
            "ChocolateyInstall",
            "Machine"
        )

        if ($chocolateyInstall) {
            $chocoExecutable = Join-Path `
                $chocolateyInstall `
                "bin\choco.exe"
        }
    }

    if (-not (Test-Path $chocoExecutable)) {
        throw "Chocolatey konnte nicht installiert oder gefunden werden."
    }

    Write-Host "[UPDATE] Chocolatey selbst aktualisieren..."

    & $chocoExecutable upgrade `
        chocolatey `
        --yes `
        --no-progress

    if ($LASTEXITCODE -notin @(0, 2, 1641, 3010)) {
        throw "Chocolatey konnte nicht aktualisiert werden."
    }

    Update-SessionPath
}


function Install-Scoop {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Scoop"
    Write-Host "========================================"

    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "[INSTALL] Scoop" -ForegroundColor Cyan

        $installerPath = Join-Path `
            ([System.IO.Path]::GetTempPath()) `
            "scoop-install.ps1"

        try {
            Invoke-WebRequest `
                -Uri "https://get.scoop.sh" `
                -OutFile $installerPath

            & $installerPath -RunAsAdmin

            if ($LASTEXITCODE -ne 0) {
                throw "Scoop-Installer meldet ExitCode $LASTEXITCODE."
            }
        }
        finally {
            if (Test-Path $installerPath) {
                Remove-Item `
                    -Path $installerPath `
                    -Force `
                    -ErrorAction SilentlyContinue
            }
        }

        Update-SessionPath
    }
    else {
        Write-Host "[OK] Scoop ist installiert." `
            -ForegroundColor Green
    }

    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        throw "Scoop konnte nicht installiert oder gefunden werden."
    }

    Write-Host "[UPDATE] Scoop selbst und Manifeste aktualisieren..."

    & scoop update

    if ($LASTEXITCODE -ne 0) {
        throw "Scoop konnte nicht aktualisiert werden."
    }

    Update-SessionPath
}


function Get-RequiredScoopBuckets {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Packages
    )

    $buckets = @{}

    foreach ($group in $Packages.Values) {
        if ($group -is [string]) {
            continue
        }

        foreach ($package in @($group)) {
            if (
                -not ($package -is [hashtable]) -or
                -not $package.ContainsKey("Source") -or
                $package.Source -ne "scoop"
            ) {
                continue
            }

            if (-not $package.ContainsKey("Bucket")) {
                throw (
                    "Scoop-Paket '{0}' hat keinen Bucket definiert." `
                        -f $package.Name
                )
            }

            $bucketName = [string]$package.Bucket
            $bucketUrl = $null

            if ($package.ContainsKey("BucketUrl")) {
                $bucketUrl = [string]$package.BucketUrl
            }

            if ($bucketName -eq "main") {
                continue
            }

            if ($buckets.ContainsKey($bucketName)) {
                $existingUrl = $buckets[$bucketName]

                if (
                    $existingUrl -and
                    $bucketUrl -and
                    $existingUrl -ne $bucketUrl
                ) {
                    throw (
                        "Scoop-Bucket '{0}' ist mit mehreren URLs definiert." `
                            -f $bucketName
                    )
                }

                if (-not $existingUrl -and $bucketUrl) {
                    $buckets[$bucketName] = $bucketUrl
                }

                continue
            }

            $buckets[$bucketName] = $bucketUrl
        }
    }

    return $buckets
}


function Test-ScoopBucket {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $scoopRoot = if ($env:SCOOP) {
        $env:SCOOP
    }
    else {
        Join-Path $env:USERPROFILE "scoop"
    }

    $bucketPath = Join-Path `
        (Join-Path $scoopRoot "buckets") `
        $Name

    if (Test-Path $bucketPath) {
        return $true
    }

    $output = @(
        & scoop bucket list 2>$null
    )

    $pattern = "^\s*{0}(?:\s|$)" -f [regex]::Escape($Name)

    return @(
        $output | Where-Object {
            $_ -match $pattern
        }
    ).Count -gt 0
}


function Initialize-ScoopBuckets {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingPositionalParameters",
        "",
        Justification = "Scoop ist eine native CLI und verwendet positionsbasierte Argumente."
    )]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Packages
    )

    $buckets = Get-RequiredScoopBuckets -Packages $Packages

    if ($buckets.Count -eq 0) {
        Write-Host "[OK] Keine zusätzlichen Scoop-Buckets benötigt."
        return
    }

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Scoop Buckets"
    Write-Host "========================================"

    foreach ($entry in $buckets.GetEnumerator()) {
        $bucketName = [string]$entry.Key
        $bucketUrl = $entry.Value

        if (Test-ScoopBucket -Name $bucketName) {
            Write-Host "[OK] Scoop-Bucket '$bucketName' ist vorhanden." `
                -ForegroundColor Green
            continue
        }

        Write-Host "[ADD] Scoop-Bucket '$bucketName'" `
            -ForegroundColor Cyan

        if ($bucketUrl) {
            & scoop bucket add $bucketName $bucketUrl
        }
        else {
            & scoop bucket add $bucketName
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Scoop-Bucket konnte nicht hinzugefügt werden: $bucketName"
        }

        Write-Host "[OK] Scoop-Bucket '$bucketName' hinzugefügt." `
            -ForegroundColor Green
    }
}