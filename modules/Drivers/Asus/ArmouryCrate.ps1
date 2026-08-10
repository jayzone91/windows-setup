function Get-AsusArmouryCrateInstallation {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $appxPackages = @()

    try {
        $appxPackages += @(
            Get-AppxPackage -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -match "(?i)Armoury.*Crate" -or
                $_.PackageFullName -match "(?i)Armoury.*Crate"
            }
        )
    }
    catch {
        Write-Verbose (
            "Armoury-Crate-AppX-Prüfung für aktuellen Benutzer " +
            "fehlgeschlagen: $($_.Exception.Message)"
        )
    }

    if (Test-Administrator) {
        try {
            $appxPackages += @(
                Get-AppxPackage `
                    -AllUsers `
                    -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.Name -match "(?i)Armoury.*Crate" -or
                    $_.PackageFullName -match "(?i)Armoury.*Crate"
                }
            )
        }
        catch {
            Write-Verbose (
                "Armoury-Crate-AppX-Prüfung für alle Benutzer " +
                "fehlgeschlagen: $($_.Exception.Message)"
            )
        }
    }

    $appx = @(
        $appxPackages |
        Sort-Object PackageFullName -Unique |
        Sort-Object {
            try {
                [version] $_.Version
            }
            catch {
                [version] "0.0.0.0"
            }
        } -Descending
    ) |
    Select-Object -First 1

    if ($appx) {
        return [PSCustomObject]@{
            Installed = $true
            Version   = [string] $appx.Version
            Source    = "AppX"
            Name      = [string] $appx.Name
            AppId     = $null
        }
    }

    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $registryEntries = foreach ($path in $uninstallPaths) {
        Get-ItemProperty `
            -Path $path `
            -ErrorAction SilentlyContinue
    }

    $registryEntry = @(
        $registryEntries |
        Where-Object {
            $_.DisplayName -and
            $_.DisplayName -match "(?i)^(?:ASUS\s+)?Armoury\s*Crate$"
        } |
        Sort-Object {
            try {
                [version] $_.DisplayVersion
            }
            catch {
                [version] "0.0.0.0"
            }
        } -Descending
    ) |
    Select-Object -First 1

    if ($registryEntry) {
        return [PSCustomObject]@{
            Installed = $true
            Version   = [string] $registryEntry.DisplayVersion
            Source    = "Registry"
            Name      = [string] $registryEntry.DisplayName
            AppId     = $null
        }
    }

    $getStartApps = Get-Command `
        -Name Get-StartApps `
        -ErrorAction SilentlyContinue

    if ($getStartApps) {
        $startApp = @(
            Get-StartApps |
            Where-Object {
                $_.Name -match "(?i)^Armoury\s*Crate$"
            }
        ) |
        Select-Object -First 1

        if ($startApp) {
            return [PSCustomObject]@{
                Installed = $true
                Version   = $null
                Source    = "StartApps"
                Name      = [string] $startApp.Name
                AppId     = [string] $startApp.AppID
            }
        }
    }

    $service = Get-Service `
        -Name "ArmouryCrateService" `
        -ErrorAction SilentlyContinue

    if ($service) {
        return [PSCustomObject]@{
            Installed = $true
            Version   = $null
            Source    = "Service"
            Name      = [string] $service.DisplayName
            AppId     = $null
        }
    }

    return [PSCustomObject]@{
        Installed = $false
        Version   = $null
        Source    = $null
        Name      = $null
        AppId     = $null
    }
}

