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


$script:WingetInstallQueue = @{
    winget  = [Collections.Generic.List[string]]::new()
    msstore = [Collections.Generic.List[string]]::new()
}

$script:WingetUpgradeQueue = @{
    winget  = [Collections.Generic.List[string]]::new()
    msstore = [Collections.Generic.List[string]]::new()
}


function Reset-WingetPackageQueues {
    foreach ($source in @("winget", "msstore")) {
        $script:WingetInstallQueue[$source].Clear()
        $script:WingetUpgradeQueue[$source].Clear()
    }
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

        [string]$InstallLocation,

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
        if ($InstallLocation -or $Version) {
            Write-Host "[INSTALL] $Name" `
                -ForegroundColor Cyan

            $installArguments = @(
                "install"
                "--id", $Id
                "--exact"
                "--source", $Source
                "--accept-package-agreements"
                "--accept-source-agreements"
                "--disable-interactivity"
            )

            if ($InstallLocation) {
                $expandedInstallLocation = (
                    [Environment]::ExpandEnvironmentVariables(
                        $InstallLocation
                    )
                )

                $installArguments += @(
                    "--location", $expandedInstallLocation
                )
            }

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

        if (-not $script:WingetInstallQueue[$Source].Contains($Id)) {
            $script:WingetInstallQueue[$Source].Add($Id)
        }

        Write-Host "[QUEUE] Installation: $Name"
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

    if (-not $script:WingetUpgradeQueue[$Source].Contains($Id)) {
        $script:WingetUpgradeQueue[$Source].Add($Id)
    }

    Write-Host "[QUEUE] Update-Prüfung: $Name"
}


function Invoke-WingetQueuedChanges {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingPositionalParameters",
        "",
        Justification = "WinGet unterstützt mehrere Paket-Queries positionsbasiert in einem gemeinsamen Install-/Upgrade-Aufruf."
    )]
    param()

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Winget Batch"
    Write-Host "========================================"

    foreach ($source in @("winget", "msstore")) {
        $installIds = @(
            $script:WingetInstallQueue[$source] |
            Select-Object -Unique
        )

        if ($installIds.Count -eq 0) {
            continue
        }

        Write-Host (
            "[INSTALL] {0} verwaltete Pakete über Source '{1}'." `
                -f $installIds.Count, $source
        ) -ForegroundColor Cyan

        $installArguments = @("install") +
            $installIds +
            @(
                "--exact"
                "--source", $source
                "--accept-package-agreements"
                "--accept-source-agreements"
                "--disable-interactivity"
            )

        & winget @installArguments

        if ($LASTEXITCODE -ne 0) {
            throw (
                "Gebündelte Winget-Installation für Source '{0}' " +
                "ist fehlgeschlagen. ExitCode: {1}" `
                    -f $source, $LASTEXITCODE
            )
        }

        Write-Host "[OK] Winget-Installationsbatch abgeschlossen." `
            -ForegroundColor Green
    }

    foreach ($source in @("winget", "msstore")) {
        $upgradeIds = @(
            $script:WingetUpgradeQueue[$source] |
            Select-Object -Unique
        )

        if ($upgradeIds.Count -eq 0) {
            continue
        }

        Write-Host (
            "[UPDATE] Prüfe {0} verwaltete Pakete über Source '{1}'." `
                -f $upgradeIds.Count, $source
        )

        $upgradeArguments = @("upgrade") +
            $upgradeIds +
            @(
                "--exact"
                "--source", $source
                "--accept-package-agreements"
                "--accept-source-agreements"
                "--disable-interactivity"
            )

        $upgradeOutput = @(
            & winget @upgradeArguments 2>&1
        )

        $upgradeExitCode = $LASTEXITCODE

        switch ($upgradeExitCode) {
            0 {
                Write-Host "[OK] Winget-Updatebatch abgeschlossen." `
                    -ForegroundColor Green
            }

            -1978335189 {
                Write-Host "[CURRENT] Verwaltete Winget-Pakete sind aktuell." `
                    -ForegroundColor Green
            }

            default {
                Write-Warning (
                    "Gebündeltes Winget-Upgrade für Source '{0}' " +
                    "meldet ExitCode {1}." `
                        -f $source, $upgradeExitCode
                )

                $upgradeOutput |
                ForEach-Object {
                    Write-Host $_
                }
            }
        }
    }
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

    $escapedId = [regex]::Escape($Id)
    $packagePattern = (
        '(?i)(?<!\S)' +
        $escapedId +
        '(?!\S)\s+(\S+)'
    )

    foreach ($rawLine in $output) {
        $line = [string]$rawLine

        # Winget kann ANSI-Steuersequenzen in die Terminalausgabe
        # einbetten. Diese dürfen die Paket-ID-Erkennung nicht stören.
        $line = [regex]::Replace(
            $line,
            "$([char]27)\[[0-?]*[ -/]*[@-~]",
            ""
        )

        $match = [regex]::Match(
            $line,
            $packagePattern
        )

        if ($match.Success) {
            return $match.Groups[1].Value.Trim()
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