function Show-NeovimMaintenanceStatus {
    if (-not $script:NeovimStashIssue) {
        return
    }

    $issue = $script:NeovimStashIssue

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host " Neovim Stash benötigt Aufmerksamkeit" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""

    Write-Warning (
        "Lokale Neovim-Änderungen konnten nach dem automatischen " +
        "Update nicht konfliktfrei wiederhergestellt werden."
    )

    Write-Host ""
    Write-Host "[STASH]"
    Write-Host ("  Repository:       {0}" -f $issue.SubmodulePath)
    Write-Host ("  Referenz:         {0}" -f $issue.StashRef)
    Write-Host ("  Commit:           {0}" -f $issue.StashCommit)
    Write-Host ("  Nachricht:        {0}" -f $issue.StashMessage)
    Write-Host ("  Restore ExitCode: {0}" -f $issue.RestoreExitCode)
    Write-Host ("  Ursprungs-Branch: {0}" -f $issue.OriginalBranch)
    Write-Host ("  Ursprungs-HEAD:   {0}" -f $issue.OriginalHead)
    Write-Host ("  Aktueller Branch: {0}" -f $issue.CurrentBranch)
    Write-Host ("  Aktueller HEAD:   {0}" -f $issue.CurrentHead)

    if ($issue.StashListEntry) {
        Write-Host ("  Stash-Liste:      {0}" -f $issue.StashListEntry)
    }

    if ($issue.UpdateError) {
        Write-Host ""
        Write-Host ("[UPDATE-FEHLER] {0}" -f $issue.UpdateError) `
            -ForegroundColor Red
    }

    if ($issue.OriginalStatus.Count -gt 0) {
        Write-Host ""
        Write-Host "[LOKALE ÄNDERUNGEN VOR DEM STASH]"
        foreach ($line in $issue.OriginalStatus) {
            Write-Host ("  {0}" -f $line)
        }
    }

    if ($issue.StashFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "[DATEIEN IM STASH]"
        foreach ($line in $issue.StashFiles) {
            Write-Host ("  {0}" -f $line)
        }
    }

    if ($issue.StashStat.Count -gt 0) {
        Write-Host ""
        Write-Host "[STASH STAT]"
        foreach ($line in $issue.StashStat) {
            Write-Host ("  {0}" -f $line)
        }
    }

    if ($issue.CurrentStatus.Count -gt 0) {
        Write-Host ""
        Write-Host "[AKTUELLER GIT-STATUS]"
        foreach ($line in $issue.CurrentStatus) {
            Write-Host ("  {0}" -f $line)
        }
    }

    Write-Host ""
    Write-Host "[WICHTIG]" -ForegroundColor Yellow
    Write-Host (
        "Das fehlgeschlagene 'stash pop' kann Teile der Änderungen " +
        "bereits in den Working Tree übernommen haben."
    )
    Write-Host (
        "Den Stash daher NICHT blind erneut anwenden. Zuerst Konflikte " +
        "und den aktuellen Git-Status prüfen."
    )

    Write-Host ""
    Write-Host "[DIAGNOSE-BEFEHLE]"
    Write-Host (
        '  git -C "{0}" status' `
            -f $issue.SubmodulePath
    )
    Write-Host (
        '  git -C "{0}" stash list' `
            -f $issue.SubmodulePath
    )
    Write-Host (
        '  git -C "{0}" stash show --stat "{1}"' `
            -f $issue.SubmodulePath, $issue.StashRef
    )
    Write-Host (
        '  git -C "{0}" stash show -p "{1}"' `
            -f $issue.SubmodulePath, $issue.StashRef
    )

    Write-Host ""
    Write-Host (
        "Wenn alle Konflikte aufgelöst und die lokalen Änderungen " +
        "vollständig geprüft wurden, kann der erhaltene Stash manuell " +
        "gelöscht werden:"
    )
    Write-Host (
        '  git -C "{0}" stash drop "{1}"' `
            -f $issue.SubmodulePath, $issue.StashRef
    )
}
