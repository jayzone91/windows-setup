@{
    Release = @{
        Repository = "ramensoftware/windhawk"
        TagPattern = "^2\.0\.0-alpha\.\d+$"
        AssetName  = "windhawk_setup.exe"
    }

    Mod = @{
        Id                = "icon-resource-redirect"
        ThemeRelativePath = "dotfiles\windhawk\themes\macos-27"
        Settings          = @(
            @{
                Key   = "iconTheme"
                Value = ""
            },
            @{
                Key   = "disableThumbnails"
                Value = "1"
            },
            @{
                Key   = "allResourceRedirect"
                Value = "0"
            },
            @{
                Key   = "themePaths[0]"
                Value = "{THEME_PATH}"
            },
            @{
                Key   = "redirectionResourcePaths[0].original"
                Value = ""
            },
            @{
                Key   = "redirectionResourcePaths[0].redirect"
                Value = ""
            },
            @{
                Key   = "themeFolder"
                Value = ""
            }
        )
    }
}