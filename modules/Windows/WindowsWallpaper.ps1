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

function Set-WindowsWallpaperSlideshow {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingPositionalParameters",
        "",
        Justification = "Git ist ein natives CLI-Programm; die verwendeten Argumente folgen der regulären Git-Syntax."
    )]
    param(
        [string] $RepositoryUrl = "https://github.com/jayzone91/wallpaper.git",

        [string] $RepositoryPath = "$env:USERPROFILE\Pictures\wallpaper",

        [string] $WallpaperSubfolder = "oled",

        [int] $IntervalMinutes = 30,

        [bool] $Shuffle = $true
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Wallpaper"
    Write-Host "========================================"

    $git = Get-Command `
        -Name "git" `
        -ErrorAction SilentlyContinue

    if (-not $git) {
        throw "Git wurde nicht gefunden."
    }

    $repositoryChanged = $false

    if (Test-Path -LiteralPath (Join-Path $RepositoryPath ".git") -PathType Container) {
        $fetchOutput = @(
            & $git.Source -C $RepositoryPath fetch --quiet 2>&1
        )

        if ($LASTEXITCODE -ne 0) {
            throw (
                "Wallpaper-Repository konnte nicht abgefragt werden: {0}" -f
                ($fetchOutput -join " ")
            )
        }

        $localHead = (
            @(
                & $git.Source -C $RepositoryPath rev-parse HEAD 2>$null
            ) -join "`n"
        ).Trim()

        $upstream = (
            @(
                & $git.Source `
                    -C $RepositoryPath `
                    rev-parse `
                    --abbrev-ref `
                    --symbolic-full-name `
                    '@{u}' `
                    2>$null
            ) -join "`n"
        ).Trim()

        if (
            $LASTEXITCODE -ne 0 -or
            [string]::IsNullOrWhiteSpace($upstream)
        ) {
            throw (
                "Wallpaper-Repository besitzt keinen auswertbaren Upstream-Branch."
            )
        }

        $remoteHead = (
            @(
                & $git.Source -C $RepositoryPath rev-parse $upstream 2>$null
            ) -join "`n"
        ).Trim()

        if ($LASTEXITCODE -ne 0 -or -not $remoteHead) {
            throw "Wallpaper-Upstream-Commit konnte nicht ermittelt werden."
        }

        if ($localHead -ne $remoteHead) {
            & $git.Source `
                -C $RepositoryPath `
                merge-base `
                --is-ancestor `
                $localHead `
                $remoteHead

            if ($LASTEXITCODE -ne 0) {
                throw (
                    "Wallpaper-Repository kann nicht per Fast-Forward " +
                    "aktualisiert werden."
                )
            }

            Write-Host "[UPDATE] Wallpaper-Repository"

            & $git.Source `
                -C $RepositoryPath `
                pull `
                --ff-only `
                --quiet

            if ($LASTEXITCODE -ne 0) {
                throw "Wallpaper-Repository konnte nicht aktualisiert werden."
            }

            $repositoryChanged = $true
        }
        else {
            Write-Host "[CURRENT] Wallpaper-Repository ist bereits aktuell." `
                -ForegroundColor Green
        }
    }
    elseif (Test-Path -LiteralPath $RepositoryPath) {
        throw (
            "Wallpaper-Ziel existiert bereits, " +
            "ist aber kein Git-Repository: $RepositoryPath"
        )
    }
    else {
        Write-Host "[CLONE] Wallpaper-Repository"

        & $git.Source clone `
            --depth 1 `
            --quiet `
            $RepositoryUrl `
            $RepositoryPath

        if ($LASTEXITCODE -ne 0) {
            throw "Wallpaper-Repository konnte nicht geklont werden."
        }

        $repositoryChanged = $true
    }

    $wallpaperPath = Join-Path `
        $RepositoryPath `
        $WallpaperSubfolder

    if (-not (Test-Path -LiteralPath $wallpaperPath -PathType Container)) {
        throw "Wallpaper-Ordner nicht gefunden: $wallpaperPath"
    }

    $images = @(
        Get-ChildItem `
            -LiteralPath $wallpaperPath `
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

    $head = (
        @(
            & $git.Source -C $RepositoryPath rev-parse HEAD
        ) -join "`n"
    ).Trim()

    $desiredFingerprint = Get-TextFingerprint `
        -Text (
            "{0}|{1}|{2}|{3}|FIT|0 0 0" -f
            [IO.Path]::GetFullPath($wallpaperPath),
            $IntervalMinutes,
            $Shuffle,
            $head
        )

    $windowsSetupRoot = Split-Path `
        -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -Parent

    $stateDirectory = Join-Path `
        $windowsSetupRoot `
        ".generated\state\windows"

    if (-not (Test-Path -LiteralPath $stateDirectory -PathType Container)) {
        New-Item `
            -ItemType Directory `
            -Path $stateDirectory `
            -Force |
        Out-Null
    }

    $statePath = Join-Path `
        $stateDirectory `
        "wallpaper.sha256"

    $storedFingerprint = $null

    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        $storedFingerprint = (
            Get-Content `
                -LiteralPath $statePath `
                -Raw
        ).Trim()
    }

    $desktopPath = "HKCU:\Control Panel\Desktop"
    $colorsPath = "HKCU:\Control Panel\Colors"

    $wallpaperStyle = Get-ItemPropertyValue `
        -Path $desktopPath `
        -Name "WallpaperStyle" `
        -ErrorAction SilentlyContinue

    $tileWallpaper = Get-ItemPropertyValue `
        -Path $desktopPath `
        -Name "TileWallpaper" `
        -ErrorAction SilentlyContinue

    $background = Get-ItemPropertyValue `
        -Path $colorsPath `
        -Name "Background" `
        -ErrorAction SilentlyContinue

    $settingsChanged = (
        $repositoryChanged -or
        $storedFingerprint -ne $desiredFingerprint -or
        [string]$wallpaperStyle -ne "6" -or
        [string]$tileWallpaper -ne "0" -or
        [string]$background -ne "0 0 0"
    )

    if (-not $settingsChanged) {
        Write-Host "[SKIP] Wallpaper-Diashow unverändert." `
            -ForegroundColor Green

        return $false
    }

    $intervalMilliseconds = [uint32](
        $IntervalMinutes * 60 * 1000
    )

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

    Set-Content `
        -LiteralPath $statePath `
        -Value $desiredFingerprint `
        -Encoding utf8NoBOM `
        -NoNewline

    Write-Host "[OK] Wallpaper-Diashow aktualisiert." `
        -ForegroundColor Green

    return $true
}
