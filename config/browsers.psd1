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
            Locale                 = "de"
            SearchEngine           = "Google"
            SpellcheckDictionary   = "de-DE"
            RestorePreviousSession = $true
            DisableTelemetry       = $true
            DisableFirefoxStudies  = $true
            DisablePocket          = $true
            EnableUserStyles       = $true
        }

        Mods        = @(
            @{
                Name = "No Sidebar Scrollbar"
                Id   = "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8"
            },
            @{
                Name = "Floating Status Bar "
                Id   = "906c6915-5677-48ff-9bfc-096a02a72379"
            },
            @{
                Name = "Tab Preview Enhanced"
                Id   = "87196c08-8ca1-4848-b13b-7ea41ee830e7"
            },
            @{
                Name = "Transparent Zen"
                Id   = "642854b5-88b4-4c40-b256-e035532109df"
            },
            @{
                Name = "Animations Plus"
                Id   = "f4866f39-cfd6-4498-ab92-54213b8279dc"
            },
            @{
                Name = "Better Letterboxing"
                Id   = "1e9f3101-210b-4ff5-8830-434e4919100d"
            },
            @{
                Name = "Private Mode Highlighting"
                Id   = "58649066-2b6f-4a5b-af6d-c3d21d16fc00"
            },
            @{
                Name = "Zen Back Forward"
                Id   = "c8d9e6e6-e702-4e15-8972-3596e57cf398"
            },
            @{
                Name = "Load Bar"
                Id   = "ae7868dc-1fa1-469e-8b89-a5edf7ab1f24"
            },
            @{
                Name = "Ghost Tabs"
                Id   = "c01d3e22-1cee-45c1-a25e-53c0f180eea8"
            },
            @{
                Name = "Audio Indicator Enhanced"
                Id   = "2317fd93-c3ed-4f37-b55a-304c1816819e"
            },
            @{
                Name = "Better Tab Indicators"
                Id   = "664c54f9-d97d-410b-a479-23dd8a08a628"
            },
            @{
                Name = "No pinned tab reset btn"
                Id   = "c45c4894-d6bd-47fc-997a-0c4d015334f1"
            },
            @{
                Name = "Better Find Bar "
                Id   = "a6335949-4465-4b71-926c-4a52d34bc9c0"
            }
        )
    }
}
