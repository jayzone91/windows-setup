@{
    Gaming = @(
        @{
            Name   = "Steam"
            Id     = "Valve.Steam"
            Source = "winget"
            GameLibrary = "Steam"
            Update = $true
        },

        @{
            Name   = "Epic Games Launcher"
            Id     = "EpicGames.EpicGamesLauncher"
            Source = "winget"
            GameLibrary = "Epic"
            Update = $true
        },

        @{
            Name   = "GOG GALAXY"
            Id     = "GOG.Galaxy"
            Source = "winget"
            GameLibrary = "GOG"
            Update = $true
        },

        @{
            Name   = "EA app"
            Id     = "ElectronicArts.EADesktop"
            Source = "winget"
            GameLibrary = "EA"
            Update = $true
        },

        @{
            Name   = "Battle.net"
            Id     = "Blizzard.BattleNet"
            Source = "winget"
            GameLibrary = "BattleNet"
            InstallLocation = "%PROGRAMFILES(X86)%\Battle.net"
            Update = $true
        },

        @{
            Name   = "Ubisoft Connect"
            Id     = "Ubisoft.Connect"
            Source = "winget"
            GameLibrary = "Ubisoft"
            Update = $true
        })
}
