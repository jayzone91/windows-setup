function New-WindowsSetupRunLogContext {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryPath
    )

    $startedAt = Get-Date
    $logDirectory = Join-Path $RepositoryPath '.generated\logs\runs'

    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        New-Item `
            -ItemType Directory `
            -Path $logDirectory `
            -Force |
        Out-Null
    }

    $fileName = 'bootstrap-{0}-{1}.log' -f `
        $startedAt.ToString('yyyyMMdd-HHmmssfff'), `
        $PID

    return [pscustomobject]@{
        Path      = Join-Path $logDirectory $fileName
        StartedAt = $startedAt
    }
}

function Start-WindowsSetupRunLogging {
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryPath
    )

    $context = New-WindowsSetupRunLogContext `
        -RepositoryPath $RepositoryPath

    try {
        Start-Transcript `
            -LiteralPath $context.Path `
            -Force |
        Out-Null

        return $context
    }
    catch {
        Write-Warning (
            'Persistentes Bootstrap-Logging konnte nicht gestartet werden: {0}' -f
            $_.Exception.Message
        )

        return $null
    }
}

function Stop-WindowsSetupRunLogging {
    param(
        $Context,

        [Parameter(Mandatory)]
        [ValidateSet('Success', 'Failed')]
        [string]$Status
    )

    if ($null -eq $Context) {
        return
    }

    $finishedAt = Get-Date

    Write-Host ''
    Write-Host (
        '[LOG] Laufstatus: {0}; Start: {1}; Ende: {2}' -f
        $Status,
        $Context.StartedAt.ToString('o'),
        $finishedAt.ToString('o')
    )

    try {
        Stop-Transcript | Out-Null
    }
    catch {
        Write-Warning (
            'Persistentes Bootstrap-Logging konnte nicht sauber beendet werden: {0}' -f
            $_.Exception.Message
        )
    }
}
