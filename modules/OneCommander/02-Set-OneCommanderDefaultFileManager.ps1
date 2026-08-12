$script:WindowsSetupSourceRoot_modules_OneCommander = Split-Path -Parent $PSScriptRoot

function Set-OneCommanderDefaultFileManager {
    [CmdletBinding()]
    param()

    $exe = Get-OneCommanderExecutablePath

    if (-not $exe) {
        throw "OneCommander.exe wurde nicht gefunden."
    }

    Write-Host "[INFO] Registriere OneCommander als Standard-Dateimanager."

    #
    # Directory
    #
    $directoryShell =
    "HKCU:\Software\Classes\Directory\shell"

    $directoryEntry =
    Join-Path `
        $directoryShell `
        "OpenInOneCommander"

    $directoryCommand =
    Join-Path `
        $directoryEntry `
        "command"

    New-Item `
        -Path $directoryEntry `
        -Force |
    Out-Null

    New-Item `
        -Path $directoryCommand `
        -Force |
    Out-Null

    Set-Item `
        -Path $directoryEntry `
        -Value "Öffnen in OneCommander"

    Set-ItemProperty `
        -Path $directoryEntry `
        -Name "Icon" `
        -Value $exe `
        -Force

    Set-Item `
        -Path $directoryCommand `
        -Value "`"$exe`" -`"%1`""

    Set-Item `
        -Path $directoryShell `
        -Value "OpenInOneCommander"

    #
    # Directory Background
    #
    $directoryBackgroundEntry =
    "HKCU:\Software\Classes\Directory\Background\shell\OpenInOneCommander"

    $directoryBackgroundCommand =
    Join-Path `
        $directoryBackgroundEntry `
        "command"

    New-Item `
        -Path $directoryBackgroundEntry `
        -Force |
    Out-Null

    New-Item `
        -Path $directoryBackgroundCommand `
        -Force |
    Out-Null

    Set-Item `
        -Path $directoryBackgroundEntry `
        -Value "Öffnen in OneCommander"

    Set-ItemProperty `
        -Path $directoryBackgroundEntry `
        -Name "Icon" `
        -Value $exe `
        -Force

    Set-Item `
        -Path $directoryBackgroundCommand `
        -Value "`"$exe`" -`"%W`""

    #
    # Drive
    #
    $driveShell =
    "HKCU:\Software\Classes\Drive\shell"

    $driveEntry =
    Join-Path `
        $driveShell `
        "OpenInOneCommander"

    $driveCommand =
    Join-Path `
        $driveEntry `
        "command"

    New-Item `
        -Path $driveEntry `
        -Force |
    Out-Null

    New-Item `
        -Path $driveCommand `
        -Force |
    Out-Null

    Set-Item `
        -Path $driveEntry `
        -Value "Öffnen in OneCommander"

    Set-ItemProperty `
        -Path $driveEntry `
        -Name "Icon" `
        -Value $exe `
        -Force

    Set-Item `
        -Path $driveCommand `
        -Value "`"$exe`" -`"%1`""

    Set-Item `
        -Path $driveShell `
        -Value "OpenInOneCommander"

    #
    # Drive Background
    #
    $driveBackgroundEntry =
    "HKCU:\Software\Classes\Drive\background\shell\OpenInOneCommander"

    $driveBackgroundCommand =
    Join-Path `
        $driveBackgroundEntry `
        "command"

    New-Item `
        -Path $driveBackgroundEntry `
        -Force |
    Out-Null

    New-Item `
        -Path $driveBackgroundCommand `
        -Force |
    Out-Null

    Set-Item `
        -Path $driveBackgroundEntry `
        -Value "Öffnen in OneCommander"

    Set-ItemProperty `
        -Path $driveBackgroundEntry `
        -Name "Icon" `
        -Value $exe `
        -Force

    Set-Item `
        -Path $driveBackgroundCommand `
        -Value "`"$exe`" -`"%W`""

    #
    # Explorer OpenNewWindow / Win + E
    #
    $clsidCommand =
    "HKCU:\Software\Classes\CLSID\{52205fd8-5dfb-447d-801a-d0b52f2e83e1}\shell\opennewwindow\command"

    New-Item `
        -Path $clsidCommand `
        -Force |
    Out-Null

    Set-Item `
        -Path $clsidCommand `
        -Value $exe

    New-ItemProperty `
        -Path $clsidCommand `
        -Name "DelegateExecute" `
        -PropertyType String `
        -Value "" `
        -Force |
    Out-Null

    Write-Host (
        "[OK] OneCommander als Standard-Dateimanager registriert."
    ) -ForegroundColor Green
}


function Install-OneCommanderTheme {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    $source = Join-Path `
        $RepositoryPath `
        "dotfiles\onecommander\Themes\CatppuccinMocha"

    $destination = Join-Path `
        $env:LOCALAPPDATA `
        "OneCommander\Themes\CatppuccinMocha"

    Set-DirectoryJunction `
        -Path $destination `
        -Target $source
}


function Remove-OneCommanderGeneratedIconCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if (-not (Test-Path $Path)) {
        return
    }

    Get-ChildItem `
        -Path $Path `
        -Directory `
        -Force `
        -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match '^\d+$'
    } |
    ForEach-Object {
        Write-Host (
            "[INFO] Entferne generierten OneCommander-Icon-Cache: " +
            $_.FullName
        )

        Remove-Item `
            -Path $_.FullName `
            -Recurse `
            -Force
    }
}


