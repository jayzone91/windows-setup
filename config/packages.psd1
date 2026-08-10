# ============================================================
# Paket-Konfiguration
# ============================================================
#
# Unterstützte Paketquellen:
#
#   Winget
#     Id     = Winget-Paket-ID
#     Source = "winget"
#
#   Microsoft Store
#     Id     = Store-Paket-ID
#     Source = "msstore"
#
#   Chocolatey
#     Id     = Chocolatey-Paketname
#     Source = "chocolatey"
#
#   Scoop
#     Id        = Scoop-Paketname
#     Source    = "scoop"
#     Bucket    = "extras"          # Pflichtfeld, auch "main" explizit angeben
#     BucketUrl = "https://..."     # nur für eigene / unbekannte Buckets
#
# Gemeinsame Optionen:
#
#   Name   = Anzeigename
#   Update = $true / $false
#
# Winget unterstützt zusätzlich:
#
#   Version = "1.2.3"               # feste Version
#
# Beispiele:
#
# @{
#     Name   = "Git"
#     Id     = "Git.Git"
#     Source = "winget"
#     Update = $true
# }
#
# @{
#     Name   = "FileZilla Client"
#     Id     = "filezilla"
#     Source = "chocolatey"
#     Update = $true
# }
#
# @{
#     Name   = "Beispiel"
#     Id     = "example"
#     Source = "scoop"
#     Bucket = "versions"
#     Update = $true
# }
#
# Benötigte Scoop-Buckets werden automatisch aus allen
# Scoop-Paketdefinitionen ermittelt und vor der Paketinstallation
# hinzugefügt. Für bekannte Buckets reicht "Bucket". Für eigene
# Buckets zusätzlich "BucketUrl" angeben.
#
# Chocolatey und Scoop werden vom Bootstrap automatisch
# installiert und bei jedem Lauf selbst aktualisiert.
#
# ============================================================
@{
    Base        = @(
        @{
            Id     = "DEVCOM.JetBrainsMonoNerdFont"
            Name   = "JetBrainsMono Nerd Font"
            Source = "winget"
            Update = $true
        },

        @{
            Name   = "Just"
            Id     = "Casey.Just"
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
        },

        @{
            Name   = "ChatGPT"
            Id     = "9PLM9XGG6VKS"
            Source = "msstore"
            Update = $true
        },

        @{
            Name   = "Raycast"
            Id     = "9PFXXSHC64H3"
            Source = "msstore"
            Update = $true
        },

        @{
            Name    = "OpenVPN"
            Id      = "OpenVPNTechnologies.OpenVPN"
            Source  = "winget"
            Version = "2.7.101"
            Update  = $false
        },

        @{
            Name   = "Logitech G HUB"
            Id     = "Logitech.GHUB"
            Source = "winget"
            Update = $true
        },

        @{
            Name   = "Komorebi"
            Id     = "LGUG2Z.komorebi"
            Source = "winget"
            Update = $true
        },

        @{
            Name   = "Zebar"
            Id     = "glzr-io.zebar"
            Source = "winget"
        },

        @{
            Name   = "whkd"
            Id     = "LGUG2Z.whkd"
            Source = "winget"
            Update = $true
        }

        @{
            Name   = "Masir"
            Id     = "LGUG2Z.masir"
            Source = "winget"
            Update = $true
        }

        @{
            Name   = "OneCommander"
            Id     = "MilosParipovic.OneCommander"
            Source = "winget"
            Update = $true
        }

        @{
            Name   = "NanaZip"
            Id     = "M2Team.NanaZip"
            Source = "winget"
            Update = $true
        },

        @{
            Name   = "PowerToys"
            Id     = "Microsoft.PowerToys"
            Source = "winget"
            Update = $true
        },

        @{
            Name   = "Everything"
            Id     = "voidtools.Everything"
            Source = "winget"
            Update = $true
        }
    )

    HomeOffice  = @(
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
            Name   = "Google Chrome Beta"
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
        },
        @{
            Name   = "Neovim Nightly"
            Id     = "neovim-nightly"
            Source = "scoop"
            Bucket = "versions"
            Update = $true
        },

        @{
            Name   = "tree-sitter CLI"
            Id     = "tree-sitter"
            Source = "scoop"
            Bucket = "main"
            Update = $true
        },

        @{
            Name   = "Zig"
            Id     = "zig"
            Source = "scoop"
            Bucket = "main"
            Update = $true
        },
        @{
            Name   = "ripgrep"
            Id     = "BurntSushi.ripgrep.MSVC"
            Source = "winget"
            Update = $true
        },

        @{
            Name   = "eza"
            Id     = "eza-community.eza"
            Source = "winget"
            Update = $true
        },

        @{
            Name   = "fd"
            Id     = "sharkdp.fd"
            Source = "winget"
            Update = $true
        },

        @{
            Name   = "bat"
            Id     = "sharkdp.bat"
            Source = "winget"
            Update = $true
        },

        @{
            Name   = "fzf"
            Id     = "junegunn.fzf"
            Source = "winget"
            Update = $true
        },

        @{
            Name   = "jq"
            Id     = "jqlang.jq"
            Source = "winget"
            Update = $true
        },

        @{
            Name   = "zoxide"
            Id     = "ajeetdsouza.zoxide"
            Source = "winget"
            Update = $true
        }
    )
}
