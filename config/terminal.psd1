@{
    # Windows-Terminal-Zieldatei der stabilen paketierten Version.
    SettingsPath = "%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    # Nach der Initialisierung ist diese Datei die alleinige Source of Truth.
    RepositorySettingsPath = "dotfiles\terminal\settings.json"

    # Verhindert, dass spätere Bootstrap-Läufe die versionierte settings.json
    # erneut aus den Erstwerten erzeugen.
    StateMarkerPath = ".generated\state\default-apps\terminal.initialized"

    # Nur für die erstmalige Erzeugung einer settings.json, falls im Repository
    # noch keine versionierte Terminal-Konfiguration vorhanden ist.
    Initial = @{
        DefaultProfile = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"

        Tabs = @{
            AlwaysShow       = $true
            ShowInTitlebar   = $false
            WidthMode        = "compact"
            UseAcrylicInRow  = $false
        }

        ProfileDefaults = @{
            FontFace    = "JetBrainsMono Nerd Font"
            FontSize    = 11
            ColorScheme = "Catppuccin Mocha"
            CursorShape = "bar"
            UseAcrylic  = $false
            Opacity     = 100
            Padding     = "12, 10, 12, 10"
        }

        HiddenProfiles = @(
            "Windows PowerShell"
            "Command Prompt"
            "Eingabeaufforderung"
        )
    }

    # Die Farben selbst stehen bewusst nicht hier.
    # Das Modul baut dieses Scheme aus config/theme.psd1.
    ColorSchemeName = "Catppuccin Mocha"
}