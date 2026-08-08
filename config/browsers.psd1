@{

    ChromeBeta = @{
        PolicyPath = "HKLM:\Software\Policies\Google\Chrome"

        Extensions = @(
            @{
                Name = "iCloud Passwords"
                Id   = "pejdijmoenmkgeppbflobdenhhabjlaj"
                Type = "Chrome"
            },
            @{
                Name = "AdBlock Plus"
                Id   = "cfhdojbkjhnklbpkdaibdccddilifddb"
                Type = "Chrome"
            }
        )
    }


    Zen        = @{
        Extensions  = @(
            @{
                Name       = "iCloud Passwords"
                InstallUrl = "https://addons.mozilla.org/firefox/downloads/latest/icloud-passwords/latest.xpi"
            },
            @{
                Name       = "uBlock Origin"
                InstallUrl = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
            },
            @{
                Name       = "Deutsch (Deutschland) Sprachpaket"
                InstallUrl = "https://addons.mozilla.org/firefox/downloads/latest/deutsch-de-language-pack/latest.xpi"
            },
            @{
                Name       = "Deutsches Wörterbuch"
                InstallUrl = "https://addons.mozilla.org/firefox/downloads/latest/dictionary-german/latest.xpi"
            }
        )

        Preferences = @{
            Locale           = "de"
            Homepage         = "about:blank"
            SearchEngine     = "Google"
            DisableTelemetry = $true
            DisablePocket    = $true
        }
    }

}
