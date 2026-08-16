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
                height       = 38
                padding      = 10
                cornerRadius = 19

                shadowEnabled = $true
                shadowSize    = 18
                shadowOpacity = 32
                shadowOffsetY = 5
                shadowColor   = "#000000"

                backgroundColor   = "#202024"
                backgroundOpacity = 68
                textColor         = "#F5F5F7"

                borderColor     = "#8E8E93"
                borderThickness = 1

                fontFamily = "Segoe UI"
                fontSize   = 14
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