function Install-OneCommanderIcons {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    $buildFileIconsScript = Join-Path `
    (Split-Path -Path $script:WindowsSetupSourceRoot_modules_OneCommander -Parent) `
        "scripts\Build-OneCommanderFileIcons.ps1"

    if (Test-Path $buildFileIconsScript) {
        . $buildFileIconsScript
    }

    $iconsRoot = Join-Path `
        $RepositoryPath `
        "dotfiles\onecommander\Icons"

    #
    # Main Folder Icon
    #
    # OneCommander erwartet diese Datei direkt im MainFolderIcon-Verzeichnis.
    # Einzeldateien werden deshalb bewusst kopiert; Theme-Packs bleiben Junctions.
    #
    $mainFolderIconSource = Join-Path `
        $iconsRoot `
        "MainFolderIcon\CatppuccinMocha.png"

    if (-not (Test-Path $mainFolderIconSource)) {
        throw (
            "Catppuccin Main Folder Icon nicht vorhanden: " +
            $mainFolderIconSource
        )
    }

    $mainFolderIconDirectory = Join-Path `
        $env:LOCALAPPDATA `
        "OneCommander\Resources\MainFolderIcon"

    $mainFolderIconDestination = Join-Path `
        $mainFolderIconDirectory `
        "CatppuccinMocha.png"

    New-Item `
        -ItemType Directory `
        -Path $mainFolderIconDirectory `
        -Force |
    Out-Null

    if (Test-Path $mainFolderIconDestination) {
        $item = Get-Item `
            -Path $mainFolderIconDestination `
            -Force

        if (
            $item.Attributes -band
            [System.IO.FileAttributes]::ReparsePoint
        ) {
            Remove-Item `
                -Path $mainFolderIconDestination `
                -Force
        }
    }

    Copy-Item `
        -Path $mainFolderIconSource `
        -Destination $mainFolderIconDestination `
        -Force

    Write-Host (
        "[OK] Catppuccin Main Folder Icon installiert."
    ) -ForegroundColor Green

    #
    # Folder Icon Theme
    #
    $folderIconsSource = Join-Path `
        $iconsRoot `
        "FolderIcons\CatppuccinMocha"

    if (Test-Path $folderIconsSource) {
        Remove-OneCommanderGeneratedIconCache `
            -Path $folderIconsSource

        Set-DirectoryJunction `
            -Path (
            Join-Path `
                $env:LOCALAPPDATA `
                "OneCommander\Resources\FolderIcons\CatppuccinMocha"
        ) `
            -Target $folderIconsSource
    }
    else {
        Write-Host (
            "[INFO] Catppuccin Folder-Icon-Theme noch nicht vorhanden."
        )
    }

    #
    # File Icon Theme
    #
    $fileIconsSource = Join-Path `
        $RepositoryPath `
        ".generated\onecommander\FileIcons\CatppuccinMocha"

    $fileIconsManifest = Join-Path `
        $fileIconsSource `
        "_manifest.json"

    if (-not (Test-Path $fileIconsManifest)) {
        Write-Host (
            "[INFO] Catppuccin File-Icons fehlen. " +
            "Erzeuge vollständiges Icon-Pack."
        )

        Build-OneCommanderFileIcons `
            -RepositoryPath $RepositoryPath
    }

    if (-not (Test-Path $fileIconsManifest)) {
        throw (
            "Catppuccin File-Icon-Pack konnte nicht erzeugt werden: " +
            $fileIconsSource
        )
    }

    Remove-OneCommanderGeneratedIconCache `
        -Path $fileIconsSource

    Set-DirectoryJunction `
        -Path (
        Join-Path `
            $env:LOCALAPPDATA `
            "OneCommander\Resources\FileIcons\CatppuccinMocha"
    ) `
        -Target $fileIconsSource
}




function Test-OneCommanderJunction {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Target
    )

    $item = Get-Item `
        -LiteralPath $Path `
        -Force `
        -ErrorAction SilentlyContinue

    if (-not $item) {
        return $false
    }

    if (
        -not (
            $item.Attributes -band
            [System.IO.FileAttributes]::ReparsePoint
        ) -or
        $item.LinkType -ne "Junction"
    ) {
        return $false
    }

    return [string]$item.Target -eq $Target
}