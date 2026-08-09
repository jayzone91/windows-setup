function ConvertTo-PowerToysHotkeyObject {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Hotkey
    )

    return [pscustomobject]@{
        win   = [bool]$Hotkey.win
        ctrl  = [bool]$Hotkey.ctrl
        alt   = [bool]$Hotkey.alt
        shift = [bool]$Hotkey.shift
        code  = [int]$Hotkey.code
        key   = [string]$Hotkey.key
    }
}

function Test-PowerToysJsonEqual {
    param(
        [AllowNull()]
        [object]$Current,

        [AllowNull()]
        [object]$Desired
    )

    $currentJson = $Current | ConvertTo-Json -Depth 100 -Compress
    $desiredJson = $Desired | ConvertTo-Json -Depth 100 -Compress

    return $currentJson -eq $desiredJson
}

function Set-PowerToysJsonProperty {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Object,

        [Parameter(Mandatory)]
        [string]$Name,

        [AllowNull()]
        [object]$Value,

        [ref]$Changed
    )

    $property = $Object.PSObject.Properties[$Name]

    if ($null -eq $property) {
        $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
        $Changed.Value = $true
        return
    }

    if (-not (Test-PowerToysJsonEqual -Current $property.Value -Desired $Value)) {
        $property.Value = $Value
        $Changed.Value = $true
    }
}

function Backup-UnmanagedPowerToysFile {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$RepositoryPath
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return
    }

    $backupRoot = Join-Path `
        $RepositoryPath `
        ".generated\backups\powertoys\before-managed-state"

    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

    $safeName = $Path `
        -replace [regex]::Escape($env:LOCALAPPDATA), "LOCALAPPDATA" `
        -replace '[:\\\/]', '_'

    $backupPath = Join-Path $backupRoot $safeName

    if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) {
        Copy-Item -LiteralPath $Path -Destination $backupPath
        Write-Host "[OK] Ausgangskonfiguration gesichert: $Path"
    }
}

function Write-PowerToysJson {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [object]$Object
    )

    $json = $Object | ConvertTo-Json -Depth 100

    [System.IO.File]::WriteAllText(
        $Path,
        $json,
        [System.Text.UTF8Encoding]::new($false)
    )

    $null = Get-Content -LiteralPath $Path -Raw |
        ConvertFrom-Json -Depth 100
}

function Get-CommandPaletteSettingsPath {
    $package = Get-AppxPackage `
        -Name "Microsoft.CommandPalette" `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -eq $package) {
        return $null
    }

    return Join-Path `
        $env:LOCALAPPDATA `
        ("Packages\{0}\LocalState\settings.json" -f $package.PackageFamilyName)
}

