function Invoke-WallpaperGitRetry {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string] $GitPath,

        [Parameter(Mandatory)]
        [string[]] $Arguments,

        [int] $Attempts = 1,

        [int] $InitialDelaySeconds = 0
    )

    $lastOutput = @()
    $lastExitCode = 1

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        $lastOutput = @(
            & $GitPath @Arguments 2>&1
        )

        $lastExitCode = $LASTEXITCODE

        if ($lastExitCode -eq 0) {
            return [pscustomobject]@{
                Success  = $true
                Output   = $lastOutput
                ExitCode = 0
            }
        }

        if ($attempt -lt $Attempts) {
            $delaySeconds = $InitialDelaySeconds * $attempt

            Write-Warning (
                "Temporärer Git-Fehler beim Wallpaper-Repository. " +
                "Versuch {0}/{1} fehlgeschlagen." -f
                $attempt,
                $Attempts
            )

            if ($delaySeconds -gt 0) {
                Start-Sleep -Seconds $delaySeconds
            }
        }
    }

    return [pscustomobject]@{
        Success  = $false
        Output   = $lastOutput
        ExitCode = $lastExitCode
    }
}
