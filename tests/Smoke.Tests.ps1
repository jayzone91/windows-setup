$repositoryRoot = Split-Path -Parent $PSScriptRoot

Describe "Windows Setup Testbasis" {
    It "lädt die zentralen Helper ohne Fehler" {
        {
            . (Join-Path $repositoryRoot "modules\Helpers\index.ps1")
        } | Should Not Throw
    }

    It "lädt die PowerShell-Codecheck-Helper ohne Fehler" {
        {
            . (Join-Path $repositoryRoot "modules\PowerShell\index.ps1")
        } | Should Not Throw
    }

    It "enthält die erwarteten kritischen Helper" {
        . (Join-Path $repositoryRoot "modules\Helpers\index.ps1")

        Get-Command Test-DirectoryJunctionTarget -ErrorAction Stop |
            Should Not BeNullOrEmpty

        Get-Command Set-FileSymbolicLink -ErrorAction Stop |
            Should Not BeNullOrEmpty

        Get-Command Test-GitHubAvailability -ErrorAction Stop |
            Should Not BeNullOrEmpty
    }
}