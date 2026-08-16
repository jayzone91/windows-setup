// ==WindhawkMod==
// @id              macos-lock-keys-notifier
// @name            macOS Lock Keys Notifier
// @description     macOS-inspired acrylic OSD for Caps Lock, Num Lock and Scroll Lock
// @version         0.1.9
// @author          windows-setup
// @include         windhawk.exe
// @license         MIT
// @compilerOptions -ldwmapi -ld2d1 -ldwrite -lgdi32 -luser32
// ==/WindhawkMod==
#include <windows.h>
#include <dwmapi.h>
#include <d2d1.h>
#include <dwrite.h>
#include <string>
#include "macos-lock-keys-style.h"
namespace {
enum ACCENT_STATE {
    ACCENT_DISABLED = 0,
    ACCENT_ENABLE_GRADIENT = 1,
    ACCENT_ENABLE_TRANSPARENTGRADIENT = 2,
    ACCENT_ENABLE_BLURBEHIND = 3,
    ACCENT_ENABLE_ACRYLICBLURBEHIND = 4
};
struct ACCENT_POLICY { int AccentState; int AccentFlags; DWORD GradientColor; int AnimationId; };
struct WINDOWCOMPOSITIONATTRIBDATA { int Attrib; PVOID Data; SIZE_T SizeOfData; };
using SetWindowCompositionAttributeFn = BOOL(WINAPI*)(HWND, WINDOWCOMPOSITIONATTRIBDATA*);
constexpr int WCA_ACCENT_POLICY = 19; LockKeysStyle gStyle;
FILETIME gStyleWrite{};
void ApplyAcrylicTint(HWND hwnd) {
    // Windows 11 22H2+: system-drawn Desktop Acrylic for transient UI.
    // Numeric constants keep the mod compatible with older Windhawk SDK headers.
    constexpr DWORD kSystemBackdropType = 38;
    constexpr int kTransientWindow = 3;

    const HRESULT hr = DwmSetWindowAttribute(
        hwnd,
        kSystemBackdropType,
        &kTransientWindow,
        sizeof(kTransientWindow)
    );

    if (SUCCEEDED(hr)) {
        return;
    }

    // Fallback for systems where the modern DWM backdrop isn't available.
    ACCENT_POLICY policy{
        ACCENT_ENABLE_ACRYLICBLURBEHIND,
        2,
        (
            DWORD(LockKeysAlphaByte(gStyle.glassAlpha)) << 24
        ) |
        (DWORD(gStyle.glassB) << 16) |
        (DWORD(gStyle.glassG) << 8) |
        DWORD(gStyle.glassR),
        0
    };

    WINDOWCOMPOSITIONATTRIBDATA data{
        WCA_ACCENT_POLICY,
        &policy,
        sizeof(policy)
    };

    HMODULE user32 = GetModuleHandleW(L"user32.dll");
    if (!user32) {
        return;
    }

    auto setWindowCompositionAttribute =
        reinterpret_cast<SetWindowCompositionAttributeFn>(
            GetProcAddress(
                user32,
                "SetWindowCompositionAttribute"
            )
        );

    if (!setWindowCompositionAttribute) {
        return;
    }

    setWindowCompositionAttribute(hwnd, &data);
}
constexpr UINT WM_LOCK_CHANGED = WM_APP + 1; constexpr UINT TIMER_POLL = 1; constexpr UINT TIMER_HIDE = 2; constexpr int kWidth = 176; constexpr int kHeight = 46; constexpr int kBottomOffset = 112; constexpr int kDurationMs = 1200; HANDLE gThread = nullptr; HANDLE gReady = nullptr; DWORD gThreadId = 0; HWND gWindow = nullptr; HHOOK gHook = nullptr; ID2D1Factory* gD2dFactory = nullptr; IDWriteFactory* gDwriteFactory = nullptr; ID2D1HwndRenderTarget* gRenderTarget = nullptr; ID2D1SolidColorBrush* gNameBrush = nullptr; ID2D1SolidColorBrush* gEnabledBrush = nullptr; ID2D1SolidColorBrush* gDisabledBrush = nullptr; IDWriteTextFormat* gNameFormat = nullptr; IDWriteTextFormat* gStateFormat = nullptr; bool gCaps = false; bool gNum = false; bool gScroll = false;
std::wstring gName;
std::wstring gState;
bool gEnabled = false;
template <typename T>
void SafeRelease(T** value) {
    if (*value) {
        (*value)->Release();
        *value = nullptr;
    }
}
bool ToggleState(int vk) {
    return (GetKeyState(vk) & 1) != 0;
}
void CacheStates() {
    gCaps = ToggleState(VK_CAPITAL);
    gNum = ToggleState(VK_NUMLOCK);
    gScroll = ToggleState(VK_SCROLL);
}
bool* CachedState(int vk) {
    switch (vk) {
        case VK_CAPITAL: return &gCaps;
        case VK_NUMLOCK: return &gNum;
        case VK_SCROLL: return &gScroll;
    }
    return nullptr;
}
const wchar_t* KeyName(int vk) {
    switch (vk) {
        case VK_CAPITAL: return L"Caps Lock";
        case VK_NUMLOCK: return L"Num Lock";
        case VK_SCROLL: return L"Scroll Lock";
    }
    return L"Lock";
}
HMONITOR ActiveMonitor() {
    HWND foreground = GetForegroundWindow();
    if (foreground) {
        return MonitorFromWindow(foreground, MONITOR_DEFAULTTONEAREST);
    }
    POINT cursor{};
    GetCursorPos(&cursor);
    return MonitorFromPoint(cursor, MONITOR_DEFAULTTONEAREST);
}
#include "macos-lock-keys-render.h"
void UpdateToast(int vk) {
    bool* cached = CachedState(vk);
    if (!cached) return;
    const bool state = ToggleState(vk);
    *cached = state;
    gName = KeyName(vk);
    gState = state ? L"ON" : L"OFF";
    gEnabled = state;
    PositionWindow();
    InvalidateRect(gWindow, nullptr, FALSE);
    KillTimer(gWindow, TIMER_HIDE);
    SetTimer(gWindow, TIMER_HIDE, static_cast<UINT>(gStyle.durationMs), nullptr);
}
void PollStates() {
    if (LoadLockKeysStyle(&gStyle, &gStyleWrite, false)) {
        ApplyAcrylicTint(gWindow);
        CreateTextResources();
        ReleaseDeviceResources();
        PositionWindow();
        InvalidateRect(gWindow, nullptr, FALSE);
    }
    const struct {
        int vk;
        bool* cached;
    } keys[] = {
        {VK_CAPITAL, &gCaps},
        {VK_NUMLOCK, &gNum},
        {VK_SCROLL, &gScroll},
    };
    for (const auto& key : keys) {
        const bool current = ToggleState(key.vk);
        if (current != *key.cached) {
            *key.cached = current;
            PostMessageW(gWindow, WM_LOCK_CHANGED, key.vk, 0);
        }
    }
}
LRESULT CALLBACK WindowProc(
    HWND hwnd,
    UINT msg,
    WPARAM wParam,
    LPARAM lParam
) {
    switch (msg) {
        case WM_ERASEBKGND:
            return 1;
        case WM_PAINT: {
            PAINTSTRUCT paint{};
            BeginPaint(hwnd, &paint);
            RenderToast();
            EndPaint(hwnd, &paint);
            return 0;
        }
        case WM_LOCK_CHANGED:
            UpdateToast(static_cast<int>(wParam));
            return 0;
        case WM_TIMER:
            if (wParam == TIMER_POLL) {
                PollStates();
            } else if (wParam == TIMER_HIDE) {
                KillTimer(hwnd, TIMER_HIDE);
                ShowWindow(hwnd, SW_HIDE);
            }
            return 0;
        case WM_DWMCOMPOSITIONCHANGED:
            ApplyBackdrop(hwnd);
            ReleaseDeviceResources();
            InvalidateRect(hwnd, nullptr, FALSE);
            return 0;
        case WM_NCHITTEST:
            return HTTRANSPARENT;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}
LRESULT CALLBACK KeyboardProc(
    int code,
    WPARAM wParam,
    LPARAM lParam
) {
    if (
        code == HC_ACTION &&
        (wParam == WM_KEYUP || wParam == WM_SYSKEYUP)
    ) {
        const auto* data = reinterpret_cast<KBDLLHOOKSTRUCT*>(lParam);
        if (
            data->vkCode == VK_CAPITAL ||
            data->vkCode == VK_NUMLOCK ||
            data->vkCode == VK_SCROLL
        ) {
            PostMessageW(gWindow, WM_LOCK_CHANGED, data->vkCode, 0);
        }
    }
    return CallNextHookEx(gHook, code, wParam, lParam);
}
DWORD WINAPI UiThread(void*) {
    SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
    if (FAILED(D2D1CreateFactory(
        D2D1_FACTORY_TYPE_SINGLE_THREADED,
        &gD2dFactory
    ))) {
        SetEvent(gReady);
        return 1;
    }
    LoadLockKeysStyle(&gStyle, &gStyleWrite, true);
    if (FAILED(CreateTextResources())) {
        SetEvent(gReady);
        return 2;
    }
    const wchar_t* className = L"WindowsSetupMacOSLockKeys";
    WNDCLASSEXW wc{sizeof(wc)};
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    wc.lpszClassName = className;
    if (!RegisterClassExW(&wc)) {
        SetEvent(gReady);
        return 3;
    }
    gWindow = CreateWindowExW(
        WS_EX_TOPMOST |
        WS_EX_TOOLWINDOW |
        WS_EX_NOACTIVATE |
        WS_EX_TRANSPARENT,
        className,
        L"",
        WS_POPUP,
        0,
        0,
        static_cast<int>(gStyle.width),
        static_cast<int>(gStyle.height),
        nullptr,
        nullptr,
        wc.hInstance,
        nullptr
    );
    if (!gWindow) {
        SetEvent(gReady);
        return 4;
    }
    LoadLockKeysStyle(&gStyle, &gStyleWrite, true);
    ApplyBackdrop(gWindow);
CacheStates();
    gHook = SetWindowsHookExW(
        WH_KEYBOARD_LL,
        KeyboardProc,
        GetModuleHandleW(nullptr),
        0
    );
    SetTimer(gWindow, TIMER_POLL, 250, nullptr);
    SetEvent(gReady);
    MSG msg{};
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    if (gHook) {
        UnhookWindowsHookEx(gHook);
        gHook = nullptr;
    }
    KillTimer(gWindow, TIMER_POLL);
    KillTimer(gWindow, TIMER_HIDE);
    ReleaseDeviceResources();
    SafeRelease(&gStateFormat);
    SafeRelease(&gNameFormat);
    SafeRelease(&gDwriteFactory);
    SafeRelease(&gD2dFactory);
    if (gWindow) {
        DestroyWindow(gWindow);
        gWindow = nullptr;
    }
    UnregisterClassW(className, wc.hInstance);
    return 0;
}
}
BOOL Wh_ModInit() {
    gReady = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    if (!gReady) return FALSE;
    gThread = CreateThread(nullptr, 0, UiThread, nullptr, 0, &gThreadId);
    if (!gThread) {
        CloseHandle(gReady);
        gReady = nullptr;
        return FALSE;
    }
    const DWORD wait = WaitForSingleObject(gReady, 5000);
    CloseHandle(gReady);
    gReady = nullptr;
    return (
        wait == WAIT_OBJECT_0 &&
        gWindow != nullptr &&
        gHook != nullptr
    );
}
void Wh_ModUninit() {
    if (gThreadId) {
        PostThreadMessageW(gThreadId, WM_QUIT, 0, 0);
    }
    if (gThread) {
        WaitForSingleObject(gThread, 5000);
        CloseHandle(gThread);
        gThread = nullptr;
    }
    gThreadId = 0;
}
