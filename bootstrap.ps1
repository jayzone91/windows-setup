param(
    [switch] $Warning,

    [switch] $Log,

    [Parameter(DontShow)]
    [switch] $InternalRun
)

$ErrorActionPreference = "Stop"

$script:WindowsSetupPerformanceStopwatch = $null
$script:WindowsSetupPerformanceLastElapsed = [TimeSpan]::Zero

if ($env:WINDOWS_SETUP_PERFORMANCE_TRACE -eq "1") {
    if ([string]::IsNullOrWhiteSpace($env:WINDOWS_SETUP_PERFORMANCE_TRACE_PATH)) {
        throw "WINDOWS_SETUP_PERFORMANCE_TRACE_PATH fehlt."
    }

    $script:WindowsSetupPerformanceStopwatch = [Diagnostics.Stopwatch]::StartNew()
}

function Write-WindowsSetupPerformanceCheckpoint {
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    if ($null -eq $script:WindowsSetupPerformanceStopwatch) {
        return
    }

    $elapsed = $script:WindowsSetupPerformanceStopwatch.Elapsed
    $delta = $elapsed - $script:WindowsSetupPerformanceLastElapsed

    Add-Content `
        -LiteralPath $env:WINDOWS_SETUP_PERFORMANCE_TRACE_PATH `
        -Value ("{0}`t{1:F3}`t{2:F3}" -f $Name, $delta.TotalSeconds, $elapsed.TotalSeconds) `
        -Encoding utf8

    $script:WindowsSetupPerformanceLastElapsed = $elapsed
}

if ($Warning -and $Log) {
    throw "Die Parameter -Warning und -Log können nicht gleichzeitig verwendet werden."
}

function Test-WindowsSetupAdministrator {
    [OutputType([bool])]
    param()

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)

    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

function Test-WindowsSetupInternetConnection {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [int] $Attempts = 2,
        [int] $RetryDelaySeconds = 5
    )

    $uri = "http://www.msftconnecttest.com/connecttest.txt"

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            $response = Invoke-WebRequest `
                -Uri $uri `
                -TimeoutSec 5 `
                -UseBasicParsing `
                -ErrorAction Stop

            if (
                $response.StatusCode -eq 200 -and
                $response.Content.Trim() -eq "Microsoft Connect Test"
            ) {
                return $true
            }
        }
        catch {
            $null = $_
        }

        if ($attempt -lt $Attempts) {
            Write-Warning (
                "Keine Internetverbindung erkannt. " +
                "Neuer Versuch in $RetryDelaySeconds Sekunden."
            )

            Start-Sleep -Seconds $RetryDelaySeconds
        }
    }

    return $false
}

function Get-WindowsSetupLogPath {
    param(
        [Parameter(Mandatory)]
        [string] $Root
    )

    $logDirectory = Join-Path $Root ".generated\logs"

    if (-not (Test-Path -LiteralPath $logDirectory -PathType Container)) {
        New-Item `
            -ItemType Directory `
            -Path $logDirectory `
            -Force |
        Out-Null
    }

    return Join-Path `
        $logDirectory `
        "bootstrap-last-error.log"
}

$pwsh = (
    Get-Command `
        -Name "pwsh" `
        -ErrorAction Stop
).Source

$Root = $PSScriptRoot

if (-not (Test-WindowsSetupAdministrator)) {
    throw (
        "Der Bootstrap benötigt Administratorrechte. " +
        "Manuelle Projektläufe mit 'sudo just update', " +
        "'sudo just update-warning', 'sudo just update-log' oder " +
        "'sudo just update-performance' starten."
    )
}

if (-not (Test-WindowsSetupInternetConnection)) {
    . "$Root\modules\Notifications.ps1"

    Send-WindowsSetupOfflineNotification

    Write-Warning (
        "Keine Internetverbindung verfügbar. " +
        "Bootstrap wird ohne Änderungen beendet."
    )

    exit 0
}

if (-not $InternalRun) {
    $arguments = @(
        "-NoProfile"
        "-ExecutionPolicy"
        "Bypass"
        "-File"
        $PSCommandPath
        "-InternalRun"
    )

    if ($Log) {
        $arguments += "-Log"

        & $pwsh @arguments

        if ($LASTEXITCODE -ne 0) {
            $lastErrorPath = Join-Path `
                $Root `
                ".generated\logs\bootstrap-last-error.log"

            Write-Error (
                "Bootstrap fehlgeschlagen. Fehlerlog: {0}" -f
                $lastErrorPath
            )
        }

        exit $LASTEXITCODE
    }

    if ($Warning) {
        $arguments += "-Warning"

        & $pwsh @arguments `
            1>$null `
            4>$null `
            5>$null `
            6>$null

        if ($LASTEXITCODE -ne 0) {
            $lastErrorPath = Join-Path `
                $Root `
                ".generated\logs\bootstrap-last-error.log"

            Write-Error (
                "Bootstrap fehlgeschlagen. Fehlerlog: {0}" -f
                $lastErrorPath
            )
        }

        exit $LASTEXITCODE
    }

    & $pwsh @arguments *>$null

    if ($LASTEXITCODE -ne 0) {
        $lastErrorPath = Join-Path `
            $Root `
            ".generated\logs\bootstrap-last-error.log"

        Write-Error (
            "Bootstrap fehlgeschlagen. Fehlerlog: {0}" -f
            $lastErrorPath
        )
    }

    exit $LASTEXITCODE
}

if (-not $Log) {
    $ProgressPreference = "SilentlyContinue"
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$lastErrorPath = Get-WindowsSetupLogPath -Root $Root

try {
    . "$Root\bootstrap\index.ps1"

    Remove-Item `
        -LiteralPath $lastErrorPath `
        -Force `
        -ErrorAction SilentlyContinue
}
catch {
    $errorRecord = $_

    $details = @(
        "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff zzz')"
        "Message: $($errorRecord.Exception.Message)"
        "Category: $($errorRecord.CategoryInfo)"
        "FullyQualifiedErrorId: $($errorRecord.FullyQualifiedErrorId)"
        "ScriptStackTrace:"
        $errorRecord.ScriptStackTrace
        ""
        "PositionMessage:"
        $errorRecord.InvocationInfo.PositionMessage
        ""
        "ErrorRecord:"
        ($errorRecord | Out-String)
    ) -join [Environment]::NewLine

    [IO.File]::WriteAllText(
        $lastErrorPath,
        $details,
        [Text.UTF8Encoding]::new($false)
    )

    Write-Error (
        "Bootstrap fehlgeschlagen. Fehlerlog: {0}" -f
        $lastErrorPath
    )

    exit 1
}
