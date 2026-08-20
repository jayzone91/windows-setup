function Get-WindowsSetupPackageSummary {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Packages
    )

    $bySource = [ordered]@{}
    $byGroup = [ordered]@{}
    $total = 0

    foreach ($entry in $Packages.GetEnumerator() | Sort-Object Key) {
        $groupName = [string]$entry.Key
        $groupPackages = @($entry.Value)

        if ($entry.Value -is [string]) {
            continue
        }

        $groupCount = 0

        foreach ($package in $groupPackages) {
            if (-not ($package -is [hashtable])) {
                continue
            }

            $groupCount++
            $total++

            $source = if ($package.ContainsKey("Source")) {
                [string]$package.Source
            }
            else {
                "unknown"
            }

            if (-not $bySource.Contains($source)) {
                $bySource[$source] = 0
            }

            $bySource[$source]++
        }

        $byGroup[$groupName] = $groupCount
    }

    return [ordered]@{
        Total    = $total
        BySource = $bySource
        ByGroup  = $byGroup
    }
}


function Write-WindowsSetupSummary {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryPath,

        [Parameter(Mandatory)]
        [hashtable]$Packages,

        [Parameter(Mandatory)]
        $WindowsUpdateStatus,

        [Parameter(Mandatory)]
        [bool]$DriverRebootRequired,

        [Parameter(Mandatory)]
        $PendingRebootStatus,

        [Parameter(Mandatory)]
        $RepositoryStatus,

        $PackageChanges,

        $RunLogContext
    )

    $logDirectory = Join-Path $RepositoryPath ".generated\logs"

    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        New-Item `
            -ItemType Directory `
            -Path $logDirectory `
            -Force |
        Out-Null
    }

    $summaryPath = Join-Path `
        $logDirectory `
        "bootstrap-last-summary.json"

    if ($null -ne $RunLogContext) {
        if (-not (Test-Path -LiteralPath $RunLogContext.LogDirectory -PathType Container)) {
            New-Item `
                -ItemType Directory `
                -Path $RunLogContext.LogDirectory `
                -Force |
            Out-Null
        }
    }

    $summary = [ordered]@{
        SchemaVersion = 1
        Timestamp     = (Get-Date).ToString("o")
        Status        = "Success"
        Packages      = [ordered]@{
            Managed = Get-WindowsSetupPackageSummary -Packages $Packages
            Changes = @(
                foreach ($change in @($PackageChanges)) {
                    [ordered]@{
                        Action = [string]$change.Action
                        Source = [string]$change.Source
                        Id     = [string]$change.Id
                    }
                }
            )
        }
        Updates       = [ordered]@{
            Windows = [ordered]@{
                InstalledCount = @(
                    $WindowsUpdateStatus.InstalledUpdates
                ).Count
                Installed = @(
                    foreach ($update in @(
                        $WindowsUpdateStatus.InstalledUpdates
                    )) {
                        [ordered]@{
                            Title = [string]$update.Title
                        }
                    }
                )
                RebootRequired = [bool]$WindowsUpdateStatus.RebootRequired
            }
        }
        Reboot        = [ordered]@{
            Required             = [bool]$PendingRebootStatus.RebootRequired
            Reasons              = @($PendingRebootStatus.Reasons)
            WindowsUpdateRequired = [bool]$WindowsUpdateStatus.RebootRequired
            DriverRequired       = $DriverRebootRequired
        }
        Repository    = [ordered]@{
            HasChanges      = [bool]$RepositoryStatus.HasChanges
            ChangedFiles    = @($RepositoryStatus.ChangedFiles)
            UnpushedCommits = [int]$RepositoryStatus.UnpushedCommits
        }
    }

    $json = $summary |
        ConvertTo-Json -Depth 8

    [IO.File]::WriteAllText(
        $summaryPath,
        $json,
        [Text.UTF8Encoding]::new($false)
    )

    if ($null -ne $RunLogContext) {
        $runSummaryPath = Join-Path `
            $RunLogContext.LogDirectory `
            ('{0}-summary.json' -f $RunLogContext.FileStem)

        [IO.File]::WriteAllText(
            $runSummaryPath,
            $json,
            [Text.UTF8Encoding]::new($false)
        )

        Write-Host (
            "[REPORT] Run-Abschlussreport: {0}" -f
            $runSummaryPath
        )
    }

    Write-Host (
        "[REPORT] Maschinenlesbarer Abschlussreport: {0}" -f
        $summaryPath
    )

    return $summaryPath
}