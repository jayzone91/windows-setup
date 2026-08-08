@{
    Base        = @(
        @{
            Id     = "DEVCOM.JetBrainsMonoNerdFont"
            Name   = "JetBrainsMono Nerd Font"
            Source = "winget"
            Update = $true
        }
    )

    Drivers     = @(
        @{
            Id     = "XP8CLZL93F5Z4P"
            Name   = "NVIDIA App"
            Source = "msstore"
            Update = $true
        }
    )

    Tools       = @(
        @{
            Id     = "9N7F2SM5D1LR"
            Name   = "Windows HDR Calibration"
            Source = "msstore"
            Update = $true
        },

        @{
            Name   = "iCloud"
            Id     = "9PKTQ5699M62"
            Source = "msstore"
            Update = $true
        }
    )

    Browser     = @(
        @{
            Name   = "Zen Browser"
            Id     = "Zen-Team.Zen-Browser"
            Source = "winget"
            Update = $true
        },

        @{
            Name   = "Google Chrome Dev"
            Id     = "Google.Chrome.Beta"
            Source = "winget"
            Update = $true
        }
    )

    Development = @(
        @{
            Name   = "fnm"
            Id     = "Schniz.fnm"
            Source = "winget"
            Update = $true
        },
        @{
            Name   = "Go"
            Id     = "GoLang.Go"
            Source = "winget"
            Update = $true
        },
        @{
            Name   = "Bun"
            Id     = "Oven-sh.Bun"
            Source = "winget"
            Update = $true
        },
        @{
            Id     = "Git.Git"
            Name   = "Git"
            Source = "winget"
            Update = $true
        },
        @{
            Id     = "GitHub.cli"
            Name   = "GitHub CLI"
            Source = "winget"
            Update = $true
        },
        @{
            Id     = "GitHub.GitHubDesktop"
            Name   = "GitHub Desktop"
            Source = "winget"
            Update = $true
        },
        @{
            Id     = "Microsoft.VisualStudioCode"
            Name   = "Visual Studio Code"
            Source = "winget"
            Update = $true
        },
        @{
            Id     = "Microsoft.PowerShell"
            Name   = "PowerShell 7"
            Source = "winget"
            Update = $true
        },
        @{
            Id     = "Nushell.Nushell"
            Name   = "Nushell"
            Source = "winget"
            Update = $true
        },
        @{
            Id     = "Starship.Starship"
            Name   = "Starship"
            Source = "winget"
            Update = $true
        }
    )
}
