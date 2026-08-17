param(
    [switch] $Warning,

    [switch] $Log,

    [Parameter(DontShow)]
    [switch] $InternalRun
)

$ErrorActionPreference = "Stop"

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
    $elevationArguments = @(
        "-NoProfile"
        "-ExecutionPolicy"
        "Bypass"
        "-File"
        ('"{0}"' -f $PSCommandPath)
    )

    if ($Warning) {
        $elevationArguments += "-Warning"
    }

    if ($Log) {
        $elevationArguments += "-Log"
    }

    if ($InternalRun) {
        $elevationArguments += "-InternalRun"
    }

    try {
        $elevatedProcess = Start-Process `
            -FilePath $pwsh `
            -ArgumentList ($elevationArguments -join " ") `
            -WorkingDirectory $PSScriptRoot `
            -Verb RunAs `
            -Wait `
            -PassThru
    }
    catch {
        throw (
            "Administratorrechte konnten nicht angefordert werden: {0}" -f
            $_.Exception.Message
        )
    }

    if ($elevatedProcess.ExitCode -ne 0) {
        $lastErrorPath = Join-Path `
            $Root `
            ".generated\logs\bootstrap-last-error.log"

        Write-Error (
            "Bootstrap fehlgeschlagen. Fehlerlog: {0}" -f
            $lastErrorPath
        )
    }

    exit $elevatedProcess.ExitCode
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