#pragma once

// Renderer split from macos-lock-keys-notifier.wh.cpp.
// Included after shared globals/helpers are declared.

void ApplyWindowClip() {
    if (!gWindow) return;
    const int width = static_cast<int>(gStyle.width);
    const int height = static_cast<int>(gStyle.height);
    const int radius = static_cast<int>(gStyle.cornerRadius);
    const int diameter = radius * 2;
    HRGN body = CreateRectRgn(
        radius,
        0,
        width - radius,
        height
    );
    HRGN middle = CreateRectRgn(
        0,
        radius,
        width,
        height - radius
    );
    HRGN left = CreateEllipticRgn(
        0,
        0,
        diameter,
        diameter
    );
    HRGN leftBottom = CreateEllipticRgn(
        0,
        height - diameter,
        diameter,
        height
    );
    HRGN right = CreateEllipticRgn(
        width - diameter,
        0,
        width,
        diameter
    );
    HRGN rightBottom = CreateEllipticRgn(
        width - diameter,
        height - diameter,
        width,
        height
    );
    CombineRgn(body, body, middle, RGN_OR);
    CombineRgn(body, body, left, RGN_OR);
    CombineRgn(body, body, leftBottom, RGN_OR);
    CombineRgn(body, body, right, RGN_OR);
    CombineRgn(body, body, rightBottom, RGN_OR);
    DeleteObject(middle);
    DeleteObject(left);
    DeleteObject(leftBottom);
    DeleteObject(right);
    DeleteObject(rightBottom);
    if (SetWindowRgn(gWindow, body, TRUE) == 0) {
        DeleteObject(body);
    }
}

void PositionWindow() {
    MONITORINFO info{sizeof(info)};
    if (!GetMonitorInfoW(ActiveMonitor(), &info)) return;
    const RECT& work = info.rcWork;
    const int width = static_cast<int>(gStyle.width);
    const int height = static_cast<int>(gStyle.height);
    const int x = work.left + ((work.right - work.left) - width) / 2;
    const int y = work.bottom - height - static_cast<int>(gStyle.bottomOffset);
    SetWindowPos(
        gWindow,
        HWND_TOPMOST,
        x,
        y,
        width,
        height,
        SWP_NOACTIVATE | SWP_SHOWWINDOW
    );
    ApplyWindowClip();
}

void ApplyBackdrop(HWND hwnd) {
    BOOL dark = TRUE;
    DwmSetWindowAttribute(
        hwnd,
        DWMWA_USE_IMMERSIVE_DARK_MODE,
        &dark,
        sizeof(dark)
    );
    DWM_SYSTEMBACKDROP_TYPE backdrop = DWMSBT_TRANSIENTWINDOW;
    DwmSetWindowAttribute(
        hwnd,
        DWMWA_SYSTEMBACKDROP_TYPE,
        &backdrop,
        sizeof(backdrop)
    );
    DWM_WINDOW_CORNER_PREFERENCE corners = DWMWCP_ROUND;
    DwmSetWindowAttribute(
        hwnd,
        DWMWA_WINDOW_CORNER_PREFERENCE,
        &corners,
        sizeof(corners)
    );
    COLORREF border = DWMWA_COLOR_NONE;
    DwmSetWindowAttribute(
        hwnd,
        DWMWA_BORDER_COLOR,
        &border,
        sizeof(border)
    );
MARGINS margins{-1, -1, -1, -1};
    DwmExtendFrameIntoClientArea(hwnd, &margins);
    ApplyAcrylicTint(hwnd);
}

void ReleaseDeviceResources() {
    SafeRelease(&gDisabledBrush);
    SafeRelease(&gEnabledBrush);
    SafeRelease(&gNameBrush);
    SafeRelease(&gRenderTarget);
}

HRESULT CreateDeviceResources() {
    if (gRenderTarget) {
        return S_OK;
    }
    RECT rect{};
    GetClientRect(gWindow, &rect);
    const auto properties = D2D1::RenderTargetProperties(
        D2D1_RENDER_TARGET_TYPE_DEFAULT,
        D2D1::PixelFormat(
            DXGI_FORMAT_B8G8R8A8_UNORM,
            D2D1_ALPHA_MODE_PREMULTIPLIED
        )
    );
    HRESULT hr = gD2dFactory->CreateHwndRenderTarget(
        properties,
        D2D1::HwndRenderTargetProperties(
            gWindow,
            D2D1::SizeU(
                rect.right - rect.left,
                rect.bottom - rect.top
            ),
            D2D1_PRESENT_OPTIONS_IMMEDIATELY
        ),
        &gRenderTarget
    );
    if (FAILED(hr)) return hr;
    hr = gRenderTarget->CreateSolidColorBrush(
        D2D1::ColorF(245 / 255.0f, 245 / 255.0f, 247 / 255.0f, 1.0f),
        &gNameBrush
    );
    if (SUCCEEDED(hr)) {
        hr = gRenderTarget->CreateSolidColorBrush(
            D2D1::ColorF(48 / 255.0f, 209 / 255.0f, 88 / 255.0f, 1.0f),
            &gEnabledBrush
        );
    }
    if (SUCCEEDED(hr)) {
        hr = gRenderTarget->CreateSolidColorBrush(
            D2D1::ColorF(174 / 255.0f, 174 / 255.0f, 178 / 255.0f, 1.0f),
            &gDisabledBrush
        );
    }
    if (FAILED(hr)) {
        ReleaseDeviceResources();
    }
    return hr;
}

