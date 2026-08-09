function Get-PcVisitSupporterModulePath {
    $candidates = @()

    if (${env:ProgramFiles(x86)}) {
        $candidates += Join-Path `
            ${env:ProgramFiles(x86)} `
            "pcvisit Software AG\pcvisit Support\host.exe"
    }

    if ($env:ProgramFiles) {
        $candidates += Join-Path `
            $env:ProgramFiles `
            "pcvisit Software AG\pcvisit Support\host.exe"
    }

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return $null
}

function Install-PcVisitSupporterModule {
    Write-Host ""
    Write-Host "[CHECK] pcvisit Supporter-Modul"

    $installedPath = Get-PcVisitSupporterModulePath

    if ($installedPath) {
        Write-Host (
            "[OK] pcvisit Supporter-Modul ist installiert: {0}" `
                -f $installedPath
        ) -ForegroundColor Green

        Write-Host "[SKIP] Updates werden durch pcvisit selbst verwaltet."
        return
    }

    $downloadUrl = (
        "https://lb3.pcvisit.de/v1/hosted/jumplink" +
        "?destname=pcvisit_Supporter-Modul_Setup_SJ" +
        "&func=download" +
        "&os=osWin32" +
        "&topic=hostSetup"
    )

    $installerPath = Join-Path `
        ([System.IO.Path]::GetTempPath()) `
        "pcvisit-supporter-setup.exe"

    Write-Host "[DOWNLOAD] pcvisit Supporter-Modul" `
        -ForegroundColor Cyan

    try {
        Invoke-WebRequest `
            -Uri $downloadUrl `
            -OutFile $installerPath

        if (-not (Test-Path $installerPath)) {
            throw "pcvisit-Installer wurde nicht heruntergeladen."
        }

        Write-Host "[INSTALL] pcvisit Supporter-Modul" `
            -ForegroundColor Cyan

        $process = Start-Process `
            -FilePath $installerPath `
            -ArgumentList "/S" `
            -Wait `
            -PassThru

        if ($process.ExitCode -ne 0) {
            throw (
                "pcvisit-Installation fehlgeschlagen. ExitCode: {0}" `
                    -f $process.ExitCode
            )
        }

        $installedPath = Get-PcVisitSupporterModulePath

        if (-not $installedPath) {
            throw (
                "pcvisit-Setup wurde ausgeführt, das Supporter-Modul " +
                "konnte anschließend aber nicht gefunden werden."
            )
        }

        Write-Host (
            "[OK] pcvisit Supporter-Modul installiert: {0}" `
                -f $installedPath
        ) -ForegroundColor Green
    }
    finally {
        if (Test-Path $installerPath) {
            Remove-Item `
                -Path $installerPath `
                -Force `
                -ErrorAction SilentlyContinue
        }
    }
}