#Requires -Version 7.0

function Start-VolumeOsd {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 10)]
        [int] $StepPercent = 2
    )

    $ErrorActionPreference = "Stop"

    if (-not $IsWindows) {
        throw "Dieser Test ist ausschließlich für Windows vorgesehen."
    }

    if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne "STA") {
        throw (
            "Der Test benötigt einen STA-Thread. Starte ihn mit: " +
            "pwsh -NoProfile -STA -ExecutionPolicy Bypass -File " +
            '".\scripts\Test-OsdVolumePill.ps1"'
        )
    }

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    $source = @'
    using System;
    using System.Collections.Concurrent;
    using System.Diagnostics;
    using System.Runtime.InteropServices;

    namespace WindowsSetupVolumePill
    {
        public sealed class VolumeKeyEvent
        {
            public VolumeKeyEvent(
                uint virtualKey,
                bool injected,
                long timestamp
            )
            {
                VirtualKey = virtualKey;
                Injected = injected;
                Timestamp = timestamp;
            }

            public uint VirtualKey { get; private set; }
            public bool Injected { get; private set; }
            public long Timestamp { get; private set; }
        }

        public static class VolumeKeyboardHook
        {
            private const int WH_KEYBOARD_LL = 13;
            private const int HC_ACTION = 0;

            private const int WM_KEYDOWN = 0x0100;
            private const int WM_KEYUP = 0x0101;
            private const int WM_SYSKEYDOWN = 0x0104;
            private const int WM_SYSKEYUP = 0x0105;

            private const uint VK_VOLUME_MUTE = 0xAD;
            private const uint VK_VOLUME_DOWN = 0xAE;
            private const uint VK_VOLUME_UP = 0xAF;

            private const uint LLKHF_INJECTED = 0x00000010;

            private static readonly ConcurrentQueue<VolumeKeyEvent> Queue =
                new ConcurrentQueue<VolumeKeyEvent>();

            private static readonly LowLevelKeyboardProc Callback =
                HookCallback;

            private static IntPtr hookHandle = IntPtr.Zero;

            public static void Install()
            {
                if (hookHandle != IntPtr.Zero)
                {
                    return;
                }

                IntPtr moduleHandle = GetModuleHandle(null);

                hookHandle = SetWindowsHookEx(
                    WH_KEYBOARD_LL,
                    Callback,
                    moduleHandle,
                    0
                );

                if (hookHandle == IntPtr.Zero)
                {
                    throw new InvalidOperationException(
                        "SetWindowsHookEx(WH_KEYBOARD_LL) fehlgeschlagen. " +
                        "Win32Error=" + Marshal.GetLastWin32Error()
                    );
                }
            }

            public static void Uninstall()
            {
                if (hookHandle == IntPtr.Zero)
                {
                    return;
                }

                UnhookWindowsHookEx(hookHandle);
                hookHandle = IntPtr.Zero;
            }

            public static bool TryDequeue(out VolumeKeyEvent record)
            {
                return Queue.TryDequeue(out record);
            }

            public static double TimestampToMilliseconds(long timestamp)
            {
                return timestamp * 1000.0 / Stopwatch.Frequency;
            }

            public static long CurrentTimestamp()
            {
                return Stopwatch.GetTimestamp();
            }

            private static IntPtr HookCallback(
                int code,
                IntPtr wParam,
                IntPtr lParam
            )
            {
                if (code == HC_ACTION)
                {
                    int message = wParam.ToInt32();

                    bool keyDown =
                        message == WM_KEYDOWN ||
                        message == WM_SYSKEYDOWN;

                    bool keyUp =
                        message == WM_KEYUP ||
                        message == WM_SYSKEYUP;

                    if (keyDown || keyUp)
                    {
                        KbdLlHookStruct data =
                            Marshal.PtrToStructure<KbdLlHookStruct>(
                                lParam
                            );

                        bool isVolumeKey =
                            data.VirtualKey == VK_VOLUME_MUTE ||
                            data.VirtualKey == VK_VOLUME_DOWN ||
                            data.VirtualKey == VK_VOLUME_UP;

                        if (isVolumeKey)
                        {
                            if (keyDown)
                            {
                                bool injected =
                                    (data.Flags & LLKHF_INJECTED) != 0;

                                Queue.Enqueue(
                                    new VolumeKeyEvent(
                                        data.VirtualKey,
                                        injected,
                                        Stopwatch.GetTimestamp()
                                    )
                                );
                            }

                            return new IntPtr(1);
                        }
                    }
                }

                return CallNextHookEx(
                    hookHandle,
                    code,
                    wParam,
                    lParam
                );
            }

            private delegate IntPtr LowLevelKeyboardProc(
                int code,
                IntPtr wParam,
                IntPtr lParam
            );

            [StructLayout(LayoutKind.Sequential)]
            private struct KbdLlHookStruct
            {
                public uint VirtualKey;
                public uint ScanCode;
                public uint Flags;
                public uint Time;
                public UIntPtr ExtraInfo;
            }

            [DllImport(
                "user32.dll",
                SetLastError = true
            )]
            private static extern IntPtr SetWindowsHookEx(
                int hookId,
                LowLevelKeyboardProc callback,
                IntPtr moduleHandle,
                uint threadId
            );

            [DllImport(
                "user32.dll",
                SetLastError = true
            )]
            [return: MarshalAs(UnmanagedType.Bool)]
            private static extern bool UnhookWindowsHookEx(
                IntPtr hookHandle
            );

            [DllImport("user32.dll")]
            private static extern IntPtr CallNextHookEx(
                IntPtr hookHandle,
                int code,
                IntPtr wParam,
                IntPtr lParam
            );

            [DllImport(
                "kernel32.dll",
                CharSet = CharSet.Unicode,
                SetLastError = true
            )]
            private static extern IntPtr GetModuleHandle(
                string moduleName
            );
        }

        public sealed class AudioState
        {
            public AudioState(float volume, bool muted)
            {
                Volume = volume;
                Muted = muted;
            }

            public float Volume { get; private set; }
            public bool Muted { get; private set; }
        }

        public sealed class AudioController : IDisposable
        {
            private const uint CLSCTX_ALL = 23;

            private IMMDeviceEnumerator enumerator;
            private IMMDevice device;
            private IAudioEndpointVolume endpointVolume;
            private bool disposed;

            public AudioController()
            {
                enumerator =
                    (IMMDeviceEnumerator)
                    new MMDeviceEnumerator();

                Marshal.ThrowExceptionForHR(
                    enumerator.GetDefaultAudioEndpoint(
                        EDataFlow.eRender,
                        ERole.eMultimedia,
                        out device
                    )
                );

                Guid iid =
                    typeof(IAudioEndpointVolume).GUID;

                object activated;

                Marshal.ThrowExceptionForHR(
                    device.Activate(
                        ref iid,
                        CLSCTX_ALL,
                        IntPtr.Zero,
                        out activated
                    )
                );

                endpointVolume =
                    (IAudioEndpointVolume)activated;
            }

            public AudioState Read()
            {
                float volume;
                bool muted;

                Marshal.ThrowExceptionForHR(
                    endpointVolume.GetMasterVolumeLevelScalar(
                        out volume
                    )
                );

                Marshal.ThrowExceptionForHR(
                    endpointVolume.GetMute(
                        out muted
                    )
                );

                return new AudioState(volume, muted);
            }

            public AudioState Adjust(float delta)
            {
                AudioState current = Read();

                float next =
                    Math.Max(
                        0.0f,
                        Math.Min(
                            1.0f,
                            current.Volume + delta
                        )
                    );

                Guid context = Guid.Empty;

                Marshal.ThrowExceptionForHR(
                    endpointVolume.SetMasterVolumeLevelScalar(
                        next,
                        ref context
                    )
                );

                return Read();
            }

            public AudioState ToggleMute()
            {
                AudioState current = Read();
                Guid context = Guid.Empty;

                Marshal.ThrowExceptionForHR(
                    endpointVolume.SetMute(
                        !current.Muted,
                        ref context
                    )
                );

                return Read();
            }

            public void Dispose()
            {
                if (disposed)
                {
                    return;
                }

                disposed = true;

                ReleaseComObject(endpointVolume);
                ReleaseComObject(device);
                ReleaseComObject(enumerator);

                endpointVolume = null;
                device = null;
                enumerator = null;
            }

            private static void ReleaseComObject(object value)
            {
                if (
                    value != null &&
                    Marshal.IsComObject(value)
                )
                {
                    Marshal.FinalReleaseComObject(value);
                }
            }

            private enum EDataFlow
            {
                eRender = 0,
                eCapture = 1,
                eAll = 2
            }

            private enum ERole
            {
                eConsole = 0,
                eMultimedia = 1,
                eCommunications = 2
            }

            [ComImport]
            [Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
            private class MMDeviceEnumerator
            {
            }

            [ComImport]
            [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6")]
            [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
            private interface IMMDeviceEnumerator
            {
                [PreserveSig]
                int EnumAudioEndpoints(
                    EDataFlow dataFlow,
                    uint stateMask,
                    out IntPtr devices
                );

                [PreserveSig]
                int GetDefaultAudioEndpoint(
                    EDataFlow dataFlow,
                    ERole role,
                    out IMMDevice endpoint
                );

                [PreserveSig]
                int GetDevice(
                    [MarshalAs(UnmanagedType.LPWStr)]
                    string id,
                    out IMMDevice device
                );

                [PreserveSig]
                int RegisterEndpointNotificationCallback(
                    IntPtr client
                );

                [PreserveSig]
                int UnregisterEndpointNotificationCallback(
                    IntPtr client
                );
            }

            [ComImport]
            [Guid("D666063F-1587-4E43-81F1-B948E807363F")]
            [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
            private interface IMMDevice
            {
                [PreserveSig]
                int Activate(
                    ref Guid iid,
                    uint clsCtx,
                    IntPtr activationParams,
                    [MarshalAs(UnmanagedType.IUnknown)]
                    out object interfacePointer
                );

                [PreserveSig]
                int OpenPropertyStore(
                    uint access,
                    out IntPtr properties
                );

                [PreserveSig]
                int GetId(
                    [MarshalAs(UnmanagedType.LPWStr)]
                    out string id
                );

                [PreserveSig]
                int GetState(out uint state);
            }

            [ComImport]
            [Guid("5CDF2C82-841E-4546-9722-0CF74078229A")]
            [InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
            private interface IAudioEndpointVolume
            {
                [PreserveSig]
                int RegisterControlChangeNotify(IntPtr notify);

                [PreserveSig]
                int UnregisterControlChangeNotify(IntPtr notify);

                [PreserveSig]
                int GetChannelCount(out uint channelCount);

                [PreserveSig]
                int SetMasterVolumeLevel(
                    float levelDb,
                    ref Guid eventContext
                );

                [PreserveSig]
                int SetMasterVolumeLevelScalar(
                    float level,
                    ref Guid eventContext
                );

                [PreserveSig]
                int GetMasterVolumeLevel(out float levelDb);

                [PreserveSig]
                int GetMasterVolumeLevelScalar(out float level);

                [PreserveSig]
                int SetChannelVolumeLevel(
                    uint channel,
                    float levelDb,
                    ref Guid eventContext
                );

                [PreserveSig]
                int SetChannelVolumeLevelScalar(
                    uint channel,
                    float level,
                    ref Guid eventContext
                );

                [PreserveSig]
                int GetChannelVolumeLevel(
                    uint channel,
                    out float levelDb
                );

                [PreserveSig]
                int GetChannelVolumeLevelScalar(
                    uint channel,
                    out float level
                );

                [PreserveSig]
                int SetMute(
                    [MarshalAs(UnmanagedType.Bool)]
                    bool muted,
                    ref Guid eventContext
                );

                [PreserveSig]
                int GetMute(
                    [MarshalAs(UnmanagedType.Bool)]
                    out bool muted
                );
            }
        }
    }
'@

    Add-Type `
        -TypeDefinition $source `
        -Language CSharp

    function New-SolidBrush {
        [CmdletBinding()]
        [OutputType([System.Windows.Media.SolidColorBrush])]
        param(
            [Parameter(Mandatory)]
            [ValidatePattern("^#[0-9A-Fa-f]{6}$")]
            [string] $Color
        )

        return [System.Windows.Media.SolidColorBrush]::new(
            [System.Windows.Media.ColorConverter]::ConvertFromString(
                $Color
            )
        )
    }

    function Get-ActiveScreenWorkArea {
        [CmdletBinding()]
        param()

        Add-Type -AssemblyName System.Windows.Forms

        $screen =
            [System.Windows.Forms.Screen]::FromPoint(
                [System.Windows.Forms.Cursor]::Position
            )

        return $screen.WorkingArea
    }

    $themePath = Join-Path `
        $PSScriptRoot `
        "..\config\theme.psd1"

    $themePath =
        [System.IO.Path]::GetFullPath(
            $themePath
        )

    if (-not (Test-Path -LiteralPath $themePath -PathType Leaf)) {
        throw "Theme-Konfiguration nicht gefunden: $themePath"
    }

    $theme = Import-PowerShellDataFile `
        -Path $themePath

    $window = [System.Windows.Window]::new()
    $window.WindowStyle =
        [System.Windows.WindowStyle]::None
    $window.ResizeMode =
        [System.Windows.ResizeMode]::NoResize
    $window.ShowInTaskbar = $false
    $window.ShowActivated = $false
    $window.Topmost = $true
    $window.AllowsTransparency = $true
    $window.Background =
        [System.Windows.Media.Brushes]::Transparent
    $window.SizeToContent =
        [System.Windows.SizeToContent]::WidthAndHeight
    $window.WindowStartupLocation =
        [System.Windows.WindowStartupLocation]::Manual
    $window.Opacity = 0

    $shadow =
        [System.Windows.Media.Effects.DropShadowEffect]::new()

    $shadow.BlurRadius = 13
    $shadow.Opacity = 0.40
    $shadow.ShadowDepth = 4
    $shadow.Direction = 270
    $shadow.Color =
        [System.Windows.Media.ColorConverter]::ConvertFromString(
            "#000000"
        )

    $outer =
        [System.Windows.Controls.Border]::new()

    $outer.Background =
        New-SolidBrush `
            -Color $theme.Colors.Base

    $outer.BorderBrush =
        New-SolidBrush `
            -Color $theme.Colors.Mauve

    $outer.BorderThickness =
        [System.Windows.Thickness]::new(1)

    $outer.CornerRadius =
        [System.Windows.CornerRadius]::new(6)

    $outer.Padding =
        [System.Windows.Thickness]::new(
            9,
            0,
            8,
            0
        )

    $outer.Height = 36
    $outer.Effect = $shadow
    $outer.Opacity = 0.95

    $grid =
        [System.Windows.Controls.Grid]::new()

    $titleColumn =
        [System.Windows.Controls.ColumnDefinition]::new()

    $titleColumn.Width =
        [System.Windows.GridLength]::Auto

    $gapColumn =
        [System.Windows.Controls.ColumnDefinition]::new()

    $gapColumn.Width =
        [System.Windows.GridLength]::new(10)

    $valueColumn =
        [System.Windows.Controls.ColumnDefinition]::new()

    $valueColumn.Width =
        [System.Windows.GridLength]::Auto

    [void] $grid.ColumnDefinitions.Add($titleColumn)
    [void] $grid.ColumnDefinitions.Add($gapColumn)
    [void] $grid.ColumnDefinitions.Add($valueColumn)

    $title =
        [System.Windows.Controls.TextBlock]::new()

    $title.Text = "Volume"
    $title.Foreground =
        New-SolidBrush `
            -Color $theme.Colors.Text

    $title.FontFamily =
        [System.Windows.Media.FontFamily]::new(
            "Segoe UI"
        )

    $title.FontSize = 14
    $title.FontWeight =
        [System.Windows.FontWeights]::SemiBold

    $title.VerticalAlignment =
        [System.Windows.VerticalAlignment]::Center

    [System.Windows.Controls.Grid]::SetColumn(
        $title,
        0
    )

    $valueBorder =
        [System.Windows.Controls.Border]::new()

    $valueBorder.Background =
        New-SolidBrush `
            -Color $theme.Colors.Green

    $valueBorder.CornerRadius =
        [System.Windows.CornerRadius]::new(11)

    $valueBorder.Padding =
        [System.Windows.Thickness]::new(
            9,
            2,
            9,
            2
        )

    # Feste Mindestbreite verhindert Layout-Sprünge zwischen z. B.
    # "8%", "100%" und "MUTE".
    $valueBorder.MinWidth = 48

    $valueBorder.VerticalAlignment =
        [System.Windows.VerticalAlignment]::Center

    [System.Windows.Controls.Grid]::SetColumn(
        $valueBorder,
        2
    )

    $value =
        [System.Windows.Controls.TextBlock]::new()

    $value.Text = "20%"
    $value.Foreground =
        New-SolidBrush `
            -Color $theme.Colors.Base

    $value.FontFamily =
        [System.Windows.Media.FontFamily]::new(
            "Segoe UI"
        )

    $value.FontSize = 12
    $value.FontWeight =
        [System.Windows.FontWeights]::SemiBold

    $value.HorizontalAlignment =
        [System.Windows.HorizontalAlignment]::Center

    $value.VerticalAlignment =
        [System.Windows.VerticalAlignment]::Center

    $valueBorder.Child = $value

    [void] $grid.Children.Add($title)
    [void] $grid.Children.Add($valueBorder)

    $outer.Child = $grid
    $window.Content = $outer

    $fadeIn =
        [System.Windows.Media.Animation.DoubleAnimation]::new()

    $fadeIn.From = 0
    $fadeIn.To = 1
    $fadeIn.Duration =
        [System.Windows.Duration]::new(
            [TimeSpan]::FromMilliseconds(150)
        )

    $fadeOut =
        [System.Windows.Media.Animation.DoubleAnimation]::new()

    $fadeOut.From = 1
    $fadeOut.To = 0
    $fadeOut.Duration =
        [System.Windows.Duration]::new(
            [TimeSpan]::FromMilliseconds(150)
        )

    function Set-WindowPosition {
        [CmdletBinding()]
        param()

        $workArea = Get-ActiveScreenWorkArea

        $window.Measure(
            [System.Windows.Size]::new(
                [double]::PositiveInfinity,
                [double]::PositiveInfinity
            )
        )

        $width = $window.DesiredSize.Width
        $height = $window.DesiredSize.Height

        $window.Left =
            $workArea.Left +
            (($workArea.Width - $width) / 2)

        $window.Top =
            $workArea.Bottom -
            $height -
            48
    }

    $script:OsdIsFadingOut = $false
    $script:OsdHideCompleteAt = [DateTime]::MaxValue

    function Show-VolumePill {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [int] $Percent,

            [Parameter(Mandatory)]
            [bool] $Muted
        )

        # Solange das OSD sichtbar ist, wird ausschließlich der dargestellte
        # Zustand aktualisiert. Das Fenster selbst bleibt bestehen.
        $title.Text = "Volume"

        if ($Muted) {
            $value.Text = "MUTE"

            $valueBorder.Background =
                New-SolidBrush `
                    -Color $theme.Colors.Red
        }
        else {
            $value.Text = "$Percent%"

            $valueBorder.Background =
                New-SolidBrush `
                    -Color $theme.Colors.Green
        }

        if ($window.IsVisible) {
            # Falls genau während des Fade-outs ein neuer Lautstärke-Event kommt,
            # Fade-out abbrechen und das bestehende Fenster weiterverwenden.
            if ($script:OsdIsFadingOut) {
                $window.BeginAnimation(
                    [System.Windows.Window]::OpacityProperty,
                    $null
                )

                $window.Opacity = 1
                $script:OsdIsFadingOut = $false
                $script:OsdHideCompleteAt = [DateTime]::MaxValue
            }

            return
        }

        # Nur beim ersten Event eines neuen Bursts positionieren, anzeigen
        # und einmalig einblenden.
        Set-WindowPosition

        $window.BeginAnimation(
            [System.Windows.Window]::OpacityProperty,
            $null
        )

        $window.Opacity = 0
        $window.Show()

        $window.BeginAnimation(
            [System.Windows.Window]::OpacityProperty,
            $fadeIn
        )
    }

    function Start-HideVolumePill {
        [CmdletBinding()]
        param()

        if (
            -not $window.IsVisible -or
            $script:OsdIsFadingOut
        ) {
            return
        }

        $script:OsdIsFadingOut = $true
        $script:OsdHideCompleteAt =
            [DateTime]::UtcNow.AddMilliseconds(150)

        $window.BeginAnimation(
            [System.Windows.Window]::OpacityProperty,
            $fadeOut
        )
    }

    function Complete-HideVolumePill {
        [CmdletBinding()]
        param()

        if (
            -not $script:OsdIsFadingOut -or
            [DateTime]::UtcNow -lt
            $script:OsdHideCompleteAt
        ) {
            return
        }

        $window.BeginAnimation(
            [System.Windows.Window]::OpacityProperty,
            $null
        )

        $window.Hide()
        $window.Opacity = 0

        $script:OsdIsFadingOut = $false
        $script:OsdHideCompleteAt = [DateTime]::MaxValue
    }

    $mutexCreated = $false
    $mutex = [System.Threading.Mutex]::new(
        $true,
        "Local\WindowsSetupVolumeOsd",
        [ref] $mutexCreated
    )

    if (-not $mutexCreated) {
        $mutex.Dispose()
        exit 0
    }

    $audio = $null
    $step =
        [float] ($StepPercent / 100.0)

    $hideAt = [DateTime]::MaxValue

    try {
        $audio =
            [WindowsSetupVolumePill.AudioController]::new()

        [WindowsSetupVolumePill.VolumeKeyboardHook]::Install()

        while ($true) {
            $window.Dispatcher.Invoke(
                [action] {},
                [System.Windows.Threading.DispatcherPriority]::Background
            )

            $record = $null

            while (
                [WindowsSetupVolumePill.VolumeKeyboardHook]::
                    TryDequeue([ref] $record)
            ) {
                switch ($record.VirtualKey) {
                    0xAD {
                        $state = $audio.ToggleMute()
                    }

                    0xAE {
                        $state = $audio.Adjust(-$step)
                    }

                    0xAF {
                        $state = $audio.Adjust($step)
                    }

                    default {
                        continue
                    }
                }

                $percent =
                    [int] [Math]::Round(
                        $state.Volume * 100
                    )

                Show-VolumePill `
                    -Percent $percent `
                    -Muted $state.Muted

                $hideAt =
                    [DateTime]::UtcNow.AddMilliseconds(
                        1500
                    )
            }

            if (
                $window.IsVisible -and
                -not $script:OsdIsFadingOut -and
                [DateTime]::UtcNow -ge
                $hideAt
            ) {
                Start-HideVolumePill
                $hideAt = [DateTime]::MaxValue
            }

            Complete-HideVolumePill

            Start-Sleep -Milliseconds 5
        }
    }
    finally {
        [WindowsSetupVolumePill.VolumeKeyboardHook]::Uninstall()

        if ($audio) {
            $audio.Dispose()
        }

        if ($window.IsVisible) {
            $window.Close()
        }

        if ($mutex) {
            if ($mutexCreated) {
                $mutex.ReleaseMutex()
            }

            $mutex.Dispose()
        }
    }
}