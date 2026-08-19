$repositoryRoot = Split-Path -Parent $PSScriptRoot

Describe "Package-Konfigurationsschema" {
    It "lädt die reale Package-Konfiguration erfolgreich" {
        {
            & (Join-Path $repositoryRoot "config\packages\index.ps1")
        } | Should Not Throw
    }

    It "enthält nur unterstützte Sources und vollständige Pflichtfelder" {
        $packages = & (Join-Path $repositoryRoot "config\packages\index.ps1")
        $supportedSources = @(
            "winget"
            "msstore"
            "chocolatey"
            "scoop"
        )

        foreach ($group in $packages.Keys) {
            foreach ($package in @($packages[$group])) {
                $package.ContainsKey("Id") | Should Be $true
                $package.ContainsKey("Name") | Should Be $true
                $package.ContainsKey("Source") | Should Be $true
                $package.ContainsKey("Update") | Should Be $true
                ($supportedSources -contains $package.Source) |
                    Should Be $true

                if ($package.Source -eq "scoop") {
                    $package.ContainsKey("Bucket") |
                        Should Be $true
                    [string]::IsNullOrWhiteSpace(
                        [string]$package.Bucket
                    ) |
                        Should Be $false
                }
            }
        }
    }

    It "referenziert nur vorhandene GameLibraries" {
        $packages = & (Join-Path $repositoryRoot "config\packages\index.ps1")
        $storage = Import-PowerShellDataFile `
            -LiteralPath (Join-Path $repositoryRoot "config\storage.psd1")

        foreach ($group in $packages.Keys) {
            foreach ($package in @($packages[$group])) {
                if ($package.ContainsKey("GameLibrary")) {
                    $storage.GameLibraries.ContainsKey(
                        [string]$package.GameLibrary
                    ) |
                        Should Be $true
                }
            }
        }
    }
}