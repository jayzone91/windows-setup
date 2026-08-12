@{
    Mods = @(
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
    )
}
