function Get-WindhawkCompilerPath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    $cli = Get-WindhawkCliPath

    if (-not $cli) {
        return $null
    }

    $appRoot = Split-Path -Parent $cli
    $iniPath = Join-Path $appRoot "windhawk.ini"

    if (-not (Test-Path -LiteralPath $iniPath -PathType Leaf)) {
        return $null
    }

    $compilerEntry = Get-Content `
        -LiteralPath $iniPath `
        -ErrorAction Stop |
    Where-Object {
        $_ -match '^\s*CompilerPath\s*='
    } |
    Select-Object -First 1

    if (-not $compilerEntry) {
        return $null
    }

    $rawPath = (
        $compilerEntry -replace '^\s*CompilerPath\s*=\s*', ''
    ).Trim()

    if ([string]::IsNullOrWhiteSpace($rawPath)) {
        return $null
    }

    $expandedPath = [Environment]::ExpandEnvironmentVariables(
        $rawPath
    )

    if (-not [IO.Path]::IsPathRooted($expandedPath)) {
        $expandedPath = Join-Path $appRoot $expandedPath
    }

    return [IO.Path]::GetFullPath($expandedPath)
}

function Test-WindhawkDevelopmentTools {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $compilerPath = Get-WindhawkCompilerPath

    if ([string]::IsNullOrWhiteSpace($compilerPath)) {
        return $false
    }

    return Test-Path `
        -LiteralPath (Join-Path $compilerPath "bin\clang++.exe") `
        -PathType Leaf
}

function Install-WindhawkDevelopmentTools {
    [CmdletBinding()]
    param()

    if (Test-WindhawkDevelopmentTools) {
        Write-Host "[CURRENT] Windhawk Development Tools vorhanden." `
            -ForegroundColor Green

        return
    }

    $installedVersion = Get-InstalledWindhawkVersion

    if ([string]::IsNullOrWhiteSpace($installedVersion)) {
        throw (
            "Windhawk Development Tools fehlen und die installierte " +
            "Windhawk-Version konnte nicht ermittelt werden."
        )
    }

    Write-Host (
        "[PREREQUISITE] Windhawk Development Tools für Version {0}" -f
        $installedVersion
    )

    $installerUrl = (
        "https://github.com/ramensoftware/windhawk/releases/" +
        "download/{0}/windhawk_setup.exe" -f
        $installedVersion
    )

    $tempDirectory = Join-Path `
        $env:TEMP `
        "windows-setup-windhawk-devtools"

    $installerPath = Join-Path `
        $tempDirectory `
        "windhawk_setup.exe"

    New-Item `
        -ItemType Directory `
        -Path $tempDirectory `
        -Force |
    Out-Null

    try {
        Invoke-WebRequest `
            -Uri $installerUrl `
            -OutFile $installerPath `
            -UseBasicParsing `
            -ErrorAction Stop

        $process = Start-Process `
            -FilePath $installerPath `
            -ArgumentList "/AUTO_REINSTALL /DEVTOOLS" `
            -Wait `
            -PassThru

        if ($process.ExitCode -ne 0) {
            throw (
                "Windhawk Development-Tools-Installer ExitCode: " +
                $process.ExitCode
            )
        }

        for ($attempt = 0; $attempt -lt 120; $attempt++) {
            if (Test-WindhawkDevelopmentTools) {
                Write-Host (
                    "[OK] Windhawk Development Tools installiert."
                ) -ForegroundColor Green

                return
            }

            Start-Sleep -Seconds 1
        }

        throw (
            "Windhawk Development Tools wurden nach dem Installer " +
            "nicht innerhalb von 120 Sekunden erkannt."
        )
    }
    finally {
        Remove-Item `
            -LiteralPath $installerPath `
            -Force `
            -ErrorAction SilentlyContinue
    }
}
