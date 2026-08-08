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


    Zen        = @(
        @{
            Name       = "iCloud Passwords"
            Type       = "Firefox"
            InstallUrl = "https://addons.mozilla.org/firefox/downloads/latest/icloud-passwords/latest.xpi"
        },
        @{
            Name       = "uBlock Origin"
            Type       = "Firefox"
            InstallUrl = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
        },
        @{
            Name       = "Deutsch (Deutschland) Sprachpaket"
            Type       = "Firefox"
            InstallUrl = "https://addons.mozilla.org/firefox/downloads/latest/deutsch-de-language-pack/latest.xpi"
        },
        @{
            Name       = "Deutsches Wörterbuch"
            Type       = "Firefox"
            InstallUrl = "https://addons.mozilla.org/firefox/downloads/latest/dictionary-german/latest.xpi"
        }
    )

}
