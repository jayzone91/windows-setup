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

        [string]$Source,

        [string]$Version,

        [bool]$Update = $true
    )

    Write-Host ""
    Write-Host "[CHECK] $Name"

    # ------------------------------------------------------------
    # Prüfen, ob das Paket bereits installiert ist
    # ------------------------------------------------------------

    $listArguments = @(
        "list"
        "--id", $Id
        "--exact"
        "--accept-source-agreements"
        "--disable-interactivity"
    )

    if ($Source) {
        $listArguments += @(
            "--source", $Source
        )
    }


    & winget @listArguments 2>&1


    $isInstalled = ($LASTEXITCODE -eq 0)

    # ------------------------------------------------------------
    # Nicht installiert -> installieren
    # ------------------------------------------------------------

    if (-not $isInstalled) {
        Write-Host "[INSTALL] $Name" -ForegroundColor Cyan

        $installArguments = @(
            "install"
            "--id", $Id
            "--exact"
            "--accept-package-agreements"
            "--accept-source-agreements"
            "--disable-interactivity"
        )

        if ($Version) {
            $installArguments += @(
                "--version", $Version
            )
        }

        if ($Source) {
            $installArguments += @(
                "--source", $Source
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

    # ------------------------------------------------------------
    # Gepinnte Version prüfen
    # ------------------------------------------------------------

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


    Write-Host "[OK] $Name ist installiert." `
        -ForegroundColor Green

    # ------------------------------------------------------------
    # Updates für dieses Paket deaktiviert
    # ------------------------------------------------------------

    if (-not $Update) {
        Write-Host "[SKIP] Update-Prüfung deaktiviert."
        return
    }

    # ------------------------------------------------------------
    # Auf Update prüfen
    # ------------------------------------------------------------

    Write-Host "[UPDATE] Prüfe auf Updates..."

    $upgradeArguments = @(
        "upgrade"
        "--id", $Id
        "--exact"
        "--accept-package-agreements"
        "--accept-source-agreements"
        "--disable-interactivity"
    )

    if ($Source) {
        $upgradeArguments += @(
            "--source", $Source
        )
    }

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

        $source = $null
        $version = $null
        $update = $true

        if ($package.ContainsKey("Source")) {
            $source = $package.Source
        }

        if ($package.ContainsKey("Version")) {
            $version = $package.Version
        }

        if ($package.ContainsKey("Update")) {
            $update = [bool]$package.Update
        }

        Install-WingetPackage `
            -Id $package.Id `
            -Name $package.Name `
            -Source $source `
            -Version $version `
            -Update $update
    }
}

function Get-WingetInstalledVersion {

    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [string]$Source
    )


    $arguments = @(
        "list"
        "--id", $Id
        "--exact"
        "--accept-source-agreements"
        "--disable-interactivity"
    )


    if ($Source) {
        $arguments += @(
            "--source", $Source
        )
    }


    $output = @(
        & winget @arguments 2>&1
    )


    if ($LASTEXITCODE -ne 0) {
        return $null
    }


    foreach ($line in $output) {

        if ($line -match [regex]::Escape($Id)) {

            $columns = $line -split "\s{2,}" |
            Where-Object {
                $_ -and $_.Trim()
            }


            if ($columns.Count -ge 3) {

                return $columns[2].Trim()
            }
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
        "--accept-package-agreements"
        "--accept-source-agreements"
        "--disable-interactivity"
    )


    if ($Source) {
        $arguments += @(
            "--source", $Source
        )
    }


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
