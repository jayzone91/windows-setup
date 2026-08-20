@{
    EnabledModules = @{
        AdvancedPaste          = $true
        AlwaysOnTop            = $false
        Awake                  = $false
        CmdPal                 = $false
        ColorPicker            = $true
        CropAndLock            = $false
        CursorWrap             = $false
        EnvironmentVariables   = $false
        FancyZones             = $true
        "File Locksmith"       = $true
        FindMyMouse            = $true
        GrabAndMove            = $false
        Hosts                  = $false
        "Image Resizer"        = $false
        "Keyboard Manager"     = $false
        LightSwitch            = $false
        "Measure Tool"         = $false
        MouseHighlighter       = $false
        MouseJump              = $false
        MousePointerCrosshairs = $false
        MouseWithoutBorders    = $false
        NewPlus                = $false
        Peek                   = $false
        PowerDisplay           = $false
        PowerRename            = $true
        "PowerToys Run"        = $false
        QuickAccent            = $false
        RegistryPreview        = $false
        "Shortcut Guide"       = $false
        TextExtractor          = $false
        Workspaces             = $false
        ZoomIt                 = $false
    }

    FancyZones = @{
        CustomLayoutsPath = 'dotfiles\powertoys\fancyzones\custom-layouts.json'
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

        UseLowLevelGlobalHotkey      = $false
        ShowAppDetails               = $true
        BackspaceGoesBack            = $true
        SingleClickActivates         = $false
        HighlightSearchOnActivate    = $true
        KeepPreviousQuery            = $false
        ShowSystemTrayIcon           = $false
        IgnoreShortcutWhenFullscreen = $true
        IgnoreShortcutWhenBusy       = $false
        AllowBreakthroughShortcut    = $false
        AllowExternalReload          = $true
        SummonOn                     = "ToMouse"
        DisableAnimations            = $false
        EnableDock                   = $false

        Theme                     = "Default"
        ColorizationMode          = "CustomColor"
        CustomThemeColor          = @{
            A = 255
            R = 30
            G = 30
            B = 46
        }
        CustomThemeColorIntensity = 100
        BackdropStyle             = "Acrylic"
        BackdropOpacity           = 100

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
        ActivationMethod        = 0
        DoNotActivateOnGameMode = $true
        ExcludedApps            = @()
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