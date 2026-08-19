$repositoryRoot = Split-Path -Parent $PSScriptRoot
$packageScript = Join-Path `
    $repositoryRoot `
    "modules\Packages\01-Test-WingetPackage.ps1"

. $packageScript

Describe "Winget Paket-Versionserkennung" {
    BeforeEach {
        $script:WingetTestOutput = @()
        $script:WingetTestExitCode = 0

        function global:winget {
            $global:LASTEXITCODE = $script:WingetTestExitCode
            $script:WingetTestOutput
        }
    }

    AfterEach {
        Remove-Item `
            -Path Function:\global:winget `
            -ErrorAction SilentlyContinue
    }

    It "erkennt eine installierte Version anhand der exakten Paket-ID" {
        $script:WingetTestOutput = @(
            "Name                  ID             Version Quelle"
            "----------------------------------------------------"
            "OpenVPN Connect       OpenVPN.OpenVPN 2.7.101 winget"
        )

        $result = Get-WingetInstalledVersion `
            -Id "OpenVPN.OpenVPN" `
            -Source "winget"

        $result | Should Be "2.7.101"
    }

    It "ignoriert ähnlich benannte Paket-IDs" {
        $script:WingetTestOutput = @(
            "Name                  ID                    Version Quelle"
            "----------------------------------------------------------------"
            "Falsches Paket        OpenVPN.OpenVPN.Test   9.9.9   winget"
            "OpenVPN Connect       OpenVPN.OpenVPN        2.7.101 winget"
        )

        $result = Get-WingetInstalledVersion `
            -Id "OpenVPN.OpenVPN" `
            -Source "winget"

        $result | Should Be "2.7.101"
    }

    It "entfernt ANSI-Sequenzen vor der Versionsauswertung" {
        $escape = [char]27

        $script:WingetTestOutput = @(
            (
                "{0}[32mOpenVPN Connect  OpenVPN.OpenVPN  2.7.101  winget{0}[0m" `
                    -f $escape
            )
        )

        $result = Get-WingetInstalledVersion `
            -Id "OpenVPN.OpenVPN" `
            -Source "winget"

        $result | Should Be "2.7.101"
    }

    It "liefert null wenn winget list fehlschlägt" {
        $script:WingetTestExitCode = 1

        $result = Get-WingetInstalledVersion `
            -Id "OpenVPN.OpenVPN" `
            -Source "winget"

        $result | Should BeNullOrEmpty
    }

    It "liefert null wenn die Paket-ID nicht in der Ausgabe vorkommt" {
        $script:WingetTestOutput = @(
            "Name            ID             Version Quelle"
            "------------------------------------------------"
            "Git             Git.Git        2.55.0  winget"
        )

        $result = Get-WingetInstalledVersion `
            -Id "OpenVPN.OpenVPN" `
            -Source "winget"

        $result | Should BeNullOrEmpty
    }
}