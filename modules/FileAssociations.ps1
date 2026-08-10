function Get-AppxApplicationProgId {
    param(
        [Parameter(Mandatory)]
        [string]$PackageName
    )

    $package = Get-AppxPackage `
        -Name $PackageName `
        -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending |
    Select-Object -First 1

    if (-not $package) {
        return $null
    }

    $packageFamilyName = $package.PackageFamilyName

    foreach (
        $progIdKey in Get-ChildItem `
            -Path "Registry::HKEY_CLASSES_ROOT" `
            -ErrorAction SilentlyContinue
    ) {
        if ($progIdKey.PSChildName -notlike "AppX*") {
            continue
        }

        $applicationPath = Join-Path `
            $progIdKey.PSPath `
            "Application"

        if (-not (Test-Path $applicationPath)) {
            continue
        }

        $application = Get-ItemProperty `
            -Path $applicationPath `
            -ErrorAction SilentlyContinue

        $appUserModelId = [string]$application.AppUserModelID

        if ([string]::IsNullOrWhiteSpace($appUserModelId)) {
            continue
        }

        if (
            $appUserModelId.StartsWith(
                "$packageFamilyName!",
                [System.StringComparison]::OrdinalIgnoreCase
            )
        ) {
            return $progIdKey.PSChildName
        }
    }

    return $null
}


function Open-WindowsSettingsAndWait {
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [string]$Description = "Windows Einstellungen"
    )

    if (-not ("WindowsSetup.SettingsWindow" -as [type])) {
        Add-Type @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace WindowsSetup
{
    public static class SettingsWindow
    {
        private delegate bool EnumWindowsProc(
            IntPtr hWnd,
            IntPtr lParam
        );

        [DllImport("user32.dll")]
        private static extern bool EnumWindows(
            EnumWindowsProc lpEnumFunc,
            IntPtr lParam
        );

        [DllImport("user32.dll")]
        private static extern bool EnumChildWindows(
            IntPtr hWndParent,
            EnumWindowsProc lpEnumFunc,
            IntPtr lParam
        );

        [DllImport("user32.dll")]
        private static extern bool IsWindowVisible(
            IntPtr hWnd
        );

        [DllImport("user32.dll")]
        private static extern uint GetWindowThreadProcessId(
            IntPtr hWnd,
            out uint lpdwProcessId
        );

        private static bool IsSystemSettingsProcess(
            IntPtr hWnd
        )
        {
            uint processId;

            GetWindowThreadProcessId(
                hWnd,
                out processId
            );

            if (processId == 0)
            {
                return false;
            }

            try
            {
                using (
                    Process process =
                        Process.GetProcessById((int)processId)
                )
                {
                    return string.Equals(
                        process.ProcessName,
                        "SystemSettings",
                        StringComparison.OrdinalIgnoreCase
                    );
                }
            }
            catch
            {
                return false;
            }
        }

        private static bool ContainsSystemSettingsChild(
            IntPtr parentWindow
        )
        {
            bool found = false;

            EnumChildWindows(
                parentWindow,
                delegate(IntPtr childWindow, IntPtr lParam)
                {
                    if (IsSystemSettingsProcess(childWindow))
                    {
                        found = true;
                        return false;
                    }

                    return true;
                },
                IntPtr.Zero
            );

            return found;
        }

        public static bool IsOpen()
        {
            bool found = false;

            EnumWindows(
                delegate(IntPtr topLevelWindow, IntPtr lParam)
                {
                    if (!IsWindowVisible(topLevelWindow))
                    {
                        return true;
                    }

                    if (
                        IsSystemSettingsProcess(topLevelWindow) ||
                        ContainsSystemSettingsChild(topLevelWindow)
                    )
                    {
                        found = true;
                        return false;
                    }

                    return true;
                },
                IntPtr.Zero
            );

            return found;
        }
    }
}
"@
    }

    Write-Host ""
    Write-Host (
        "[ACTION] {0} wird geöffnet." `
            -f $Description
    ) -ForegroundColor Cyan

    Write-Host (
        "[INFO] Der Setup-Lauf wird fortgesetzt, " +
        "sobald das Einstellungsfenster geschlossen wurde."
    )

    Start-Process $Uri

    # --------------------------------------------------------
    # Auf das tatsächliche Öffnen der Settings-App warten
    # --------------------------------------------------------

    $settingsOpened = $false

    for ($attempt = 0; $attempt -lt 100; $attempt++) {
        if ([WindowsSetup.SettingsWindow]::IsOpen()) {
            $settingsOpened = $true
            break
        }

        Start-Sleep -Milliseconds 100
    }

    if (-not $settingsOpened) {
        Write-Warning (
            "Das Windows-Einstellungsfenster konnte innerhalb " +
            "von 10 Sekunden nicht erkannt werden."
        )

        return $false
    }

    Write-Host (
        "[WAIT] Windows Einstellungen sind geöffnet."
    ) -ForegroundColor Yellow

    # --------------------------------------------------------
    # Auf das vollständige Schließen warten
    # --------------------------------------------------------

    while ([WindowsSetup.SettingsWindow]::IsOpen()) {
        Start-Sleep -Milliseconds 250
    }

    Write-Host (
        "[OK] Einstellungsfenster geschlossen."
    ) -ForegroundColor Green

    return $true
}
function Open-DefaultAppSettingsAndWait {
    param(
        [Parameter(Mandatory)]
        [string]$DisplayName,

        [string]$AppUserModelId,

        [string]$RegisteredAppUser,

        [string]$RegisteredAppMachine
    )

    $parameterName = $null
    $parameterValue = $null

    if (-not [string]::IsNullOrWhiteSpace($AppUserModelId)) {
        $parameterName = "registeredAUMID"
        $parameterValue = $AppUserModelId
    }
    elseif (-not [string]::IsNullOrWhiteSpace($RegisteredAppUser)) {
        $parameterName = "registeredAppUser"
        $parameterValue = $RegisteredAppUser
    }
    elseif (-not [string]::IsNullOrWhiteSpace($RegisteredAppMachine)) {
        $parameterName = "registeredAppMachine"
        $parameterValue = $RegisteredAppMachine
    }

    if ($parameterName) {
        $encodedValue = [System.Uri]::EscapeDataString(
            $parameterValue
        )

        $uri = (
            "ms-settings:defaultapps?{0}={1}" `
                -f $parameterName, $encodedValue
        )

        return Open-WindowsSettingsAndWait `
            -Uri $uri `
            -Description (
            "Standard-App-Einstellungen für {0}" `
                -f $DisplayName
        )
    }

    Write-Warning (
        "Die direkte Standard-App-Seite für '{0}' " +
        "konnte nicht ermittelt werden." `
            -f $DisplayName
    )

    Write-Host (
        "[INFO] Öffne stattdessen die allgemeine " +
        "Standard-App-Seite."
    )

    Write-Host (
        "[INFO] Bitte dort nach '{0}' suchen und " +
        "die gewünschten Zuordnungen festlegen." `
            -f $DisplayName
    ) -ForegroundColor Yellow

    return Open-WindowsSettingsAndWait `
        -Uri "ms-settings:defaultapps" `
        -Description "Windows Standard-Apps"
}


function Initialize-DefaultAppConfiguration {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$StatePath,

        [string]$AppUserModelId,

        [string]$RegisteredAppUser,

        [string]$RegisteredAppMachine
    )

    if (Test-Path $StatePath) {        Write-Host (
            (
                "[OK] Standard-App-Konfiguration für {0} " +
                "wurde bereits initialisiert."
            ) -f $Name
        ) -ForegroundColor Green

        return
    }

    $settingsCompleted = Open-DefaultAppSettingsAndWait `
        -DisplayName $Name `
        -AppUserModelId $AppUserModelId `
        -RegisteredAppUser $RegisteredAppUser `
        -RegisteredAppMachine $RegisteredAppMachine

    if (-not $settingsCompleted) {
        Write-Warning (
            "Die Standard-App-Konfiguration für '{0}' " +
            "wurde nicht als initialisiert markiert." `
                -f $Name
        )

        return
    }

    $stateDirectory = Split-Path `
        -Path $StatePath `
        -Parent

    if (-not (Test-Path $stateDirectory)) {
        New-Item `
            -ItemType Directory `
            -Path $stateDirectory `
            -Force |
        Out-Null
    }

    New-Item `
        -ItemType File `
        -Path $StatePath `
        -Force |
    Out-Null

    Write-Host (
        (
            "[OK] Standard-App-Konfiguration für {0} " +
            "als initialisiert markiert."
        ) -f $Name
    ) -ForegroundColor Green
}


