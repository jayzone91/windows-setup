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
}
