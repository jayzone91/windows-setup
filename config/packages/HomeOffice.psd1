@{
    HomeOffice = @(
        @{
            Name   = "Remote Desktop Manager"
            Id     = "Devolutions.RemoteDesktopManager"
            Source = "winget"
            Update = $true
        },

        @{
            Name   = "FileZilla Client"
            Id     = "filezilla"
            Source = "chocolatey"
            Update = $true
        },

        @{
            Name   = "Thunderbird ESR"
            Id     = "Mozilla.Thunderbird.ESR"
            Source = "winget"
            Update = $true
        }
    )
}
