@{
    PackageName       = "Files"
    PackageFamilyName = "Files_1y0xx7n9077q4"
    AppId             = "Files_1y0xx7n9077q4!App"
    AppInstallerUrl   = "https://cdn.files.community/files/stable/Files.Package.appinstaller"

    DesiredSettings = @{
        AppThemeBackdropMaterial               = 3
        AppThemeBackgroundColor                = "#00000000"
        AppThemeAddressBarBackgroundColor      = "#00000001"
        AppThemeToolbarBackgroundColor         = "#00000001"
        AppThemeSidebarBackgroundColor         = "#00000001"
        AppThemeFileAreaBackgroundColor        = "#00000001"
        AppThemeInfoPaneBackgroundColor        = "#00000001"

        DefaultLayoutMode                      = 3
        SyncFolderPreferencesAcrossDirectories = $true

        ShowToolbar                            = $true
        ShowStatusBar                          = $false
        ShowTabActions                         = $false

        IsSidebarOpen                          = $true
        SidebarWidth                           = 240
        ShowPinnedSection                      = $true
        ShowDrivesSection                      = $true
        ShowCloudDrivesSection                 = $true
        ShowNetworkSection                     = $true
        ShowLibrarySection                     = $false
        ShowWslSection                         = $false
        ShowFileTagsSection                    = $false

        ShowQuickAccessWidget                  = $true
        ShowDrivesWidget                       = $true
        ShowNetworkLocationsWidget             = $false
        ShowRecentFilesWidget                  = $false
        ShowFileTagsWidget                     = $false
    }
}
