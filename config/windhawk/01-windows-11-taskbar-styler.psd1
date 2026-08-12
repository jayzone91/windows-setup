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
    )
}
