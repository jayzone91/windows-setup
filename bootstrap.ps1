#Requires -RunAsAdministrator

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

if (-not $InternalRun) {
    $pwsh = (
        Get-Command `
            -Name "pwsh" `
            -ErrorAction Stop
    ).Source

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
        exit $LASTEXITCODE
    }

    if ($Warning) {
        $arguments += "-Warning"

        & $pwsh @arguments `
            1>$null `
            4>$null `
            5>$null `
            6>$null

        exit $LASTEXITCODE
    }

    & $pwsh @arguments *>$null
    exit $LASTEXITCODE
}

if (-not $Log) {
    $ProgressPreference = "SilentlyContinue"
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Root = $PSScriptRoot

. "$Root\bootstrap\index.ps1"