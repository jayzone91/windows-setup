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
    )
}
