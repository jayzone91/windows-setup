@{
    Mods = @(
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
