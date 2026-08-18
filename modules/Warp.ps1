function Get-WarpConfiguredPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Config,

        [Parameter(Mandatory)]
        [string] $Name,

        [string] $RepositoryPath
    )

    if (
        -not $Config.Contains($Name) -or
        [string]::IsNullOrWhiteSpace([string] $Config[$Name])
    ) {
        throw "Warp-Konfiguration enthält keinen Wert '$Name'."
    }

    $value = [Environment]::ExpandEnvironmentVariables(
        [string] $Config[$Name]
    )

    if ($RepositoryPath) {
        return Join-Path $RepositoryPath $value
    }

    return $value
}


function Set-WarpConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary] $Config,

        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Write-Host ""
    Write-Host "========================================"
    Write-Host " Warp"
    Write-Host "========================================"

    $settingsPath = Get-WarpConfiguredPath `
        -Config $Config `
        -Name "SettingsPath"

    $repositorySettingsPath = Get-WarpConfiguredPath `
        -Config $Config `
        -Name "RepositorySettingsPath" `
        -RepositoryPath $RepositoryPath

    if (-not (Test-Path -LiteralPath $repositorySettingsPath -PathType Leaf)) {
        throw "Versionierte Warp settings.toml fehlt: $repositorySettingsPath"
    }

    Set-FileHardLink `
        -Path $settingsPath `
        -Target $repositorySettingsPath `
        -ReplaceExistingFile

    if (-not $Config.Contains("Theme")) {
        throw "Warp-Konfiguration enthält keinen Theme-Bereich."
    }

    $themeConfig = $Config.Theme

    $themeRepositoryPath = Get-WarpConfiguredPath `
        -Config $themeConfig `
        -Name "RepositoryPath" `
        -RepositoryPath $RepositoryPath

    $themeTargetPath = Get-WarpConfiguredPath `
        -Config $themeConfig `
        -Name "TargetPath"

    if (-not (Test-Path -LiteralPath $themeRepositoryPath -PathType Leaf)) {
        throw "Versioniertes Warp-Theme fehlt: $themeRepositoryPath"
    }

    Set-FileHardLink `
        -Path $themeTargetPath `
        -Target $themeRepositoryPath `
        -ReplaceExistingFile

    Write-Host "[OK] Warp settings.toml und Theme verknüpft." `
        -ForegroundColor Green
}
