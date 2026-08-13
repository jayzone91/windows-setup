@{
    AppxPackages      = @(

        # ----------------------------------------------------
        # Microsoft Consumer / Werbung
        # ----------------------------------------------------

        "Microsoft.BingNews"
        "Microsoft.BingSearch"
        "Microsoft.BingWeather"
        "Microsoft.MicrosoftSolitaireCollection"
        "Microsoft.WindowsFeedbackHub"
        "Microsoft.GetHelp"

        # ----------------------------------------------------
        # Microsoft Consumer Apps
        # ----------------------------------------------------

        "Microsoft.Copilot"
        "Microsoft.OutlookForWindows"
        "Microsoft.Todos"
        "Microsoft.PowerAutomateDesktop"
        "MicrosoftCorporationII.QuickAssist"
        "MSTeams"

        # ----------------------------------------------------
        # Medien / Kreativ
        # ----------------------------------------------------

        "Clipchamp.Clipchamp"
        "Microsoft.ZuneMusic"
        "Microsoft.WindowsSoundRecorder"

        # ----------------------------------------------------
        # Sonstiges
        # ----------------------------------------------------

        "Microsoft.WindowsAlarms"
    )


    OptionalFeatures  = @(
        # Vorerst absichtlich leer.
        #
        # Optional Features greifen tiefer ins System ein.
        # Die schauen wir uns separat an.
    )


    Capabilities      = @(
        # Ebenfalls zunächst leer.
    )


    RegistryTweaks    = @(
        @{
            Path  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            Name  = "SilentInstalledAppsEnabled"
            Type  = "DWord"
            Value = 0
        }

        @{
            Path  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            Name  = "SystemPaneSuggestionsEnabled"
            Type  = "DWord"
            Value = 0
        }

        @{
            Path  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            Name  = "SubscribedContent-338388Enabled"
            Type  = "DWord"
            Value = 0
        }

        @{
            Path  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            Name  = "SubscribedContent-338389Enabled"
            Type  = "DWord"
            Value = 0
        }

        @{
            Path  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            Name  = "SubscribedContent-353694Enabled"
            Type  = "DWord"
            Value = 0
        }

        @{
            Path  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            Name  = "SubscribedContent-353696Enabled"
            Type  = "DWord"
            Value = 0
        }
    )


    # --------------------------------------------------------
    # Dokumentation: Diese Pakete NICHT entfernen
    # --------------------------------------------------------

    ProtectedPackages = @(

        # Microsoft Store / App Infrastruktur
        "Microsoft.WindowsStore"
        "Microsoft.StorePurchaseApp"
        "Microsoft.DesktopAppInstaller"

        # Windows UI / Runtime
        "Microsoft.Windows.ShellExperienceHost"
        "Microsoft.Windows.StartMenuExperienceHost"
        "MicrosoftWindows.Client.CBS"
        "MicrosoftWindows.Client.Core"
        "Microsoft.UI.Xaml"
        "Microsoft.VCLibs"
        "Microsoft.NET.Native"

        # WebView
        "MicrosoftEdgeWebView"

        # Windows Security
        "Microsoft.SecHealthUI"

        # Windows Hello / Anmeldung
        "Microsoft.AAD.BrokerPlugin"
        "Microsoft.AccountsControl"
        "Microsoft.BioEnrollment"
        "Microsoft.CredDialogHost"
        "Microsoft.LockApp"

        # Gaming
        "Microsoft.GamingApp"
        "Microsoft.GamingServices"
        "Microsoft.XboxGameOverlay"
        "Microsoft.XboxGamingOverlay"
        "Microsoft.XboxIdentityProvider"
        "Microsoft.XboxSpeechToTextOverlay"

        # Sinnvolle Windows Apps
        "Microsoft.WindowsTerminal"
        "Microsoft.WindowsNotepad"
        "Microsoft.WindowsCalculator"
        "Microsoft.Windows.Photos"
        "Microsoft.Paint"
    )
}
