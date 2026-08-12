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