function Initialize-NanaZipFileAssociations {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " NanaZip Dateizuordnungen"
    Write-Host "========================================"

    $packageName = "40174MouriNaruto.NanaZip"

    $package = Get-AppxPackage `
        -Name $packageName `
        -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending |
    Select-Object -First 1

    if (-not $package) {
        Write-Warning (
            "NanaZip ist nicht als AppX/MSIX-Paket registriert. " +
            "Dateizuordnungen werden übersprungen."
        )

        return
    }

    $progId = Get-AppxApplicationProgId `
        -PackageName $packageName

    $appUserModelId = $null

    if ($progId) {
        Write-Host (
            "[OK] NanaZip ProgID: {0}" `
                -f $progId
        ) -ForegroundColor Green

        $applicationPath = (
            "Registry::HKEY_CLASSES_ROOT\{0}\Application" `
                -f $progId
        )

        $application = Get-ItemProperty `
            -Path $applicationPath `
            -ErrorAction SilentlyContinue

        $appUserModelId = [string]$application.AppUserModelID
    }
    else {
        Write-Warning (
            "Der NanaZip-AppX-ProgID konnte nicht " +
            "ermittelt werden."
        )
    }

    if (-not [string]::IsNullOrWhiteSpace($appUserModelId)) {
        Write-Host (
            "[OK] NanaZip AppUserModelID: {0}" `
                -f $appUserModelId
        ) -ForegroundColor Green
    }
    else {
        Write-Warning (
            "Die NanaZip AppUserModelID konnte nicht " +
            "ermittelt werden."
        )

        Write-Host (
            "[INFO] Die allgemeine Standard-App-Seite " +
            "wird als Fallback verwendet."
        )
    }

    Write-Host ""
    Write-Host (
        "[INFO] Bitte NanaZip als Standard-App für die " +
        "gewünschten Archivformate konfigurieren."
    )

    Write-Host (
        "[INFO] ISO, VHD/VHDX, WIM und ähnliche " +
        "Windows-Image-Formate sollten nicht zwingend " +
        "NanaZip zugeordnet werden."
    )

    $statePath = Join-Path `
        $RepositoryPath `
        ".generated\state\default-apps\nanazip.initialized"

    Initialize-DefaultAppConfiguration `
        -Name "NanaZip" `
        -StatePath $statePath `
        -AppUserModelId $appUserModelId
}
