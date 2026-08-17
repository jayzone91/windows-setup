@{
    ComputerName = "Jay-PC"

    Theme        = @{
        AccentColor = "#0A84FF"
    }

    System       = @{
        Sudo          = @{
            Enabled = $true
            Mode    = "normal"
        }
        DeveloperMode = $true
        LongPaths     = $true
    }

    Taskbar      = @{
        AutoHide = $false
    }

    WindowManagement = @{
        Snap = @{
            Enabled = $true
        }
    }

    StartMenu    = @{
        ShowRecentlyAddedApps = $false
        ShowRecentItems       = $false
        ShowRecommendations   = $false
        ShowMostUsedApps      = $true
    }
}
