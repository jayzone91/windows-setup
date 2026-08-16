@{
    Mods = @(
        @{
            Id      = "windows-11-taskbar-styler"
            Name    = "Windows 11 Taskbar Styler"
            Enabled = $true

            Settings = @{
                theme = "LiquidGlass"

                controlStyles = @(
                    @{
                        target = "Taskbar.TaskbarFrame"
                        styles = @(
                            "Width=Auto"
                            "MinWidth:=100"
                            "MaxWidth:=1200"
                            "HorizontalAlignment=Center"
                        )
                    }
                    @{
                        target = "Taskbar.TaskbarFrame > Grid#RootGrid"
                        styles = @(
                            "Margin=0,3,12,3"
                            "CornerRadius=18"
                        )
                    }
                )
            }
        }
    )
}