HRESULT CreateTextResources() {
    SafeRelease(&gStateFormat);
    SafeRelease(&gNameFormat);
    if (!gDwriteFactory) {
        HRESULT hr = DWriteCreateFactory(
            DWRITE_FACTORY_TYPE_SHARED,
            __uuidof(IDWriteFactory),
            reinterpret_cast<IUnknown**>(&gDwriteFactory)
        );
        if (FAILED(hr)) return hr;
    }
    HRESULT hr = gDwriteFactory->CreateTextFormat(
        L"Segoe UI Variable Text",
        nullptr,
        DWRITE_FONT_WEIGHT_MEDIUM,
        DWRITE_FONT_STYLE_NORMAL,
        DWRITE_FONT_STRETCH_NORMAL,
        gStyle.nameFontSize,
        L"",
        &gNameFormat
    );
    if (FAILED(hr)) return hr;
    gNameFormat->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_LEADING);
    gNameFormat->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
    gNameFormat->SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
    hr = gDwriteFactory->CreateTextFormat(
        L"Segoe UI Variable Text",
        nullptr,
        DWRITE_FONT_WEIGHT_SEMI_BOLD,
        DWRITE_FONT_STYLE_NORMAL,
        DWRITE_FONT_STRETCH_NORMAL,
        gStyle.stateFontSize,
        L"",
        &gStateFormat
    );
    if (SUCCEEDED(hr)) {
        gStateFormat->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_TRAILING);
        gStateFormat->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);
        gStateFormat->SetWordWrapping(DWRITE_WORD_WRAPPING_NO_WRAP);
    }
    return hr;
}

void RenderToast() {
    if (FAILED(CreateDeviceResources())) return;
    gRenderTarget->BeginDraw();
    gRenderTarget->SetTextAntialiasMode(
        D2D1_TEXT_ANTIALIAS_MODE_GRAYSCALE
    );
    gRenderTarget->Clear(D2D1::ColorF(0, 0.0f));

    gDisabledBrush->SetColor(
        LockKeysColor(gStyle.glassR, gStyle.glassG, gStyle.glassB)
    );
    gDisabledBrush->SetOpacity(gStyle.surfaceAlpha);
    gRenderTarget->FillRoundedRectangle(
        D2D1::RoundedRect(
            D2D1::RectF(
                1.0f,
                1.0f,
                gStyle.width - 1.0f,
                gStyle.height - 1.0f
            ),
            gStyle.cornerRadius,
            gStyle.cornerRadius
        ),
        gDisabledBrush
    );

    gDisabledBrush->SetColor(D2D1::ColorF(1.0f, 1.0f, 1.0f));
    gDisabledBrush->SetOpacity(gStyle.innerGlowAlpha);
    gRenderTarget->DrawRoundedRectangle(
        D2D1::RoundedRect(
            D2D1::RectF(
                1.5f,
                1.5f,
                gStyle.width - 1.5f,
                gStyle.height - 1.5f
            ),
            gStyle.cornerRadius - 1.0f,
            gStyle.cornerRadius - 1.0f
        ),
        gDisabledBrush,
        0.75f
    );
    const auto nameRect = D2D1::RectF(
        gStyle.nameLeft,
        0.0f,
        gStyle.nameRight,
        gStyle.height
    );
    const auto stateRect = D2D1::RectF(
        gStyle.stateLeft,
        0.0f,
        gStyle.stateRight,
        gStyle.height
    );
    gRenderTarget->DrawTextW(
        gName.c_str(),
        static_cast<UINT32>(gName.size()),
        gNameFormat,
        nameRect,
        gNameBrush
    );
    gRenderTarget->FillEllipse(
        D2D1::Ellipse(
            D2D1::Point2F(gStyle.dotX, gStyle.height / 2.0f),
            gStyle.dotSize,
            gStyle.dotSize
        ),
        gEnabled ? gEnabledBrush : gDisabledBrush
    );
    gRenderTarget->DrawTextW(
        gState.c_str(),
        static_cast<UINT32>(gState.size()),
        gStateFormat,
        stateRect,
        gNameBrush
    );
    gDisabledBrush->SetOpacity(gStyle.borderAlpha); gRenderTarget->DrawRoundedRectangle(D2D1::RoundedRect(D2D1::RectF(0.5f, 0.5f, gStyle.width - 0.5f, gStyle.height - 0.5f), gStyle.cornerRadius, gStyle.cornerRadius), gDisabledBrush, 1.0f);
    gDisabledBrush->SetOpacity(gStyle.highlightAlpha); gRenderTarget->DrawLine(D2D1::Point2F(14.0f, 1.5f), D2D1::Point2F(gStyle.width - 14.0f, 1.5f), gDisabledBrush, 1.0f); gDisabledBrush->SetOpacity(1.0f);
    const HRESULT hr = gRenderTarget->EndDraw();
    if (hr == D2DERR_RECREATE_TARGET) {
        ReleaseDeviceResources();
    }
}
