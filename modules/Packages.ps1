function Test-WingetPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    winget list `
        --id $Id `
        --exact `
        --accept-source-agreements `
        --disable-interactivity *> $null

    return $LASTEXITCODE -eq 0
}


function Install-WingetPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateSet("winget", "msstore")]
        [string]$Source,

        [string]$Version,

        [bool]$Update = $true
    )

    Write-Host ""
    Write-Host "[CHECK] $Name"

    $listArguments = @(
        "list"
        "--id", $Id
        "--exact"
        "--source", $Source
        "--accept-source-agreements"
        "--disable-interactivity"
    )

    & winget @listArguments 2>&1

    $isInstalled = ($LASTEXITCODE -eq 0)

    if (-not $isInstalled) {
        Write-Host "[INSTALL] $Name" -ForegroundColor Cyan

        $installArguments = @(
            "install"
            "--id", $Id
            "--exact"
            "--source", $Source
            "--accept-package-agreements"
            "--accept-source-agreements"
            "--disable-interactivity"
        )

        if ($Version) {
            $installArguments += @(
                "--version", $Version
            )
        }

        & winget @installArguments

        if ($LASTEXITCODE -ne 0) {
            throw "Installation fehlgeschlagen: $Name"
        }

        Write-Host "[OK] $Name installiert." `
            -ForegroundColor Green

        return
    }

    Write-Host "[OK] $Name ist installiert." `
        -ForegroundColor Green

    if ($Version) {
        $installedVersion = Get-WingetInstalledVersion `
            -Id $Id `
            -Source $Source

        if (-not $installedVersion) {
            Write-Warning (
                "Installierte Version von '{0}' konnte nicht ermittelt werden." `
                    -f $Name
            )

            return
        }

        Write-Host (
            "[INFO] Installierte Version: {0}" `
                -f $installedVersion
        )

        if ($installedVersion -eq $Version) {
            Write-Host (
                "[CURRENT] {0} Version {1} ist installiert." `
                    -f `
                    $Name,
                $Version
            ) `
                -ForegroundColor Green

            return
        }

        Write-Host (
            "[PIN] {0}: {1} -> {2}" `
                -f `
                $Name,
            $installedVersion,
            $Version
        ) `
            -ForegroundColor Yellow

        Install-WingetPinnedVersion `
            -Id $Id `
            -Name $Name `
            -Version $Version `
            -Source $Source

        return
    }

    if (-not $Update) {
        Write-Host "[SKIP] Update-Prüfung deaktiviert."
        return
    }

    Write-Host "[UPDATE] Prüfe auf Updates..."

    $upgradeArguments = @(
        "upgrade"
        "--id", $Id
        "--exact"
        "--source", $Source
        "--accept-package-agreements"
        "--accept-source-agreements"
        "--disable-interactivity"
    )

    $upgradeOutput = & winget @upgradeArguments 2>&1
    $upgradeExitCode = $LASTEXITCODE

    switch ($upgradeExitCode) {
        0 {
            Write-Host "[UPDATED] $Name wurde aktualisiert." `
                -ForegroundColor Green
        }

        -1978335189 {
            Write-Host "[CURRENT] $Name ist bereits aktuell." `
                -ForegroundColor Green
        }

        default {
            Write-Warning (
                "Winget-Update für '$Name' fehlgeschlagen. " +
                "ExitCode: $upgradeExitCode"
            )

            $upgradeOutput | ForEach-Object {
                Write-Host $_
            }
        }
    }

    Write-Host "[OK] Update-Prüfung abgeschlossen." `
        -ForegroundColor Green
}


function Get-WingetInstalledVersion {
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [ValidateSet("winget", "msstore")]
        [string]$Source
    )

    $arguments = @(
        "list"
        "--id", $Id
        "--exact"
        "--source", $Source
        "--accept-source-agreements"
        "--disable-interactivity"
    )

    $output = @(
        & winget @arguments 2>&1
    )

    if ($LASTEXITCODE -ne 0) {
        return $null
    }

    foreach ($line in $output) {
        if ($line -notmatch [regex]::Escape($Id)) {
            continue
        }

        $columns = @(
            $line -split "\s{2,}" |
            ForEach-Object {
                $_.Trim()
            } |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            }
        )

        $idIndex = [Array]::IndexOf(
            $columns,
            $Id
        )

        if (
            $idIndex -ge 0 -and
            $columns.Count -gt ($idIndex + 1)
        ) {
            return $columns[$idIndex + 1]
        }
    }

    return $null
}


function Install-WingetPinnedVersion {
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Version,

        [Parameter(Mandatory)]
        [ValidateSet("winget", "msstore")]
        [string]$Source
    )

    Write-Host (
        "[INSTALL] Gepinnte Version {0}" `
            -f $Version
    )

    $arguments = @(
        "install"
        "--id", $Id
        "--exact"
        "--version", $Version
        "--force"
        "--source", $Source
        "--accept-package-agreements"
        "--accept-source-agreements"
        "--disable-interactivity"
    )

    & winget @arguments

    if ($LASTEXITCODE -ne 0) {
        throw (
            "Gepinnte Version konnte nicht installiert werden: {0} {1}" `
                -f `
                $Name,
            $Version
        )
    }

    Write-Host (
        "[OK] {0} Version {1} installiert." `
            -f `
            $Name,
        $Version
    ) `
        -ForegroundColor Green
}


function Test-ChocolateyPackage {
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    $output = @(
        & choco list `
            --exact $Id `
            --limit-output `
            --no-color 2>$null
    )

    $pattern = "^{0}\|" -f [regex]::Escape($Id)

    return @(
        $output | Where-Object {
            $_ -match $pattern
        }
    ).Count -gt 0
}


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

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "[INSTALL] Chocolatey" -ForegroundColor Cyan

        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.ServicePointManager]::SecurityProtocol -bor `
            [Net.SecurityProtocolType]::Tls12

        $installScript = Invoke-RestMethod `
            -Uri "https://community.chocolatey.org/install.ps1"

        Invoke-Expression $installScript

        Update-SessionPath
    }
    else {
        Write-Host "[OK] Chocolatey ist installiert." `
            -ForegroundColor Green
    }

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        throw "Chocolatey konnte nicht installiert oder gefunden werden."
    }

    Write-Host "[UPDATE] Chocolatey selbst aktualisieren..."

    & choco upgrade `
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

    $output = @(
        & scoop bucket list 2>$null
    )

    $pattern = "^\s*{0}\s+" -f [regex]::Escape($Name)

    return @(
        $output | Where-Object {
            $_ -match $pattern
        }
    ).Count -gt 0
}


