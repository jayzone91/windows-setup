@{
    EnabledModules = @{
        AdvancedPaste             = $true
        AlwaysOnTop               = $false
        Awake                     = $false
        CmdPal                    = $true
        ColorPicker               = $true
        CropAndLock               = $false
        CursorWrap                = $false
        EnvironmentVariables      = $false
        FancyZones                = $false
        "File Locksmith"          = $true
        FindMyMouse               = $true
        GrabAndMove               = $false
        Hosts                     = $false
        "Image Resizer"           = $false
        "Keyboard Manager"        = $false
        LightSwitch               = $false
        "Measure Tool"            = $false
        MouseHighlighter          = $false
        MouseJump                 = $false
        MousePointerCrosshairs    = $false
        MouseWithoutBorders       = $false
        NewPlus                   = $false
        Peek                      = $false
        PowerDisplay              = $false
        PowerRename               = $true
        "PowerToys Run"           = $false
        QuickAccent               = $false
        RegistryPreview           = $false
        "Shortcut Guide"          = $false
        TextExtractor             = $false
        Workspaces                = $false
        ZoomIt                    = $false
    }

    CommandPalette = @{
        Hotkey = @{
            win   = $false
            ctrl  = $false
            alt   = $true
            shift = $false
            code  = 32
            key   = ""
        }

        UseLowLevelGlobalHotkey       = $false
        ShowAppDetails                = $false
        BackspaceGoesBack             = $false
        SingleClickActivates          = $false
        HighlightSearchOnActivate     = $true
        KeepPreviousQuery             = $false
        ShowSystemTrayIcon            = $false
        IgnoreShortcutWhenFullscreen  = $true
        IgnoreShortcutWhenBusy        = $false
        AllowBreakthroughShortcut     = $false
        AllowExternalReload           = $true
        SummonOn                      = "ToMouse"
        DisableAnimations             = $false
        EnableDock                    = $false

        Theme                         = "Dark"
        ColorizationMode              = "Custom"
        CustomThemeColor              = @{
            A = 255
            R = 203
            G = 166
            B = 247
        }
        CustomThemeColorIntensity     = 24
        BackdropStyle                 = "Acrylic"
        BackdropOpacity               = 95

        Providers = @{
            "VictorLin.EverythingCP_yazqh14evg2ve!App!ID" = $true
            "Files"                                          = $false
        }
    }

    AdvancedPaste = @{
        WindowHotkey = @{
            win   = $false
            ctrl  = $false
            alt   = $false
            shift = $false
            code  = 0
            key   = ""
        }

        PlainTextHotkey = @{
            win   = $false
            ctrl  = $true
            alt   = $false
            shift = $true
            code  = 86
            key   = ""
        }

        MarkdownHotkey = @{
            win   = $false
            ctrl  = $true
            alt   = $false
            shift = $true
            code  = 77
            key   = ""
        }

        JsonHotkey = @{
            win   = $false
            ctrl  = $false
            alt   = $false
            shift = $false
            code  = 0
            key   = ""
        }

        PasteAsFile = @{
            Enabled = $true

            Txt = @{
                Enabled = $false
            }

            Png = @{
                Enabled = $false
            }

            Html = @{
                Enabled = $false
            }
        }

        Transcode = @{
            Enabled = $true

            Mp3 = @{
                Enabled = $false
            }

            Mp4 = @{
                Enabled = $false
            }
        }
    }

    FileLocksmith = @{
        ShowInExtendedContextMenuOnly = $false
    }

    FindMyMouse = @{
        # 0 = zweimal linke STRG-Taste drücken
        ActivationMethod = 0
        DoNotActivateOnGameMode = $true
    }

    PowerRename = @{
        ShowIcon                = $true
        ExtendedContextMenuOnly = $false
        PersistState            = $true
        MRUEnabled              = $true
        MaxMRUSize              = 10
        UseBoostLib             = $false
    }
}