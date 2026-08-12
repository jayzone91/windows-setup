$script:WindowsSetupSourceRoot_modules_VolumeOsd = Split-Path -Parent $PSScriptRoot
#Requires -Version 7.0
function Start-VolumeOsd {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 10)]
        [int] $StepPercent = 2
    )
    $ErrorActionPreference = "Stop"
    if (-not $IsWindows) {
        throw "Dieser Test ist ausschließlich für Windows vorgesehen."
    }
    if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne "STA") {
        throw (
            "Der Test benötigt einen STA-Thread. Starte ihn mit: " +
            "pwsh -NoProfile -STA -ExecutionPolicy Bypass -File " +
            '".\scripts\Test-OsdVolumePill.ps1"'
        )
    }
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    $interopSourcePath = Join-Path `
        (Join-Path $script:WindowsSetupSourceRoot_modules_VolumeOsd "VolumeOsd") `
        "Interop.cs"
    if (-not ("WindowsSetupVolumePill.VolumeKeyboardHook" -as [type])) {
        Add-Type -Path $interopSourcePath
    }
    function New-SolidBrush {
        [CmdletBinding()]
        [OutputType([System.Windows.Media.SolidColorBrush])]
        param(
            [Parameter(Mandatory)]
            [ValidatePattern("^#[0-9A-Fa-f]{6}$")]
            [string] $Color
        )
        return [System.Windows.Media.SolidColorBrush]::new(
            [System.Windows.Media.ColorConverter]::ConvertFromString(
                $Color
            )
        )
    }
    function Get-ActiveScreenWorkArea {
        [CmdletBinding()]
        param()
        Add-Type -AssemblyName System.Windows.Forms
        $screen =
            [System.Windows.Forms.Screen]::FromPoint(
                [System.Windows.Forms.Cursor]::Position
            )
        return $screen.WorkingArea
    }
    $themePath = Join-Path `
        $script:WindowsSetupSourceRoot_modules_VolumeOsd `
        "..\config\theme.psd1"
    $themePath =
        [System.IO.Path]::GetFullPath(
            $themePath
        )
    if (-not (Test-Path -LiteralPath $themePath -PathType Leaf)) {
        throw "Theme-Konfiguration nicht gefunden: $themePath"
    }
    $theme = Import-PowerShellDataFile `
        -Path $themePath
    $window = [System.Windows.Window]::new()
    $window.WindowStyle =
        [System.Windows.WindowStyle]::None
    $window.ResizeMode =
        [System.Windows.ResizeMode]::NoResize
    $window.ShowInTaskbar = $false
    $window.ShowActivated = $false
    $window.Topmost = $true
    $window.AllowsTransparency = $true
    $window.Background =
        [System.Windows.Media.Brushes]::Transparent
    $window.SizeToContent =
        [System.Windows.SizeToContent]::WidthAndHeight
    $window.WindowStartupLocation =
        [System.Windows.WindowStartupLocation]::Manual
    $window.Opacity = 0
    $shadow =
        [System.Windows.Media.Effects.DropShadowEffect]::new()
    $shadow.BlurRadius = 13
    $shadow.Opacity = 0.40
    $shadow.ShadowDepth = 4
    $shadow.Direction = 270
    $shadow.Color =
        [System.Windows.Media.ColorConverter]::ConvertFromString(
            "#000000"
        )
    $outer =
        [System.Windows.Controls.Border]::new()
    $outer.Background =
        New-SolidBrush `
            -Color $theme.Colors.Base
    $outer.BorderBrush =
        New-SolidBrush `
            -Color $theme.Colors.Mauve
    $outer.BorderThickness =
        [System.Windows.Thickness]::new(1)
    $outer.CornerRadius =
        [System.Windows.CornerRadius]::new(6)
    $outer.Padding =
        [System.Windows.Thickness]::new(
            9,
            0,
            8,
            0
        )
    $outer.Height = 36
    $outer.Effect = $shadow
    $outer.Opacity = 0.95
    $grid =
        [System.Windows.Controls.Grid]::new()
    $titleColumn =
        [System.Windows.Controls.ColumnDefinition]::new()
    $titleColumn.Width =
        [System.Windows.GridLength]::Auto
    $gapColumn =
        [System.Windows.Controls.ColumnDefinition]::new()
    $gapColumn.Width =
        [System.Windows.GridLength]::new(10)
    $valueColumn =
        [System.Windows.Controls.ColumnDefinition]::new()
    $valueColumn.Width =
        [System.Windows.GridLength]::Auto
    [void] $grid.ColumnDefinitions.Add($titleColumn)
    [void] $grid.ColumnDefinitions.Add($gapColumn)
    [void] $grid.ColumnDefinitions.Add($valueColumn)
    $title =
        [System.Windows.Controls.TextBlock]::new()
    $title.Text = "Volume"
    $title.Foreground =
        New-SolidBrush `
            -Color $theme.Colors.Text
    $title.FontFamily =
        [System.Windows.Media.FontFamily]::new(
            "Segoe UI"
        )
    $title.FontSize = 14
    $title.FontWeight =
        [System.Windows.FontWeights]::SemiBold
    $title.VerticalAlignment =
        [System.Windows.VerticalAlignment]::Center
    [System.Windows.Controls.Grid]::SetColumn(
        $title,
        0
    )
    $valueBorder =
        [System.Windows.Controls.Border]::new()
    $valueBorder.Background =
        New-SolidBrush `
            -Color $theme.Colors.Green
    $valueBorder.CornerRadius =
        [System.Windows.CornerRadius]::new(11)
    $valueBorder.Padding =
        [System.Windows.Thickness]::new(
            9,
            2,
            9,
            2
        )
    # Feste Mindestbreite verhindert Layout-Sprünge zwischen z. B.
    # "8%", "100%" und "MUTE".
    $valueBorder.MinWidth = 48
    $valueBorder.VerticalAlignment =
        [System.Windows.VerticalAlignment]::Center
    [System.Windows.Controls.Grid]::SetColumn(
        $valueBorder,
        2
    )
    $value =
        [System.Windows.Controls.TextBlock]::new()
    $value.Text = "20%"
    $value.Foreground =
        New-SolidBrush `
            -Color $theme.Colors.Base
    $value.FontFamily =
        [System.Windows.Media.FontFamily]::new(
            "Segoe UI"
        )
    $value.FontSize = 12
    $value.FontWeight =
        [System.Windows.FontWeights]::SemiBold
    $value.HorizontalAlignment =
        [System.Windows.HorizontalAlignment]::Center
    $value.VerticalAlignment =
        [System.Windows.VerticalAlignment]::Center
    $valueBorder.Child = $value
    [void] $grid.Children.Add($title)
    [void] $grid.Children.Add($valueBorder)
    $outer.Child = $grid
    $window.Content = $outer
    $fadeIn =
        [System.Windows.Media.Animation.DoubleAnimation]::new()
    $fadeIn.From = 0
    $fadeIn.To = 1
    $fadeIn.Duration =
        [System.Windows.Duration]::new(
            [TimeSpan]::FromMilliseconds(150)
        )
    $fadeOut =
        [System.Windows.Media.Animation.DoubleAnimation]::new()
    $fadeOut.From = 1
    $fadeOut.To = 0
    $fadeOut.Duration =
        [System.Windows.Duration]::new(
            [TimeSpan]::FromMilliseconds(150)
        )
    function Set-WindowPosition {
        [CmdletBinding()]
        param()
        $workArea = Get-ActiveScreenWorkArea
        $window.Measure(
            [System.Windows.Size]::new(
                [double]::PositiveInfinity,
                [double]::PositiveInfinity
            )
        )
        $width = $window.DesiredSize.Width
        $height = $window.DesiredSize.Height
        $window.Left =
            $workArea.Left +
            (($workArea.Width - $width) / 2)
        $window.Top =
            $workArea.Bottom -
            $height -
            48
    }
    $script:OsdIsFadingOut = $false
    $script:OsdHideCompleteAt = [DateTime]::MaxValue
    function Show-VolumePill {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [int] $Percent,
            [Parameter(Mandatory)]
            [bool] $Muted
        )
        # Solange das OSD sichtbar ist, wird ausschließlich der dargestellte
        # Zustand aktualisiert. Das Fenster selbst bleibt bestehen.
        $title.Text = "Volume"
        if ($Muted) {
            $value.Text = "MUTE"
            $valueBorder.Background =
                New-SolidBrush `
                    -Color $theme.Colors.Red
        }
        else {
            $value.Text = "$Percent%"
            $valueBorder.Background =
                New-SolidBrush `
                    -Color $theme.Colors.Green
        }
        if ($window.IsVisible) {
            # Falls genau während des Fade-outs ein neuer Lautstärke-Event kommt,
            # Fade-out abbrechen und das bestehende Fenster weiterverwenden.
            if ($script:OsdIsFadingOut) {
                $window.BeginAnimation(
                    [System.Windows.Window]::OpacityProperty,
                    $null
                )
                $window.Opacity = 1
                $script:OsdIsFadingOut = $false
                $script:OsdHideCompleteAt = [DateTime]::MaxValue
            }
            return
        }
        # Nur beim ersten Event eines neuen Bursts positionieren, anzeigen
        # und einmalig einblenden.
        Set-WindowPosition
        $window.BeginAnimation(
            [System.Windows.Window]::OpacityProperty,
            $null
        )
        $window.Opacity = 0
        $window.Show()
        $window.BeginAnimation(
            [System.Windows.Window]::OpacityProperty,
            $fadeIn
        )
    }
    function Start-HideVolumePill {
        [CmdletBinding()]
        param()
        if (
            -not $window.IsVisible -or
            $script:OsdIsFadingOut
        ) {
            return
        }
        $script:OsdIsFadingOut = $true
        $script:OsdHideCompleteAt =
            [DateTime]::UtcNow.AddMilliseconds(150)
        $window.BeginAnimation(
            [System.Windows.Window]::OpacityProperty,
            $fadeOut
        )
    }
    function Complete-HideVolumePill {
        [CmdletBinding()]
        param()
        if (
            -not $script:OsdIsFadingOut -or
            [DateTime]::UtcNow -lt
            $script:OsdHideCompleteAt
        ) {
            return
        }
        $window.BeginAnimation(
            [System.Windows.Window]::OpacityProperty,
            $null
        )
        $window.Hide()
        $window.Opacity = 0
        $script:OsdIsFadingOut = $false
        $script:OsdHideCompleteAt = [DateTime]::MaxValue
    }
    $mutexCreated = $false
    $mutex = [System.Threading.Mutex]::new(
        $true,
        "Local\WindowsSetupVolumeOsd",
        [ref] $mutexCreated
    )
    if (-not $mutexCreated) {
        $mutex.Dispose()
        exit 0
    }
    $audio = $null
    $step =
        [float] ($StepPercent / 100.0)
    $hideAt = [DateTime]::MaxValue
    try {
        $audio =
            [WindowsSetupVolumePill.AudioController]::new()
        [WindowsSetupVolumePill.VolumeKeyboardHook]::Install()
        while ($true) {
            $window.Dispatcher.Invoke(
                [action] {},
                [System.Windows.Threading.DispatcherPriority]::Background
            )
            $record = $null
            while (
                [WindowsSetupVolumePill.VolumeKeyboardHook]::
                    TryDequeue([ref] $record)
            ) {
                switch ($record.VirtualKey) {
                    0xAD {
                        $state = $audio.ToggleMute()
                    }
                    0xAE {
                        $state = $audio.Adjust(-$step)
                    }
                    0xAF {
                        $state = $audio.Adjust($step)
                    }
                    default {
                        continue
                    }
                }
                $percent =
                    [int] [Math]::Round(
                        $state.Volume * 100
                    )
                Show-VolumePill `
                    -Percent $percent `
                    -Muted $state.Muted
                $hideAt =
                    [DateTime]::UtcNow.AddMilliseconds(
                        1500
                    )
            }
            if (
                $window.IsVisible -and
                -not $script:OsdIsFadingOut -and
                [DateTime]::UtcNow -ge
                $hideAt
            ) {
                Start-HideVolumePill
                $hideAt = [DateTime]::MaxValue
            }
            Complete-HideVolumePill
            Start-Sleep -Milliseconds 5
        }
    }
    finally {
        [WindowsSetupVolumePill.VolumeKeyboardHook]::Uninstall()
        if ($audio) {
            $audio.Dispose()
        }
        if ($window.IsVisible) {
            $window.Close()
        }
        if ($mutex) {
            if ($mutexCreated) {
                $mutex.ReleaseMutex()
            }
            $mutex.Dispose()
        }
    }
}