function Install-AsusArmouryCrate {
    [CmdletBinding()]
    param()

    Write-Step "ASUS Armoury Crate"

    $installation = Get-AsusArmouryCrateInstallation

    if ($installation.Installed) {
        $versionText = if ($installation.Version) {
            " Version $($installation.Version)"
        }
        else {
            ""
        }
        $installationStatus = (
            "[OK] ASUS Armoury Crate ist installiert.{0} " +
            "(Erkennung: {1})"
        ) -f $versionText, $installation.Source

        Write-Host $installationStatus -ForegroundColor Green

        Write-Host (
            "[INFO] Programm- und Core-Service-Updates werden " +
            "über das Armoury Crate Update Center verwaltet."
        )

        return
    }

    Write-Host (
        "[INSTALL] ASUS Armoury Crate über Winget"
    ) -ForegroundColor Cyan

    $arguments = @(
        "install"
        "--id", "Asus.ArmouryCrate"
        "--exact"
        "--source", "winget"
        "--accept-package-agreements"
        "--accept-source-agreements"
        "--disable-interactivity"
    )

    $output = @(
        & winget @arguments 2>&1
    )

    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        Write-Warning (
            "ASUS Armoury Crate konnte über Winget nicht " +
            "installiert werden. ExitCode: $exitCode"
        )

        $output |
        ForEach-Object {
            Write-Host $_
        }

        Write-Warning (
            "Es wird bewusst KEIN direkter ASUS-Installer als " +
            "Fallback verwendet. Ein späterer 'just update'-Lauf " +
            "versucht die Winget-Installation erneut."
        )

        return
    }

    Start-Sleep -Seconds 2

    $installation = Get-AsusArmouryCrateInstallation

    if (-not $installation.Installed) {
        Write-Warning (
            "Winget meldete Erfolg, Armoury Crate konnte danach " +
            "aber noch nicht über AppX/Registry/StartApps/Service " +
            "erkannt werden."
        )

        return
    }

    $versionText = if ($installation.Version) {
        " Version $($installation.Version)"
    }
    else {
        ""
    }

    Write-Host (
        "[OK] ASUS Armoury Crate installiert.{0} " +
        "(Erkennung: {1})" `
            -f $versionText, $installation.Source
    ) -ForegroundColor Green
}

function Get-AsusSystemFirmwareSummary {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $baseBoard = Get-CimInstance `
        -ClassName Win32_BaseBoard |
    Select-Object -First 1

    $bios = Get-CimInstance `
        -ClassName Win32_BIOS |
    Select-Object -First 1

    $biosReleaseDate = if ($bios.ReleaseDate) {
        $bios.ReleaseDate.ToString("yyyy-MM-dd")
    }
    else {
        "unbekannt"
    }

    return [PSCustomObject]@{
        Manufacturer    = $baseBoard.Manufacturer
        Motherboard     = $baseBoard.Product
        BoardVersion    = $baseBoard.Version
        BiosVendor      = $bios.Manufacturer
        BiosVersion     = $bios.SMBIOSBIOSVersion
        BiosReleaseDate = $biosReleaseDate
    }
}

function Open-AsusArmouryCrate {
    [CmdletBinding()]
    param()

    Write-Step "ASUS / Armoury Crate Update-Prüfung"

    $installation = Get-AsusArmouryCrateInstallation

    if (-not $installation.Installed) {
        throw (
            "ASUS Armoury Crate ist nicht installiert. " +
            "Zuerst 'just update' ausführen."
        )
    }

    $versionText = if ($installation.Version) {
        $installation.Version
    }
    else {
        "unbekannt"
    }

    Write-Host (
        "[OK] ASUS Armoury Crate installiert: {0} " +
        "(Erkennung: {1})" `
            -f $versionText, $installation.Source
    ) -ForegroundColor Green

    $firmware = Get-AsusSystemFirmwareSummary

    Write-Host ""
    Write-Host "Aktueller ASUS-Systemstand:"
    Write-Host "  Hersteller:   $($firmware.Manufacturer)"
    Write-Host "  Mainboard:     $($firmware.Motherboard)"
    Write-Host "  Board-Version: $($firmware.BoardVersion)"
    Write-Host "  BIOS-Anbieter: $($firmware.BiosVendor)"
    Write-Host "  BIOS-Version:  $($firmware.BiosVersion)"
    Write-Host "  BIOS-Datum:    $($firmware.BiosReleaseDate)"

    Write-Host ""
    Write-Host "In Armoury Crate bitte bewusst prüfen:" `
        -ForegroundColor Yellow
    Write-Host (
        "  1. Einstellungen -> Update Center -> " +
        "Nach Updates suchen."
    )
    Write-Host (
        "  2. ASUS-/Drittanbieter-Treiber und Firmware prüfen, " +
        "z. B. Realtek."
    )
    Write-Host (
        "  3. Intel-Treiber dort NICHT übernehmen. " +
        "Intel DSA bleibt dafür zuständig."
    )
    Write-Host (
        "  4. BIOS/UEFI-Angebot für dieses Mainboard prüfen. " +
        "Falls Armoury Crate zu ASUS DriverHub weiterleitet, " +
        "diesen offiziellen ASUS-Pfad verwenden."
    )
    Write-Host (
        "  5. BIOS/Firmware wird von windows-setup nicht " +
        "automatisch geflasht."
    )

    $getStartApps = Get-Command `
        -Name Get-StartApps `
        -ErrorAction SilentlyContinue

    if (-not $getStartApps) {
        Write-Warning (
            "Get-StartApps ist nicht verfügbar. " +
            "Öffne den Windows-App-Ordner als Fallback."
        )

        Start-Process `
            -FilePath (Join-Path $env:SystemRoot "explorer.exe") `
            -ArgumentList "shell:AppsFolder"

        return
    }

    $apps = @(
        Get-StartApps |
        Where-Object {
            $_.Name -match "(?i)Armoury\s*Crate"
        }
    )

    if ($apps.Count -eq 0) {
        Write-Warning (
            "Armoury Crate wurde in den registrierten Start-Apps " +
            "nicht gefunden. Öffne den Windows-App-Ordner."
        )

        Start-Process `
            -FilePath (Join-Path $env:SystemRoot "explorer.exe") `
            -ArgumentList "shell:AppsFolder"

        return
    }

    $exact = @(
        $apps |
        Where-Object {
            $_.Name -ieq "Armoury Crate"
        }
    )

    $app = if ($exact.Count -gt 0) {
        $exact[0]
    }
    else {
        $apps[0]
    }

    Start-Process `
        -FilePath (Join-Path $env:SystemRoot "explorer.exe") `
        -ArgumentList "shell:AppsFolder\$($app.AppID)"

    Write-Host "[OK] Armoury Crate geöffnet." -ForegroundColor Green
}
