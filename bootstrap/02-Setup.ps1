$repositoryStatus =
Get-WindowsSetupRepositoryStatus `
    -RepositoryPath $Root

if ($repositoryStatus.HasChanges) {

    Write-Host ""
    Write-Host "[INFO] Lokale Repository-Änderungen:"

    foreach ($file in $repositoryStatus.ChangedFiles) {
        Write-Host "  - $file"
    }
}

if ($repositoryStatus.UnpushedCommits -gt 0) {
    Write-Host (
        "[INFO] Ungepushte Commits: {0}" `
            -f $repositoryStatus.UnpushedCommits
    )
}

Show-NeovimMaintenanceStatus

Write-WindowsSetupPerformanceCheckpoint -Name "Repository-/Wartungsstatus"

Send-WindowsSetupNotifications `
    -WindowsUpdateRebootRequired $script:windowsUpdateStatus.RebootRequired `
    -DriverRebootRequired $script:DriverRebootRequired `
    -PendingReboot $script:rebootRequired `
    -RepositoryStatus $repositoryStatus `
    -RepositoryPath $Root
Write-WindowsSetupPerformanceCheckpoint -Name "Benachrichtigungen"
