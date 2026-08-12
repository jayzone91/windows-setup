@{
    Mods = @(
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
    )
}