function Initialize-ScoopBuckets {
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


function Initialize-PackageManagers {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Packages
    )

    Install-Chocolatey
    Install-Scoop

    Initialize-ScoopBuckets `
        -Packages $Packages
}


function Install-PackageGroup {
    param(
        [Parameter(Mandatory)]
        [array]$Packages,

        [Parameter(Mandatory)]
        [string]$GroupName
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " $GroupName"
    Write-Host "========================================"

    foreach ($package in $Packages) {
        if (-not $package.ContainsKey("Source")) {
            throw (
                "Paket '{0}' hat keine Source definiert." `
                    -f $package.Name
            )
        }

        $source = [string]$package.Source
        $version = $null
        $update = $true

        if ($package.ContainsKey("Version")) {
            $version = [string]$package.Version
        }

        if ($package.ContainsKey("Update")) {
            $update = [bool]$package.Update
        }

        switch ($source) {
            { $_ -in @("winget", "msstore") } {
                Install-WingetPackage `
                    -Id $package.Id `
                    -Name $package.Name `
                    -Source $source `
                    -Version $version `
                    -Update $update

                break
            }

            "chocolatey" {
                Install-ChocolateyPackage `
                    -Id $package.Id `
                    -Name $package.Name `
                    -Update $update

                break
            }

            "scoop" {
                if (-not $package.ContainsKey("Bucket")) {
                    throw (
                        "Scoop-Paket '{0}' hat keinen Bucket definiert." `
                            -f $package.Name
                    )
                }

                Install-ScoopPackage `
                    -Id $package.Id `
                    -Name $package.Name `
                    -Bucket $package.Bucket `
                    -Update $update

                break
            }

            default {
                throw (
                    "Unbekannte Paketquelle '{0}' für Paket '{1}'." `
                        -f `
                        $source,
                    $package.Name
                )
            }
        }
    }
}


function Clear-PackageManagerCaches {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Paketmanager Cleanup"
    Write-Host "========================================"

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "[CLEAN] Chocolatey HTTP-Cache"

        & choco cache remove --expired

        if ($LASTEXITCODE -ne 0) {
            Write-Warning (
                "Chocolatey-Cache konnte nicht vollständig bereinigt werden."
            )
        }
    }

    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "[CLEAN] Scoop Download-Cache"

        & scoop cache rm *

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Scoop-Download-Cache konnte nicht bereinigt werden."
        }

        Write-Host "[CLEAN] Alte Scoop-App-Versionen"

        & scoop cleanup *

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Alte Scoop-Versionen konnten nicht bereinigt werden."
        }
    }

    Write-Host (
        "[SKIP] Winget besitzt aktuell keinen unterstützten " +
        "allgemeinen Cache-Cleanup-Befehl."
    )
}