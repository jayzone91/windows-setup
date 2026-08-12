@{
    Mods = @(
@{
            Id      = "lock-keys-notifier"
            Name    = "Lock Keys Notifier"
            Enabled = $true

            Settings = @{
                notifyCapsLock   = $true
                notifyNumLock    = $true
                notifyScrollLock = $true
                notifyInsert     = $false

                suppressFullscreen = $false
                pollElevated       = $true

                layout         = "pill"
                durationMs     = 1500
                monitor        = "active"
                positionAnchor = "bottom-center"
                offsetX        = 0
                offsetY        = 48

                fadeEnabled    = $true
                fadeDurationMs = 150

                soundMode = "none"
                soundFile = ""

                autoSize     = $true
                width        = 124
                height       = 36
                padding      = 9
                cornerRadius = 6

                shadowEnabled = $true
                shadowSize    = 13
                shadowOpacity = 40
                shadowOffsetY = 4
                shadowColor   = "#000000"

                backgroundColor   = "#1e1e2e"
                backgroundOpacity = 95
                textColor         = "#cdd6f4"

                borderColor     = "#cba6f7"
                borderThickness = 1

                fontFamily = "Segoe UI"
                fontSize   = 14
                fontWeight = "semibold"
                fontItalic = $false

                showIcon = $false

                capsAccentColor   = "#a6e3a1"
                numAccentColor    = "#a6e3a1"
                scrollAccentColor = "#a6e3a1"
                insertAccentColor = "#a6e3a1"

                insertDisplayMode = "onoff"
                insertSingleLabel = "pressed"

                labelOn  = "ON"
                labelOff = "OFF"

                nameCaps   = "Caps Lock"
                nameNum    = "Num Lock"
                nameScroll = "Scroll Lock"
                nameInsert = "Insert"
            }
        }
    )
}