function Set-PowerToysConfiguration {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " PowerToys"
    Write-Host "========================================"
    Write-Host ""

    $powerToysRoot = Join-Path $env:LOCALAPPDATA "Microsoft\PowerToys"

    $paths = @{
        Global = Join-Path $powerToysRoot "settings.json"
        AdvancedPaste = Join-Path $powerToysRoot "AdvancedPaste\settings.json"
        FileLocksmith = Join-Path $powerToysRoot "File Locksmith\file-locksmith-settings.json"
        FindMyMouse = Join-Path $powerToysRoot "FindMyMouse\settings.json"
        PowerRename = Join-Path $powerToysRoot "PowerRename\power-rename-settings.json"
        CommandPalette = Get-CommandPaletteSettingsPath
    }

    $requiredPaths = @(
        $paths.Global
        $paths.AdvancedPaste
        $paths.FileLocksmith
        $paths.FindMyMouse
        $paths.PowerRename
    )

    foreach ($path in $requiredPaths) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Write-Warning "PowerToys-Konfigurationsdatei nicht gefunden: $path"
            return
        }
    }

    if (
        [string]::IsNullOrWhiteSpace($paths.CommandPalette) -or
        -not (Test-Path -LiteralPath $paths.CommandPalette -PathType Leaf)
    ) {
        Write-Warning "Command-Palette-Konfiguration wurde nicht gefunden."
        return
    }

    $global = Get-Content -LiteralPath $paths.Global -Raw |
        ConvertFrom-Json -Depth 100

    $advancedPaste = Get-Content -LiteralPath $paths.AdvancedPaste -Raw |
        ConvertFrom-Json -Depth 100

    $fileLocksmith = Get-Content -LiteralPath $paths.FileLocksmith -Raw |
        ConvertFrom-Json -Depth 100

    $findMyMouse = Get-Content -LiteralPath $paths.FindMyMouse -Raw |
        ConvertFrom-Json -Depth 100

    $powerRename = Get-Content -LiteralPath $paths.PowerRename -Raw |
        ConvertFrom-Json -Depth 100

    $commandPalette = Get-Content -LiteralPath $paths.CommandPalette -Raw |
        ConvertFrom-Json -Depth 100

    $changed = $false

    # --------------------------------------------------------
    # Globale Modulzustände
    # --------------------------------------------------------

    foreach ($moduleName in $Config.EnabledModules.Keys) {
        $property = $global.enabled.PSObject.Properties[$moduleName]

        if ($null -eq $property) {
            Write-Warning "PowerToys-Modul nicht in settings.json gefunden: $moduleName"
            continue
        }

        $desiredEnabled = [bool]$Config.EnabledModules[$moduleName]

        if ([bool]$property.Value -ne $desiredEnabled) {
            $property.Value = $desiredEnabled
            $changed = $true
            Write-Host "[CHANGE] Modul $moduleName = $desiredEnabled"
        }
    }

    # --------------------------------------------------------
    # Advanced Paste
    # --------------------------------------------------------

    $advancedChanged = $false
    $properties = $advancedPaste.properties

    $advancedHotkeys = @{
        "advanced-paste-ui-hotkey" = ConvertTo-PowerToysHotkeyObject `
            -Hotkey $Config.AdvancedPaste.WindowHotkey
        "paste-as-plain-hotkey" = ConvertTo-PowerToysHotkeyObject `
            -Hotkey $Config.AdvancedPaste.PlainTextHotkey
        "paste-as-markdown-hotkey" = ConvertTo-PowerToysHotkeyObject `
            -Hotkey $Config.AdvancedPaste.MarkdownHotkey
        "paste-as-json-hotkey" = ConvertTo-PowerToysHotkeyObject `
            -Hotkey $Config.AdvancedPaste.JsonHotkey
    }

    foreach ($name in $advancedHotkeys.Keys) {
        $current = $properties.PSObject.Properties[$name]

        if ($null -eq $current) {
            Write-Warning "Advanced-Paste-Einstellung nicht gefunden: $name"
            continue
        }

        if (
            -not (
                Test-PowerToysJsonEqual `
                    -Current $current.Value `
                    -Desired $advancedHotkeys[$name]
            )
        ) {
            $current.Value = $advancedHotkeys[$name]
            $advancedChanged = $true
        }
    }

    $additionalActions = $properties."additional-actions"

    if (
        [bool]$additionalActions."paste-as-file".isShown -ne
        [bool]$Config.AdvancedPaste.PasteAsFile.Enabled
    ) {
        $additionalActions."paste-as-file".isShown =
            [bool]$Config.AdvancedPaste.PasteAsFile.Enabled

        $advancedChanged = $true
    }

    $pasteFileActions = @{
        "paste-as-txt-file" = [bool]$Config.AdvancedPaste.PasteAsFile.Txt.Enabled
        "paste-as-png-file" = [bool]$Config.AdvancedPaste.PasteAsFile.Png.Enabled
        "paste-as-html-file" = [bool]$Config.AdvancedPaste.PasteAsFile.Html.Enabled
    }

    foreach ($name in $pasteFileActions.Keys) {
        $action = $additionalActions."paste-as-file".$name
        $desiredEnabled = $pasteFileActions[$name]

        if ([bool]$action.isShown -ne $desiredEnabled) {
            $action.isShown = $desiredEnabled
            $advancedChanged = $true
        }

        $emptyHotkey = ConvertTo-PowerToysHotkeyObject -Hotkey @{
            win = $false
            ctrl = $false
            alt = $false
            shift = $false
            code = 0
            key = ""
        }

        if (
            -not (
                Test-PowerToysJsonEqual `
                    -Current $action.shortcut `
                    -Desired $emptyHotkey
            )
        ) {
            $action.shortcut = $emptyHotkey
            $advancedChanged = $true
        }
    }

    if (
        [bool]$additionalActions.transcode.isShown -ne
        [bool]$Config.AdvancedPaste.Transcode.Enabled
    ) {
        $additionalActions.transcode.isShown =
            [bool]$Config.AdvancedPaste.Transcode.Enabled

        $advancedChanged = $true
    }

    $transcodeActions = @{
        "transcode-to-mp3" = [bool]$Config.AdvancedPaste.Transcode.Mp3.Enabled
        "transcode-to-mp4" = [bool]$Config.AdvancedPaste.Transcode.Mp4.Enabled
    }

    foreach ($name in $transcodeActions.Keys) {
        $action = $additionalActions.transcode.$name
        $desiredEnabled = $transcodeActions[$name]

        if ([bool]$action.isShown -ne $desiredEnabled) {
            $action.isShown = $desiredEnabled
            $advancedChanged = $true
        }

        $emptyHotkey = ConvertTo-PowerToysHotkeyObject -Hotkey @{
            win = $false
            ctrl = $false
            alt = $false
            shift = $false
            code = 0
            key = ""
        }

        if (
            -not (
                Test-PowerToysJsonEqual `
                    -Current $action.shortcut `
                    -Desired $emptyHotkey
            )
        ) {
            $action.shortcut = $emptyHotkey
            $advancedChanged = $true
        }
    }

    # --------------------------------------------------------
    # File Locksmith
    # --------------------------------------------------------

    $fileLocksmithChanged = $false

    if (
        [bool]$fileLocksmith.showInExtendedContextMenu -ne
        [bool]$Config.FileLocksmith.ShowInExtendedContextMenuOnly
    ) {
        $fileLocksmith.showInExtendedContextMenu =
            [bool]$Config.FileLocksmith.ShowInExtendedContextMenuOnly

        $fileLocksmithChanged = $true
    }

    # --------------------------------------------------------
    # Find My Mouse
    # --------------------------------------------------------

    $findMyMouseChanged = $false

    if (
        [int]$findMyMouse.properties.activation_method.value -ne
        [int]$Config.FindMyMouse.ActivationMethod
    ) {
        $findMyMouse.properties.activation_method.value =
            [int]$Config.FindMyMouse.ActivationMethod

        $findMyMouseChanged = $true
    }

    if (
        [bool]$findMyMouse.properties.do_not_activate_on_game_mode.value -ne
        [bool]$Config.FindMyMouse.DoNotActivateOnGameMode
    ) {
        $findMyMouse.properties.do_not_activate_on_game_mode.value =
            [bool]$Config.FindMyMouse.DoNotActivateOnGameMode

        $findMyMouseChanged = $true
    }

    # --------------------------------------------------------
    # PowerRename
    # --------------------------------------------------------

    $powerRenameChanged = $false

    $powerRenameDesired = @{
        ShowIcon = [bool]$Config.PowerRename.ShowIcon
        ExtendedContextMenuOnly = [bool]$Config.PowerRename.ExtendedContextMenuOnly
        PersistState = [bool]$Config.PowerRename.PersistState
        MRUEnabled = [bool]$Config.PowerRename.MRUEnabled
        MaxMRUSize = [int]$Config.PowerRename.MaxMRUSize
        UseBoostLib = [bool]$Config.PowerRename.UseBoostLib
    }

    foreach ($name in $powerRenameDesired.Keys) {
        $currentProperty = $powerRename.PSObject.Properties[$name]

        if ($null -eq $currentProperty) {
            Write-Warning "PowerRename-Einstellung nicht gefunden: $name"
            continue
        }

        if (
            -not (
                Test-PowerToysJsonEqual `
                    -Current $currentProperty.Value `
                    -Desired $powerRenameDesired[$name]
            )
        ) {
            $currentProperty.Value = $powerRenameDesired[$name]
            $powerRenameChanged = $true
        }
    }

    # --------------------------------------------------------
    # Command Palette
    # --------------------------------------------------------

    $commandPaletteChanged = $false

    $desiredHotkey = ConvertTo-PowerToysHotkeyObject `
        -Hotkey $Config.CommandPalette.Hotkey

    if (
        -not (
            Test-PowerToysJsonEqual `
                -Current $commandPalette.Hotkey `
                -Desired $desiredHotkey
        )
    ) {
        $commandPalette.Hotkey = $desiredHotkey
        $commandPaletteChanged = $true
    }

    $commandPaletteSettings = @(
        "UseLowLevelGlobalHotkey"
        "ShowAppDetails"
        "BackspaceGoesBack"
        "SingleClickActivates"
        "HighlightSearchOnActivate"
        "KeepPreviousQuery"
        "ShowSystemTrayIcon"
        "IgnoreShortcutWhenFullscreen"
        "IgnoreShortcutWhenBusy"
        "AllowBreakthroughShortcut"
        "AllowExternalReload"
        "SummonOn"
        "DisableAnimations"
        "EnableDock"
        "Theme"
        "ColorizationMode"
        "CustomThemeColorIntensity"
        "BackdropStyle"
        "BackdropOpacity"
    )

    foreach ($name in $commandPaletteSettings) {
        $desiredValue = $Config.CommandPalette[$name]
        $property = $commandPalette.PSObject.Properties[$name]

        if ($null -eq $property) {
            $commandPalette |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name $name `
                    -Value $desiredValue

            $commandPaletteChanged = $true
            continue
        }

        if (
            -not (
                Test-PowerToysJsonEqual `
                    -Current $property.Value `
                    -Desired $desiredValue
            )
        ) {
            $property.Value = $desiredValue
            $commandPaletteChanged = $true
        }
    }

    $desiredColor = [pscustomobject]@{
        A = [int]$Config.CommandPalette.CustomThemeColor.A
        R = [int]$Config.CommandPalette.CustomThemeColor.R
        G = [int]$Config.CommandPalette.CustomThemeColor.G
        B = [int]$Config.CommandPalette.CustomThemeColor.B
    }

    if (
        -not (
            Test-PowerToysJsonEqual `
                -Current $commandPalette.CustomThemeColor `
                -Desired $desiredColor
        )
    ) {
        $commandPalette.CustomThemeColor = $desiredColor
        $commandPaletteChanged = $true
    }

    foreach ($providerId in $Config.CommandPalette.Providers.Keys) {
        $providerProperty =
            $commandPalette.ProviderSettings.PSObject.Properties[$providerId]

        if ($null -eq $providerProperty) {
            Write-Warning "Command-Palette-Provider nicht gefunden: $providerId"
            continue
        }

        $desiredEnabled =
            [bool]$Config.CommandPalette.Providers[$providerId]

        if (
            [bool]$providerProperty.Value.IsEnabled -ne
            $desiredEnabled
        ) {
            $providerProperty.Value.IsEnabled = $desiredEnabled
            $commandPaletteChanged = $true
        }
    }

    $changed =
        $changed -or
        $advancedChanged -or
        $fileLocksmithChanged -or
        $findMyMouseChanged -or
        $powerRenameChanged -or
        $commandPaletteChanged

    if (-not $changed) {
        Write-Host "[OK] PowerToys entspricht bereits dem Desired State."
        return
    }

    foreach ($path in $paths.Values) {
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            Backup-UnmanagedPowerToysFile `
                -Path $path `
                -RepositoryPath $RepositoryPath
        }
    }

    # PowerToys erst bei echtem Drift beenden, damit laufende
    # Komponenten die Dateien nicht direkt wieder überschreiben.
    $powerToysProcess = Get-Process `
        -Name "PowerToys" `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    $powerToysExe = $null

    if ($null -ne $powerToysProcess) {
        try {
            $powerToysExe = $powerToysProcess.Path
        }
        catch {
            $powerToysExe = $null
        }
    }

    if ($commandPaletteChanged) {
        Get-Process `
            -Name "CommandPalette" `
            -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue

        Start-Sleep -Milliseconds 300
    }

    if ($null -ne $powerToysProcess) {
        Get-Process `
            -ErrorAction SilentlyContinue |
            Where-Object {
                $_.ProcessName -like "PowerToys*"
            } |
            Stop-Process -Force -ErrorAction SilentlyContinue

        Start-Sleep -Milliseconds 800
    }

    if ($changed) {
        Write-PowerToysJson -Path $paths.Global -Object $global
    }

    if ($advancedChanged) {
        Write-PowerToysJson `
            -Path $paths.AdvancedPaste `
            -Object $advancedPaste
    }

    if ($fileLocksmithChanged) {
        Write-PowerToysJson `
            -Path $paths.FileLocksmith `
            -Object $fileLocksmith
    }

    if ($findMyMouseChanged) {
        Write-PowerToysJson `
            -Path $paths.FindMyMouse `
            -Object $findMyMouse
    }

    if ($powerRenameChanged) {
        Write-PowerToysJson `
            -Path $paths.PowerRename `
            -Object $powerRename
    }

    if ($commandPaletteChanged) {
        Write-PowerToysJson `
            -Path $paths.CommandPalette `
            -Object $commandPalette
    }

    if (
        -not [string]::IsNullOrWhiteSpace($powerToysExe) -and
        (Test-Path -LiteralPath $powerToysExe -PathType Leaf)
    ) {
        Start-Process -FilePath $powerToysExe
        Write-Host "[OK] PowerToys neu gestartet."
    }

    Write-Host "[OK] PowerToys Desired State angewendet."
}