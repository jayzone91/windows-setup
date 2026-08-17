function Test-GitHubAvailability {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [int] $Attempts = 3,
        [int] $InitialDelaySeconds = 2
    )

    if ($null -ne $script:GitHubAvailable) {
        return [bool] $script:GitHubAvailable
    }

    $uri = "https://api.github.com/meta"

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        try {
            $null = Invoke-RestMethod `
                -Uri $uri `
                -Headers @{
                    Accept       = "application/vnd.github+json"
                    "User-Agent" = "windows-setup"
                } `
                -TimeoutSec 10 `
                -ErrorAction Stop

            $script:GitHubAvailable = $true
            return $true
        }
        catch {
            $statusCode = if (
                $null -ne $_.Exception.Response -and
                $null -ne $_.Exception.Response.StatusCode
            ) {
                [int] $_.Exception.Response.StatusCode
            }
            else {
                $null
            }

            if ($attempt -lt $Attempts) {
                $delaySeconds = $InitialDelaySeconds * $attempt

                Write-Warning (
                    "GitHub ist aktuell nicht erreichbar" +
                    $(if ($null -ne $statusCode) { " (HTTP $statusCode)" } else { "" }) +
                    ". Neuer Versuch in $delaySeconds Sekunden " +
                    "($attempt/$Attempts)."
                )

                Start-Sleep -Seconds $delaySeconds
            }
        }
    }

    $script:GitHubAvailable = $false

    Write-Warning (
        "GitHub ist aktuell nicht erreichbar. " +
        "Nichtkritische GitHub-Schritte werden für diesen Bootstrap übersprungen."
    )

    return $false
}