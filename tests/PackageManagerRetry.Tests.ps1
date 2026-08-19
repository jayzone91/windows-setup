$repositoryRoot = Split-Path -Parent $PSScriptRoot
$packageScript = Join-Path `
    $repositoryRoot `
    "modules\Packages\02-Install-ChocolateyPackage.ps1"

. $packageScript

Describe "Paketmanager-Retry" {
    BeforeEach {
        $script:RetryTestAttempts = 0
        $script:RetryTestExitCodes = @()
        $script:RetryTestArguments = @()

        function global:Invoke-RetryTestCommand {
            $script:RetryTestAttempts++
            $script:RetryTestArguments = @($args)

            $index = [Math]::Min(
                $script:RetryTestAttempts - 1,
                $script:RetryTestExitCodes.Count - 1
            )

            $global:LASTEXITCODE = $script:RetryTestExitCodes[$index]
        }
    }

    AfterEach {
        Remove-Item `
            -Path Function:\global:Invoke-RetryTestCommand `
            -ErrorAction SilentlyContinue
    }

    It "liefert beim ersten erfolgreichen Versuch sofort den ExitCode" {
        $script:RetryTestExitCodes = @(0)

        $result = Invoke-PackageManagerCommandWithRetry `
            -Command "Invoke-RetryTestCommand" `
            -Arguments @("update", "test") `
            -SuccessExitCodes @(0) `
            -RetryDelaySeconds 0

        $result | Should Be 0
        $script:RetryTestAttempts | Should Be 1
        $script:RetryTestArguments.Count | Should Be 2
        $script:RetryTestArguments[0] | Should Be "update"
        $script:RetryTestArguments[1] | Should Be "test"
    }

    It "wiederholt einen fehlgeschlagenen Aufruf einmal" {
        $script:RetryTestExitCodes = @(1, 0)

        $result = Invoke-PackageManagerCommandWithRetry `
            -Command "Invoke-RetryTestCommand" `
            -Arguments @("update") `
            -SuccessExitCodes @(0) `
            -RetryDelaySeconds 0

        $result | Should Be 0
        $script:RetryTestAttempts | Should Be 2
    }

    It "liefert nach dem letzten fehlgeschlagenen Versuch den ExitCode" {
        $script:RetryTestExitCodes = @(1, 2)

        $result = Invoke-PackageManagerCommandWithRetry `
            -Command "Invoke-RetryTestCommand" `
            -Arguments @("update") `
            -SuccessExitCodes @(0) `
            -RetryDelaySeconds 0

        $result | Should Be 2
        $script:RetryTestAttempts | Should Be 2
    }

    It "akzeptiert mehrere erfolgreiche ExitCodes" {
        $script:RetryTestExitCodes = @(3010)

        $result = Invoke-PackageManagerCommandWithRetry `
            -Command "Invoke-RetryTestCommand" `
            -Arguments @("upgrade") `
            -SuccessExitCodes @(0, 1641, 3010) `
            -RetryDelaySeconds 0

        $result | Should Be 3010
        $script:RetryTestAttempts | Should Be 1
    }
}
