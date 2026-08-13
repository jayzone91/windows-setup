function Get-WindowsVolumeOsdRepositoryPath {
    return Split-Path `
        -Parent (
            Split-Path `
                -Parent $PSScriptRoot
        )
}

function Get-WindowsVolumeOsdPidPath {
    $repositoryPath = Get-WindowsVolumeOsdRepositoryPath

    return Join-Path `
        $repositoryPath `
        ".generated\state\volume-osd\instance.pid"
}

function Test-WindowsVolumeOsdCommandLine {
    param(
        [AllowNull()]
        [string] $CommandLine
    )

    if ([string]::IsNullOrWhiteSpace($CommandLine)) {
        return $false
    }

    return (
        $CommandLine -like "*\modules\VolumeOsd\*" -or
        $CommandLine -like "*\.generated\volume-osd\*"
    )
}

function Get-WindowsVolumeOsdProcesses {
    $processesById = @{}
    $pidPath = Get-WindowsVolumeOsdPidPath

    if (Test-Path -LiteralPath $pidPath -PathType Leaf) {
        $pidText = (
            Get-Content `
                -LiteralPath $pidPath `
                -Raw `
                -ErrorAction SilentlyContinue
        )

        $instanceId = 0

        if (
            -not [string]::IsNullOrWhiteSpace($pidText) -and
            [int]::TryParse(
                $pidText.Trim(),
                [ref] $instanceId
            )
        ) {
            $pidProcess = Get-CimInstance `
                -ClassName Win32_Process `
                -Filter "ProcessId = $instanceId" `
                -ErrorAction SilentlyContinue

            if (
                $pidProcess -and
                $pidProcess.Name -ieq "pwsh.exe" -and
                (
                    Test-WindowsVolumeOsdCommandLine `
                        -CommandLine $pidProcess.CommandLine
                )
            ) {
                $processesById[[int] $pidProcess.ProcessId] = $pidProcess
            }
        }
    }

    Get-CimInstance `
        -ClassName Win32_Process `
        -Filter "Name = 'pwsh.exe'" `
        -ErrorAction SilentlyContinue |
    Where-Object {
        Test-WindowsVolumeOsdCommandLine `
            -CommandLine $_.CommandLine
    } |
    ForEach-Object {
        $processesById[[int] $_.ProcessId] = $_
    }

    return @($processesById.Values)
}

function Wait-WindowsVolumeOsdMutexAvailable {
    param(
        [ValidateRange(1, 60)]
        [int] $TimeoutSeconds = 10
    )

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)

    while ([DateTime]::UtcNow -lt $deadline) {
        $probe = $null
        $probeOwned = $false

        try {
            $probe = [System.Threading.Mutex]::new(
                $false,
                "Local\WindowsSetupVolumeOsd"
            )

            try {
                $probeOwned = $probe.WaitOne(0)
            }
            catch [System.Threading.AbandonedMutexException] {
                # Ein abgebrochener Besitzer gilt als freigegeben; der aktuelle
                # Thread besitzt den Mutex nach dieser Exception.
                $probeOwned = $true
            }

            if ($probeOwned) {
                $probe.ReleaseMutex()
                $probeOwned = $false
                return
            }
        }
        finally {
            if ($probe) {
                if ($probeOwned) {
                    try {
                        $probe.ReleaseMutex()
                    }
                    catch {
                        Write-Verbose (
                            "Probe-Mutex konnte beim Cleanup nicht freigegeben " +
                            "werden: {0}" -f $_.Exception.Message
                        )
                    }
                }

                $probe.Dispose()
            }
        }

        Start-Sleep -Milliseconds 100
    }

    throw (
        "Volume-OSD-Mutex 'Local\WindowsSetupVolumeOsd' wurde nicht " +
        "innerhalb von {0} Sekunden frei." -f
        $TimeoutSeconds
    )
}

function Stop-WindowsVolumeOsdProcesses {
    $processes = @(
        Get-WindowsVolumeOsdProcesses
    )

    foreach ($process in $processes) {
        try {
            Stop-Process `
                -Id $process.ProcessId `
                -Force `
                -ErrorAction Stop
        }
        catch {
            throw (
                "Volume-OSD-Prozess konnte nicht beendet werden: " +
                "PID {0}. {1}" -f
                $process.ProcessId,
                $_.Exception.Message
            )
        }
    }

    foreach ($process in $processes) {
        $deadline = [DateTime]::UtcNow.AddSeconds(10)

        while (
            (Get-Process -Id $process.ProcessId -ErrorAction SilentlyContinue) -and
            [DateTime]::UtcNow -lt $deadline
        ) {
            Start-Sleep -Milliseconds 100
        }

        if (
            Get-Process `
                -Id $process.ProcessId `
                -ErrorAction SilentlyContinue
        ) {
            throw (
                "Volume-OSD-Prozess PID {0} wurde nicht innerhalb " +
                "von 10 Sekunden beendet." -f
                $process.ProcessId
            )
        }
    }

    $remaining = @(
        Get-WindowsVolumeOsdProcesses
    )

    if ($remaining.Count -gt 0) {
        throw (
            "Volume OSD konnte nicht vollständig beendet werden. " +
            "Verbleibende PID(s): " +
            (($remaining.ProcessId | Sort-Object -Unique) -join ", ")
        )
    }

    $pidPath = Get-WindowsVolumeOsdPidPath

    if (Test-Path -LiteralPath $pidPath -PathType Leaf) {
        Remove-Item `
            -LiteralPath $pidPath `
            -Force
    }

    Wait-WindowsVolumeOsdMutexAvailable
}

function Get-WindowsVolumeOsdLogTail {
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Label
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return " {0} wurde nicht erzeugt." -f $Label
    }

    $lines = @(
        Get-Content `
            -LiteralPath $Path `
            -Tail 20 `
            -ErrorAction SilentlyContinue
    )

    if ($lines.Count -eq 0) {
        return " {0} ist leer." -f $Label
    }

    return " {0}: {1}" -f $Label, ($lines -join " | ")
}

function Get-WindowsVolumeOsdStartupDiagnostics {
    $repositoryPath = Get-WindowsVolumeOsdRepositoryPath
    $logRoot = Join-Path `
        $repositoryPath `
        ".generated\logs"

    $startup = Get-WindowsVolumeOsdLogTail `
        -Path (Join-Path $logRoot "volume-osd-startup.log") `
        -Label "Startup-Log"

    $vbs = Get-WindowsVolumeOsdLogTail `
        -Path (Join-Path $logRoot "volume-osd-vbs.log") `
        -Label "VBS-Log"

    return $startup + $vbs
}