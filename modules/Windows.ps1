if (-not ("DesktopWallpaperNativeV2" -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class DesktopWallpaperNativeV2
{
    // --------------------------------------------------------
    // COM Interfaces
    // --------------------------------------------------------

    [ComImport]
    [Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IShellItem
    {
    }

    [ComImport]
    [Guid("B63EA76D-1F85-456F-A19C-48159EFA858B")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IShellItemArray
    {
    }

    [ComImport]
    [Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B")]
    [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IDesktopWallpaper
    {
        void SetWallpaper(
            [MarshalAs(UnmanagedType.LPWStr)] string monitorID,
            [MarshalAs(UnmanagedType.LPWStr)] string wallpaper
        );

        [return: MarshalAs(UnmanagedType.LPWStr)]
        string GetWallpaper(
            [MarshalAs(UnmanagedType.LPWStr)] string monitorID
        );

        [return: MarshalAs(UnmanagedType.LPWStr)]
        string GetMonitorDevicePathAt(
            uint monitorIndex
        );

        uint GetMonitorDevicePathCount();

        void GetMonitorRECT(
            [MarshalAs(UnmanagedType.LPWStr)] string monitorID,
            out RECT displayRect
        );

        void SetBackgroundColor(uint color);

        uint GetBackgroundColor();

        void SetPosition(
            DESKTOP_WALLPAPER_POSITION position
        );

        DESKTOP_WALLPAPER_POSITION GetPosition();

        void SetSlideshow(
            [MarshalAs(UnmanagedType.Interface)]
            IShellItemArray items
        );

        [return: MarshalAs(UnmanagedType.Interface)]
        IShellItemArray GetSlideshow();

        void SetSlideshowOptions(
            DESKTOP_SLIDESHOW_OPTIONS options,
            uint slideshowTick
        );

        void GetSlideshowOptions(
            out DESKTOP_SLIDESHOW_OPTIONS options,
            out uint slideshowTick
        );

        void AdvanceSlideshow(
            [MarshalAs(UnmanagedType.LPWStr)] string monitorID,
            DESKTOP_SLIDESHOW_DIRECTION direction
        );

        DESKTOP_SLIDESHOW_STATE GetStatus();

        void Enable(
            [MarshalAs(UnmanagedType.Bool)] bool enable
        );
    }

    // --------------------------------------------------------
    // Structures
    // --------------------------------------------------------

    [StructLayout(LayoutKind.Sequential)]
    private struct RECT
    {
        public int left;
        public int top;
        public int right;
        public int bottom;
    }

    // --------------------------------------------------------
    // Enums
    // --------------------------------------------------------

    private enum DESKTOP_WALLPAPER_POSITION
    {
        CENTER  = 0,
        TILE    = 1,
        STRETCH = 2,
        FIT     = 3,
        FILL    = 4,
        SPAN    = 5
    }

    [Flags]
    private enum DESKTOP_SLIDESHOW_OPTIONS
    {
        NONE          = 0,
        SHUFFLEIMAGES = 1
    }

    private enum DESKTOP_SLIDESHOW_DIRECTION
    {
        FORWARD  = 0,
        BACKWARD = 1
    }

    [Flags]
    private enum DESKTOP_SLIDESHOW_STATE
    {
        ENABLED                    = 0x01,
        SLIDESHOW                  = 0x02,
        DISABLED_BY_REMOTE_SESSION = 0x04
    }

    // --------------------------------------------------------
    // Shell API
    // --------------------------------------------------------

    [DllImport(
        "shell32.dll",
        CharSet = CharSet.Unicode,
        PreserveSig = true
    )]
    private static extern int SHCreateItemFromParsingName(
        string pszPath,
        IntPtr pbc,
        ref Guid riid,
        [MarshalAs(UnmanagedType.Interface)]
        out IShellItem ppv
    );

    [DllImport(
        "shell32.dll",
        PreserveSig = true
    )]
    private static extern int SHCreateShellItemArrayFromShellItem(
        [MarshalAs(UnmanagedType.Interface)]
        IShellItem psi,
        ref Guid riid,
        [MarshalAs(UnmanagedType.Interface)]
        out IShellItemArray ppv
    );

    // --------------------------------------------------------
    // Public helper
    // --------------------------------------------------------

    public static void ConfigureSlideshow(
        string folder,
        uint intervalMilliseconds,
        bool shuffle
    )
    {
        if (String.IsNullOrWhiteSpace(folder))
        {
            throw new ArgumentException(
                "Wallpaper folder must not be empty.",
                "folder"
            );
        }

        if (!System.IO.Directory.Exists(folder))
        {
            throw new System.IO.DirectoryNotFoundException(
                "Wallpaper folder not found: " + folder
            );
        }

        IShellItem shellItem = null;
        IShellItemArray shellArray = null;
        IDesktopWallpaper wallpaper = null;

        try
        {
            Guid shellItemGuid =
                new Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE");

            Guid shellArrayGuid =
                new Guid("B63EA76D-1F85-456F-A19C-48159EFA858B");

            int result = SHCreateItemFromParsingName(
                folder,
                IntPtr.Zero,
                ref shellItemGuid,
                out shellItem
            );

            if (result != 0)
            {
                Marshal.ThrowExceptionForHR(result);
            }

            result = SHCreateShellItemArrayFromShellItem(
                shellItem,
                ref shellArrayGuid,
                out shellArray
            );

            if (result != 0)
            {
                Marshal.ThrowExceptionForHR(result);
            }

            Guid desktopWallpaperClsid =
                new Guid("C2CF3110-460E-4FC1-B9D0-8A1C0C9CC4BD");

            Type desktopWallpaperType =
                Type.GetTypeFromCLSID(
                    desktopWallpaperClsid,
                    true
                );

            object comObject =
                Activator.CreateInstance(
                    desktopWallpaperType
                );

            wallpaper =
                (IDesktopWallpaper)comObject;

            // Wallpaper-Funktion sicher aktivieren
            wallpaper.Enable(true);

            // Ordner als Diashow verwenden
            wallpaper.SetSlideshow(
                shellArray
            );

            DESKTOP_SLIDESHOW_OPTIONS options =
                shuffle
                    ? DESKTOP_SLIDESHOW_OPTIONS.SHUFFLEIMAGES
                    : DESKTOP_SLIDESHOW_OPTIONS.NONE;

            wallpaper.SetSlideshowOptions(
                options,
                intervalMilliseconds
            );

            // Bildfüllung
            wallpaper.SetPosition(
                DESKTOP_WALLPAPER_POSITION.FIT
            );

            // Freie Fläche schwarz
            wallpaper.SetBackgroundColor(
                0x00000000
            );
        }
        finally
        {
            if (wallpaper != null)
            {
                Marshal.ReleaseComObject(
                    wallpaper
                );
            }

            if (shellArray != null)
            {
                Marshal.ReleaseComObject(
                    shellArray
                );
            }

            if (shellItem != null)
            {
                Marshal.ReleaseComObject(
                    shellItem
                );
            }
        }
    }
}
"@
}

function Set-TaskbarPreferences {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Taskleiste"
    Write-Host "========================================"

    $advancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"

    foreach ($path in @(
            $advancedPath,
            $searchPath
        )) {
        if (-not (Test-Path $path)) {
            New-Item `
                -Path $path `
                -Force `
                -ErrorAction Stop | Out-Null
        }
    }

    # Suche
    Write-Host "[CONFIG] Suche ausblenden"

    Set-ItemProperty `
        -Path $searchPath `
        -Name "SearchboxTaskbarMode" `
        -Value 0 `
        -ErrorAction Stop

    # Taskansicht / Aktive Anwendungen
    Write-Host "[CONFIG] Aktive Anwendungen ausblenden"

    Set-ItemProperty `
        -Path $advancedPath `
        -Name "ShowTaskViewButton" `
        -Value 0 `
        -ErrorAction Stop

    # Widgets
    Write-Host "[CONFIG] Widgets deaktivieren"

    $widgetsPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"

    if (-not (Test-Path $widgetsPolicyPath)) {
        New-Item `
            -Path $widgetsPolicyPath `
            -Force `
            -ErrorAction Stop | Out-Null
    }

    New-ItemProperty `
        -Path $widgetsPolicyPath `
        -Name "AllowNewsAndInterests" `
        -PropertyType DWord `
        -Value 0 `
        -Force `
        -ErrorAction Stop | Out-Null

    # Fortsetzen
    Write-Host "[CONFIG] Fortsetzen ausblenden"

    Set-ItemProperty `
        -Path $advancedPath `
        -Name "TaskbarResume" `
        -Value 0 `
        -ErrorAction Stop

    Write-Host "[OK] Taskleisten-Einstellungen gesetzt." `
        -ForegroundColor Green
}

function Clear-WindowsSetupTemp {
    $tempPath = Join-Path $env:TEMP "windows-setup"

    Write-Host ""
    Write-Host "[CLEANUP] Temporäre Setup-Dateien bereinigen..."

    if (Test-Path $tempPath) {
        Remove-Item `
            -Path $tempPath `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }

    New-Item `
        -Path $tempPath `
        -ItemType Directory `
        -Force | Out-Null

    Write-Host "[OK] Temporäre Setup-Dateien bereinigt." `
        -ForegroundColor Green
}

function Set-StartMenuPreferences {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Startmenü & Suche"
    Write-Host "========================================"

    $explorerPolicyPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"

    if (-not (Test-Path $explorerPolicyPath)) {
        New-Item `
            -Path $explorerPolicyPath `
            -Force `
            -ErrorAction Stop | Out-Null
    }

    Write-Host "[CONFIG] Internet-Suche im Startmenü deaktivieren"

    New-ItemProperty `
        -Path $explorerPolicyPath `
        -Name "DisableSearchBoxSuggestions" `
        -PropertyType DWord `
        -Value 1 `
        -Force `
        -ErrorAction Stop | Out-Null

    Write-Host "[OK] Startmenü-Einstellungen gesetzt." `
        -ForegroundColor Green
}

function Set-WindowsTheme {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Windows Design"
    Write-Host "========================================"

    $personalizePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $desktopPath = "HKCU:\Control Panel\Desktop"

    foreach ($path in @(
            $personalizePath,
            $desktopPath
        )) {
        if (-not (Test-Path $path)) {
            New-Item `
                -Path $path `
                -Force `
                -ErrorAction Stop | Out-Null
        }
    }

    # ------------------------------------------------------------
    # Dark Mode
    # ------------------------------------------------------------

    Write-Host "[CONFIG] Dark Mode aktivieren"

    New-ItemProperty `
        -Path $personalizePath `
        -Name "AppsUseLightTheme" `
        -PropertyType DWord `
        -Value 0 `
        -Force `
        -ErrorAction Stop | Out-Null

    New-ItemProperty `
        -Path $personalizePath `
        -Name "SystemUsesLightTheme" `
        -PropertyType DWord `
        -Value 0 `
        -Force `
        -ErrorAction Stop | Out-Null

    # ------------------------------------------------------------
    # Akzentfarbe automatisch aus Hintergrundbild bestimmen
    # ------------------------------------------------------------

    Write-Host "[CONFIG] Akzentfarbe automatisch bestimmen"

    New-ItemProperty `
        -Path $desktopPath `
        -Name "AutoColorization" `
        -PropertyType DWord `
        -Value 1 `
        -Force `
        -ErrorAction Stop | Out-Null

    Write-Host "[OK] Windows Design konfiguriert." `
        -ForegroundColor Green
}

function Restart-WindowsExplorer {
    Write-Host ""
    Write-Host "[RESTART] Windows Explorer wird neu gestartet..."

    Stop-Process `
        -Name explorer `
        -Force `
        -ErrorAction SilentlyContinue


    Write-Host "[OK] Windows Explorer neu gestartet." `
        -ForegroundColor Green
}

function Set-WindowsPowerPreferences {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Energieoptionen"
    Write-Host "========================================"

    Write-Host "[CONFIG] Monitor niemals automatisch ausschalten"
    powercfg /change monitor-timeout-ac 0
    powercfg /change monitor-timeout-dc 0

    Write-Host "[CONFIG] Standby deaktivieren"
    powercfg /change standby-timeout-ac 0
    powercfg /change standby-timeout-dc 0

    Write-Host "[CONFIG] Ruhezustand deaktivieren"
    powercfg /hibernate off

    Write-Host "[OK] Energieoptionen gesetzt." -ForegroundColor Green
}


function Set-WindowsHDR {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " HDR"
    Write-Host "========================================"

    Write-Warning (
        "HDR kann auf diesem System aktuell nicht zuverlässig " +
        "über die Windows DisplayConfig API automatisiert werden."
    )

    Write-Host (
        "[INFO] HDR bitte einmalig über " +
        "'Einstellungen > System > Anzeige > HDR' aktivieren."
    )
}

function Set-WindowsWallpaperSlideshow {
    param(
        [string]$RepositoryUrl = "https://github.com/jayzone91/wallpaper.git",

        [string]$RepositoryPath =
        "$env:USERPROFILE\Pictures\wallpaper",

        [string]$WallpaperSubfolder = "oled",

        [int]$IntervalMinutes = 30,

        [bool]$Shuffle = $true
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Wallpaper"
    Write-Host "========================================"

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw "Git wurde nicht gefunden."
    }

    # ------------------------------------------------------------
    # Repository
    # ------------------------------------------------------------

    if (Test-Path (Join-Path $RepositoryPath ".git")) {
        Write-Host "[UPDATE] Wallpaper-Repository"

        & git `
            -C $RepositoryPath `
            pull `
            --ff-only

        if ($LASTEXITCODE -ne 0) {
            throw "Wallpaper-Repository konnte nicht aktualisiert werden."
        }
    }
    elseif (Test-Path $RepositoryPath) {
        throw (
            "Wallpaper-Ziel existiert bereits, " +
            "ist aber kein Git-Repository: $RepositoryPath"
        )
    }
    else {
        Write-Host "[CLONE] Wallpaper-Repository"

        & git clone `
            --depth 1 `
            $RepositoryUrl `
            $RepositoryPath

        if ($LASTEXITCODE -ne 0) {
            throw "Wallpaper-Repository konnte nicht geklont werden."
        }
    }

    # ------------------------------------------------------------
    # Wallpaper-Ordner
    # ------------------------------------------------------------

    $wallpaperPath = Join-Path `
        $RepositoryPath `
        $WallpaperSubfolder

    if (-not (Test-Path $wallpaperPath)) {
        throw "Wallpaper-Ordner nicht gefunden: $wallpaperPath"
    }

    $images = @(
        Get-ChildItem `
            -Path $wallpaperPath `
            -File |
        Where-Object {
            $_.Extension.ToLowerInvariant() -in @(
                ".jpg",
                ".jpeg",
                ".png",
                ".bmp"
            )
        }
    )

    if ($images.Count -eq 0) {
        throw "Keine Wallpaper in $wallpaperPath gefunden."
    }

    Write-Host "[OK] $($images.Count) Wallpaper gefunden." `
        -ForegroundColor Green

    # ------------------------------------------------------------
    # Windows Diashow
    # ------------------------------------------------------------

    $intervalMilliseconds = [uint32](
        $IntervalMinutes * 60 * 1000
    )

    Write-Host "[CONFIG] Diashow-Ordner: $wallpaperPath"
    Write-Host "[CONFIG] Intervall: $IntervalMinutes Minuten"
    Write-Host "[CONFIG] Zufällige Reihenfolge: $Shuffle"

    $desktopPath = "HKCU:\Control Panel\Desktop"
    $colorsPath = "HKCU:\Control Panel\Colors"

    Set-ItemProperty `
        -Path $desktopPath `
        -Name "WallpaperStyle" `
        -Value "6"

    Set-ItemProperty `
        -Path $desktopPath `
        -Name "TileWallpaper" `
        -Value "0"

    Set-ItemProperty `
        -Path $colorsPath `
        -Name "Background" `
        -Value "0 0 0"

    [DesktopWallpaperNativeV2]::ConfigureSlideshow(
        $wallpaperPath,
        $intervalMilliseconds,
        $Shuffle
    )

    Write-Host "[OK] Wallpaper-Diashow konfiguriert." `
        -ForegroundColor Green
}
