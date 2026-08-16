#pragma once

#include <windows.h>
#include <d2d1.h>
#include <stdio.h>
#include <string>

struct LockKeysStyle {
    BYTE glassR = 18, glassG = 18, glassB = 22;
    BYTE textR = 245, textG = 245, textB = 247;
    BYTE onR = 48, onG = 209, onB = 88;
    BYTE offR = 142, offG = 142, offB = 147;
    BYTE borderR = 255, borderG = 255, borderB = 255;

    float glassAlpha = 0.22f;
    float surfaceAlpha = 0.10f;
    float innerGlowAlpha = 0.08f;
    float borderAlpha = 0.18f;
    float highlightAlpha = 0.38f;

    float width = 176.0f;
    float height = 46.0f;
    float bottomOffset = 112.0f;
    float cornerRadius = 14.0f;

    float nameLeft = 18.0f;
    float nameRight = 112.0f;
    float stateLeft = 132.0f;
    float stateRight = 160.0f;
    float dotX = 124.0f;
    float dotSize = 3.0f;

    float nameFontSize = 15.0f;
    float stateFontSize = 14.0f;
    float durationMs = 1200.0f;
};

inline std::wstring LockKeysStylePath() {
    wchar_t home[MAX_PATH]{};
    GetEnvironmentVariableW(L"USERPROFILE", home, MAX_PATH);
    return std::wstring(home) +
        L"\\windows-setup\\config\\windhawk\\macos-lock-keys.css";
}

inline std::string LockKeysCssValue(
    const std::string& css,
    const char* key
) {
    const size_t p = css.find(key);
    if (p == std::string::npos) return {};

    const size_t colon = css.find(':', p);
    if (colon == std::string::npos) return {};

    const size_t semicolon = css.find(';', colon);
    const size_t start = css.find_first_not_of(" \t\r\n", colon + 1);
    if (start == std::string::npos) return {};

    const size_t limit =
        semicolon == std::string::npos ? css.size() : semicolon;
    if (limit == 0) return {};

    const size_t end = css.find_last_not_of(" \t\r\n", limit - 1);
    if (end == std::string::npos || end < start) return {};

    return css.substr(start, end - start + 1);
}

inline void LockKeysCssFloat(
    const std::string& css,
    const char* key,
    float* value
) {
    const std::string raw = LockKeysCssValue(css, key);
    if (raw.empty()) return;

    float parsed = 0.0f;
    if (sscanf(raw.c_str(), "%f", &parsed) == 1) {
        *value = parsed;
    }
}

inline void LockKeysCssRgb(
    const std::string& css,
    const char* key,
    BYTE* r,
    BYTE* g,
    BYTE* b
) {
    const std::string raw = LockKeysCssValue(css, key);
    if (raw.size() != 7 || raw[0] != '#') return;

    unsigned rr = 0, gg = 0, bb = 0;
    if (sscanf(raw.c_str() + 1, "%02x%02x%02x", &rr, &gg, &bb) != 3) {
        return;
    }

    *r = static_cast<BYTE>(rr);
    *g = static_cast<BYTE>(gg);
    *b = static_cast<BYTE>(bb);
}

inline bool LoadLockKeysStyle(
    LockKeysStyle* style,
    FILETIME* lastWrite,
    bool force
) {
    const std::wstring path = LockKeysStylePath();
    WIN32_FILE_ATTRIBUTE_DATA attributes{};

    if (!GetFileAttributesExW(
        path.c_str(),
        GetFileExInfoStandard,
        &attributes
    )) {
        return false;
    }

    if (!force &&
        CompareFileTime(&attributes.ftLastWriteTime, lastWrite) == 0) {
        return false;
    }

    HANDLE file = CreateFileW(
        path.c_str(),
        GENERIC_READ,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
        nullptr,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        nullptr
    );
    if (file == INVALID_HANDLE_VALUE) return false;

    const DWORD size = GetFileSize(file, nullptr);
    DWORD read = 0;
    std::string css(size, '\0');

    const BOOL ok =
        size == 0 || ReadFile(file, css.data(), size, &read, nullptr);

    CloseHandle(file);
    if (!ok) return false;

    css.resize(read);

    LockKeysCssRgb(css, "--glass-color", &style->glassR, &style->glassG, &style->glassB);
    LockKeysCssRgb(css, "--text-color", &style->textR, &style->textG, &style->textB);
    LockKeysCssRgb(css, "--on-color", &style->onR, &style->onG, &style->onB);
    LockKeysCssRgb(css, "--off-color", &style->offR, &style->offG, &style->offB);
    LockKeysCssRgb(css, "--border-color", &style->borderR, &style->borderG, &style->borderB);

    LockKeysCssFloat(css, "--glass-alpha", &style->glassAlpha);
    LockKeysCssFloat(css, "--surface-alpha", &style->surfaceAlpha);
    LockKeysCssFloat(css, "--inner-glow-alpha", &style->innerGlowAlpha);
    LockKeysCssFloat(css, "--border-alpha", &style->borderAlpha);
    LockKeysCssFloat(css, "--highlight-alpha", &style->highlightAlpha);

    LockKeysCssFloat(css, "--width", &style->width);
    LockKeysCssFloat(css, "--height", &style->height);
    LockKeysCssFloat(css, "--bottom-offset", &style->bottomOffset);
    LockKeysCssFloat(css, "--corner-radius", &style->cornerRadius);

    LockKeysCssFloat(css, "--name-left", &style->nameLeft);
    LockKeysCssFloat(css, "--name-right", &style->nameRight);
    LockKeysCssFloat(css, "--state-left", &style->stateLeft);
    LockKeysCssFloat(css, "--state-right", &style->stateRight);
    LockKeysCssFloat(css, "--dot-x", &style->dotX);
    LockKeysCssFloat(css, "--dot-size", &style->dotSize);

    LockKeysCssFloat(css, "--name-font-size", &style->nameFontSize);
    LockKeysCssFloat(css, "--state-font-size", &style->stateFontSize);
    LockKeysCssFloat(css, "--duration-ms", &style->durationMs);

    *lastWrite = attributes.ftLastWriteTime;
    return true;
}

inline BYTE LockKeysAlphaByte(float value) {
    if (value < 0.0f) value = 0.0f;
    if (value > 1.0f) value = 1.0f;
    return static_cast<BYTE>(value * 255.0f);
}

inline D2D1_COLOR_F LockKeysColor(
    BYTE r,
    BYTE g,
    BYTE b
) {
    return D2D1::ColorF(
        r / 255.0f,
        g / 255.0f,
        b / 255.0f
    );
}
