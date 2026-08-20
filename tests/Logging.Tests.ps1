$repositoryRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $repositoryRoot 'modules\Logging.ps1')

Describe 'Persistentes Bootstrap-Logging' {
    It 'erzeugt einen eindeutigen Run-Log-Kontext unter .generated\logs\runs' {
        $tempRoot = Join-Path `
            ([IO.Path]::GetTempPath()) `
            ('windows-setup-log-' + [guid]::NewGuid().ToString('N'))

        try {
            $context = New-WindowsSetupRunLogContext `
                -RepositoryPath $tempRoot

            $expectedDirectory = Join-Path `
                $tempRoot `
                '.generated\logs\runs'

            (Test-Path -LiteralPath $expectedDirectory -PathType Container) |
                Should Be $true

            (Split-Path -Parent $context.Path) |
                Should Be $expectedDirectory

            (Split-Path -Leaf $context.Path) |
                Should Match '^bootstrap-\d{8}-\d{9}-\d+\.log$'

            $context.StartedAt |
                Should Not BeNullOrEmpty

            $context.FileStem |
                Should Match '^bootstrap-\d{8}-\d{9}-\d+$'
        }
        finally {
            if (Test-Path -LiteralPath $tempRoot) {
                Remove-Item `
                    -LiteralPath $tempRoot `
                    -Recurse `
                    -Force
            }
        }
    }

    It 'benennt abgeschlossene Logs mit dem Ergebnisstatus um' {
        $tempRoot = Join-Path `
            ([IO.Path]::GetTempPath()) `
            ('windows-setup-log-' + [guid]::NewGuid().ToString('N'))

        try {
            $context = New-WindowsSetupRunLogContext `
                -RepositoryPath $tempRoot

            [IO.File]::WriteAllText(
                $context.Path,
                'test',
                [Text.UTF8Encoding]::new($false)
            )

            Mock Stop-Transcript {}

            Stop-WindowsSetupRunLogging `
                -Context $context `
                -Status 'Success'

            $expectedPath = Join-Path `
                $context.LogDirectory `
                ($context.FileStem + '-success.log')

            (Test-Path -LiteralPath $expectedPath -PathType Leaf) |
                Should Be $true
        }
        finally {
            if (Test-Path -LiteralPath $tempRoot) {
                Remove-Item `
                    -LiteralPath $tempRoot `
                    -Recurse `
                    -Force
            }
        }
    }}
