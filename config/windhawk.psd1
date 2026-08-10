@{
    Mods = @(
        @{
            Id      = "windows-11-taskbar-styler"
            Name    = "Windows 11 Taskbar Styler"
            Enabled = $true

            Settings = @{
                theme = "RosePine"

                controlStyles = @(
                    @{
                        target = "Taskbar.TaskListLabeledButtonPanel > Border#BackgroundElement"
                        styles = @(
                            "Background:=#333444"
                        )
                    }
                    @{
                        target = "Grid#SystemTrayFrameGrid"
                        styles = @(
                            "Background:=#333444"
                        )
                    }
                    @{
                        target = "Taskbar.TaskListLabeledButtonPanel@CommonStates > Rectangle#RunningIndicator"
                        styles = @(
                            "Height=5"
                            "Width=5"
                            "RadiusX=2.5"
                            "RadiusY=2.5"
                            "StrokeThickness=0"
                            "Stroke=Transparent"
                            "Fill=Transparent"
                            "Fill@InactiveNormal=Transparent"
                            "Fill@InactivePointerOver=Transparent"
                            "Fill@InactivePressed=Transparent"
                            "Fill@ActiveNormal=#cba6f7"
                            "Fill@ActivePointerOver=#cba6f7"
                            "Fill@ActivePressed=#cba6f7"
                            "VerticalAlignment=Bottom"
                            "Margin=0,0,0,2"
                            "Canvas.ZIndex=1"
                        )
                    }
                    @{
                        target = "TextBlock#LabelControl"
                        styles = @(
                            "Foreground=#cdd6f4"
                        )
                    }
                    @{
                        target = "Taskbar.TaskbarBackground#HoverFlyoutBackgroundControl > Grid > Rectangle#BackgroundFill"
                        styles = @(
                            "Fill=#333444"
                        )
                    }
                    @{
                        target = "Taskbar.TaskListButtonPanel#ExperienceToggleButtonRootPanel > Border#BackgroundElement"
                        styles = @(
                            "Background=#333444"
                        )
                    }
                    @{
                        target = "Grid#OverflowRootGrid > Border"
                        styles = @(
                            "Background=#333444"
                        )
                    }
                )
            }
        }

        @{
            Id      = "windows-11-start-menu-styler"
            Name    = "Windows 11 Start Menu Styler"
            Enabled = $true

            Settings = @{
                theme = "RosePine"

                controlStyles = @(
                    @{
                        target = "StartMenu.SearchBoxToggleButton"
                        styles = @(
                            "Background=#313244"
                        )
                    }
                    @{
                        target = "StartDocked.SearchBoxToggleButton"
                        styles = @(
                            "Background=#313244"
                        )
                    }
                    @{
                        target = "Windows.UI.Xaml.Controls.Border#AcrylicBorder"
                        styles = @(
                            "BorderBrush=#45475a"
                            "Background=#1e1e2e"
                        )
                    }
                    @{
                        target = "Windows.UI.Xaml.Controls.FontIcon > Windows.UI.Xaml.Controls.Grid > Windows.UI.Xaml.Controls.TextBlock"
                        styles = @(
                            "Foreground=#f38ba8"
                        )
                    }
                    @{
                        target = "Windows.UI.Xaml.Controls.TextBlock#AppDisplayName"
                        styles = @(
                            "Foreground=#cdd6f4"
                        )
                    }
                    @{
                        target = "Windows.UI.Xaml.Controls.Grid#DroppedFlickerWorkaroundWrapper > Windows.UI.Xaml.Controls.Border#BackgroundBorder"
                        styles = @(
                            "BorderBrush=#1e1e2e"
                            "Background=#313244"
                        )
                    }
                    @{
                        target = "StartDocked.NavigationPaneButton#PowerButton > Windows.UI.Xaml.Controls.Grid > Windows.UI.Xaml.Controls.Border#BackgroundBorder"
                        styles = @(
                            "Background=#313244"
                        )
                    }
                    @{
                        target = "Windows.UI.Xaml.Controls.TextBlock#PlaceholderText"
                        styles = @(
                            "Foreground=#6c7086"
                        )
                    }
                    @{
                        target = "Windows.UI.Xaml.Controls.TextBlock[Text=]"
                        styles = @(
                            "Foreground=#cba6f7"
                        )
                    }
                    @{
                        target = "Windows.UI.Xaml.Controls.Grid#ContentBorder > Windows.UI.Xaml.Controls.Border#BackgroundBorder"
                        styles = @(
                            "Background=#313244"
                        )
                    }
                    @{
                        target = "Windows.UI.Xaml.Controls.TextBlock[Text=]"
                        styles = @(
                            "Foreground=#cba6f7"
                        )
                    }
                    @{
                        target = "Windows.UI.Xaml.Controls.Border#AppBorder"
                        styles = @(
                            "Background=#1e1e2e"
                            "BorderBrush=#45475a"
                        )
                    }
                    @{
                        target = "Windows.UI.Xaml.Controls.Border#TaskbarSearchBackground"
                        styles = @(
                            "BorderBrush=#cba6f7"
                        )
                    }
                )
            }
        }
        @{
            Id      = "windows-11-notification-center-styler"
            Name    = "Windows 11 Notification Center Styler"
            Enabled = $true

            Settings = @{
                theme = "Matter"

                styleConstants = @(
                    'base = <AcrylicBrush TintColor="#1e1e2e" TintOpacity="1" TintLuminosityOpacity="0.6" Opacity = "1" FallbackColor="#1e1e2e" />'
                    'overlay = <AcrylicBrush TintColor="#313244" TintOpacity="1" TintLuminosityOpacity="0.6" FallbackColor="#313244" />'
                    'accentColor = <SolidColorBrush Color="#585b70" Opacity = "1" />'
                    'overlay2 = <AcrylicBrush TintColor="#45475a" TintOpacity="1" TintLuminosityOpacity="0.4" FallbackColor="#45475a" />'
                )

                controlStyles = @(
                    @{
                        target = "Windows.UI.Xaml.Controls.Grid#WeekDayNames"
                        styles = @(
                            'Background := <SolidColorBrush Color="#45475a" Opacity = "0.9" />'
                        )
                    }
                    @{
                        target = "Windows.UI.Xaml.Controls.Grid#RootGrid > Windows.UI.Xaml.Controls.ContentPresenter#ContentPresenter"
                        styles = @(
                            'Background := <SolidColorBrush Color="#585b70" Opacity = "0.65" />'
                        )
                    }
                )
            }
        }
        @{
            Id      = "taskbar-auto-hide-speed"
            Name    = "Taskbar auto-hide speed"
            Enabled = $true

            Settings = @{
                showSpeedup       = 250
                hideSpeedup       = 250
                frameRate         = 90
                oldTaskbarOnWin11 = $false
            }
        }
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
