$repositoryRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $repositoryRoot "modules\Reporting.ps1")

Describe "Maschinenlesbarer Abschlussreport" {
    It "fasst verwaltete Pakete nach Gruppe und Source zusammen" {
        $packages = @{
            Base = @(
                @{
                    Id     = "Example.One"
                    Name   = "One"
                    Source = "winget"
                }
            )
            Tools = @(
                @{
                    Id     = "Example.Two"
                    Name   = "Two"
                    Source = "scoop"
                }
                @{
                    Id     = "Example.Three"
                    Name   = "Three"
                    Source = "winget"
                }
            )
        }

        $summary = Get-WindowsSetupPackageSummary -Packages $packages

        $summary.Total | Should Be 3
        $summary.BySource.winget | Should Be 2
        $summary.BySource.scoop | Should Be 1
        $summary.ByGroup.Base | Should Be 1
        $summary.ByGroup.Tools | Should Be 2
    }

    It "schreibt einen parsebaren JSON-Abschlussreport" {
        $tempRoot = Join-Path `
            ([IO.Path]::GetTempPath()) `
            ("windows-setup-report-" + [guid]::NewGuid().ToString("N"))

        try {
            $packages = @{
                Base = @(
                    @{
                        Id     = "Example.One"
                        Name   = "One"
                        Source = "winget"
                    }
                )
            }

            $path = Write-WindowsSetupSummary `
                -RepositoryPath $tempRoot `
                -Packages $packages `
                -WindowsUpdateStatus ([pscustomobject]@{
                    InstalledUpdates = @(
                        [pscustomobject]@{
                            Title = "Example Update"
                        }
                    )
                    RebootRequired = $false
                }) `
                -DriverRebootRequired $false `
                -PendingRebootStatus ([pscustomobject]@{
                    RebootRequired = $false
                    Reasons = @()
                }) `
                -RepositoryStatus ([pscustomobject]@{
                    HasChanges = $false
                    ChangedFiles = @()
                    UnpushedCommits = 0
                }) `
                -PackageChanges @(
                    [pscustomobject]@{
                        Action = "Install"
                        Source = "winget"
                        Id = "Example.One"
                    }
                    [pscustomobject]@{
                        Action = "Update"
                        Source = "scoop"
                        Id = "Example.Tool"
                    }
                ) `
                -RunLogContext ([pscustomobject]@{
                    LogDirectory = Join-Path $tempRoot '.generated\logs\runs'
                    FileStem = 'bootstrap-test'
                })

            (Test-Path -LiteralPath $path -PathType Leaf) |
                Should Be $true

            $report = Get-Content -LiteralPath $path -Raw |
                ConvertFrom-Json

            $report.SchemaVersion | Should Be 1
            $report.Status | Should Be "Success"
            $report.Packages.Managed.Total | Should Be 1
            $report.Packages.InstalledCount | Should Be 1
            $report.Packages.UpdatedCount | Should Be 1
            $report.Packages.BySource.winget.InstalledCount | Should Be 1
            $report.Packages.BySource.winget.UpdatedCount | Should Be 0
            $report.Packages.BySource.scoop.InstalledCount | Should Be 0
            $report.Packages.BySource.scoop.UpdatedCount | Should Be 1
            $report.Packages.Changes.Count | Should Be 2
            $report.Updates.Windows.InstalledCount | Should Be 1
            $report.Updates.Windows.Installed[0].Title |
                Should Be "Example Update"
            $report.Updates.Windows.RebootRequired | Should Be $false
            $report.Reboot.Required | Should Be $false
            $report.Repository.HasChanges | Should Be $false

            $runSummaryPath = Join-Path `
                $tempRoot `
                '.generated\logs\runs\bootstrap-test-summary.json'

            (Test-Path -LiteralPath $runSummaryPath -PathType Leaf) |
                Should Be $true

            $runReport = Get-Content -LiteralPath $runSummaryPath -Raw |
                ConvertFrom-Json

            $runReport.Updates.Windows.InstalledCount |
                Should Be 1
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