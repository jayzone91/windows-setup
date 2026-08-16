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
                durationMs     = 1200
                monitor        = "active"
                positionAnchor = "bottom-center"
                offsetX        = 0
                offsetY        = 96

                fadeEnabled    = $true
                fadeDurationMs = 180

                soundMode = "none"
                soundFile = ""

                autoSize     = $true
                width        = 128
                height       = 42
                padding      = 10
                cornerRadius = 21

                shadowEnabled = $true
                shadowSize    = 18
                shadowOpacity = 28
                shadowOffsetY = 6
                shadowColor   = "#000000"

                backgroundColor   = "#1C1C1E"
                backgroundOpacity = 72
                textColor         = "#F5F5F7"

                borderColor     = ""
                borderThickness = 0

                fontFamily = "Segoe UI"
                fontSize   = 13
                fontWeight = "semibold"
                fontItalic = $false

                showIcon = $false

                capsAccentColor   = "#30D158"
                numAccentColor    = "#30D158"
                scrollAccentColor = "#30D158"
                insertAccentColor = "#30D158"

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
