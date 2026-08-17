function Get-RaycastApplicationPackage {
    return Get-AppxPackage `
        -Name 'Raycast.Raycast' `
        -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending |
    Select-Object -First 1
}

function Get-RaycastJavaScriptRuntime {
    $node = Get-Command `
        -Name "node.exe" `
        -All `
        -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Source -and
        $_.Source -notmatch '\\WindowsApps\\'
    } |
    Select-Object -First 1

    if ($node) {
        return $node.Source
    }

    $bun = Get-Command `
        -Name "bun.exe" `
        -ErrorAction SilentlyContinue |
    Select-Object -First 1

    if ($bun) {
        return $bun.Source
    }

    throw (
        "Kein ausführbarer JavaScript-Runtime gefunden. " +
        "Erwartet wird Node.js außerhalb von WindowsApps oder Bun."
    )
}

function Get-RaycastBackupPath {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    if ([string]::IsNullOrWhiteSpace([string]$Config.BackupPath)) {
        throw 'config/raycast.psd1 enthält keinen BackupPath.'
    }

    return [Environment]::ExpandEnvironmentVariables(
        [string]$Config.BackupPath
    )
}

function Test-RaycastConfig {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    $password = [string]$Config.ExportPassword

    if ([string]::IsNullOrWhiteSpace($password)) {
        throw 'config/raycast.psd1 enthält kein ExportPassword.'
    }

    if ($password.Length -lt 8) {
        throw 'Raycast ExportPassword muss mindestens 8 Zeichen lang sein.'
    }

    [void](Get-RaycastBackupPath -Config $Config)
}

function Invoke-RaycastConfigTool {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('sanitize', 'build')]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$InputPath,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$RepositoryPath,

        [Parameter(Mandatory)]
        [object]$Package
    )

    $toolPath = Join-Path `
        $RepositoryPath `
        'scripts\raycast-config.mjs'

    if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) {
        throw "Raycast-Generator fehlt: $toolPath"
    }

    $runtime = Get-RaycastJavaScriptRuntime

    $previousPassword = $env:RAYCAST_EXPORT_PASSWORD
    $previousInput = $env:RAYCAST_INPUT_PATH
    $previousOutput = $env:RAYCAST_OUTPUT_PATH
    $previousVersion = $env:RAYCAST_APP_VERSION

    try {
        $env:RAYCAST_EXPORT_PASSWORD = [string]$Config.ExportPassword
        $env:RAYCAST_INPUT_PATH = $InputPath
        $env:RAYCAST_OUTPUT_PATH = $OutputPath
        $env:RAYCAST_APP_VERSION = [string]$Package.Version

        $processInfo = [Diagnostics.ProcessStartInfo]::new()
        $processInfo.FileName = $runtime
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.ArgumentList.Add($toolPath)
        $processInfo.ArgumentList.Add($Action)

        $process = [Diagnostics.Process]::new()
        $process.StartInfo = $processInfo

        try {
            if (-not $process.Start()) {
                throw "Raycast-Konfigurationswerkzeug konnte nicht gestartet werden."
            }

            $stdoutTask = $process.StandardOutput.ReadToEndAsync()
            $stderrTask = $process.StandardError.ReadToEndAsync()

            $process.WaitForExit()

            $stdout = $stdoutTask.GetAwaiter().GetResult()
            $stderr = $stderrTask.GetAwaiter().GetResult()
            $toolExitCode = $process.ExitCode

            if (-not [string]::IsNullOrWhiteSpace($stdout)) {
                Write-Host $stdout.TrimEnd()
            }

            if (-not [string]::IsNullOrWhiteSpace($stderr)) {
                Write-Host $stderr.TrimEnd()
            }
        }
        finally {
            $process.Dispose()
        }

        if ($toolExitCode -ne 0) {
            throw "Raycast-Konfigurationswerkzeug ist fehlgeschlagen: $Action"
        }
    }
    finally {
        $env:RAYCAST_EXPORT_PASSWORD = $previousPassword
        $env:RAYCAST_INPUT_PATH = $previousInput
        $env:RAYCAST_OUTPUT_PATH = $previousOutput
        $env:RAYCAST_APP_VERSION = $previousVersion
    }
}

function Get-LatestRaycastBackup {
    param(
        [Parameter(Mandatory)]
        [string]$BackupPath
    )

    if (-not (Test-Path -LiteralPath $BackupPath -PathType Container)) {
        return $null
    }

    return Get-ChildItem `
        -LiteralPath $BackupPath `
        -Filter '*.rayconfig' `
        -File `
        -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

function Sync-RaycastDesiredState {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$RepositoryPath,

        [Parameter(Mandatory)]
        [object]$Package
    )

    $backupPath = Get-RaycastBackupPath -Config $Config
    $backup = Get-LatestRaycastBackup -BackupPath $backupPath

    if (-not $backup) {
        Write-Warning (
            "Kein lokales Raycast-Backup unter '$backupPath' gefunden. " +
            'Desired-State-Sicherung wird übersprungen.'
        )

        return $false
    }

    $desiredStatePath = Join-Path `
        $RepositoryPath `
        'dotfiles\raycast\config.json'

    $tempPath = Join-Path `
        ([IO.Path]::GetTempPath()) `
        ('raycast-desired-' + [guid]::NewGuid().ToString('N') + '.json')

    try {
        Invoke-RaycastConfigTool `
            -Action sanitize `
            -InputPath $backup.FullName `
            -OutputPath $tempPath `
            -Config $Config `
            -RepositoryPath $RepositoryPath `
            -Package $Package

        $newContent = [IO.File]::ReadAllText($tempPath)
        $oldContent = if (
            Test-Path -LiteralPath $desiredStatePath -PathType Leaf
        ) {
            [IO.File]::ReadAllText($desiredStatePath)
        }
        else {
            $null
        }

        if ($newContent -eq $oldContent) {
            Write-Host '[OK] Raycast Desired State unverändert.' `
                -ForegroundColor Green

            return $true
        }

        $directory = Split-Path -Path $desiredStatePath -Parent

        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }

        Copy-Item `
            -LiteralPath $tempPath `
            -Destination $desiredStatePath `
            -Force

        Write-Host (
            '[UPDATE] Raycast Desired State aus lokalem Backup gesichert.'
        ) -ForegroundColor Yellow

        return $true
    }
    finally {
        Remove-Item `
            -LiteralPath $tempPath `
            -Force `
            -ErrorAction SilentlyContinue
    }
}

function New-RaycastInitializationMarker {
    param(
        [Parameter(Mandatory)]
        [string]$StatePath
    )

    $directory = Split-Path -Path $StatePath -Parent

    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    New-Item -ItemType File -Path $StatePath -Force | Out-Null
}

function Initialize-RaycastConfiguration {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$RepositoryPath
    )

    Write-Host ''
    Write-Host '========================================'
    Write-Host ' Raycast'
    Write-Host '========================================'

    Test-RaycastConfig -Config $Config

    $package = Get-RaycastApplicationPackage

    if (-not $package) {
        Write-Warning 'Raycast ist nicht als AppX/MSIX-Paket registriert.'
        return
    }

    $statePath = Join-Path `
        $RepositoryPath `
        '.generated\state\default-apps\raycast.initialized'

    $backupPath = Get-RaycastBackupPath -Config $Config

    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        Write-Host '[OK] Raycast wurde bereits initialisiert.' `
            -ForegroundColor Green

        [void](Sync-RaycastDesiredState `
            -Config $Config `
            -RepositoryPath $RepositoryPath `
            -Package $package)

        return
    }

    Write-WindowsSetupInteractive
    Write-WindowsSetupInteractive `
        -Message '[INFO] Raycast-Backups können persönliche und sensible Daten enthalten.'
    Write-WindowsSetupInteractive `
        -Message (
            '[INFO] Dieses Setup geht davon aus, dass das vollständige .rayconfig-' +
            'Archiv ausschließlich lokal gespeichert wird.'
        )
    Write-WindowsSetupInteractive `
        -Message '[INFO] Ins Repository gelangt ausschließlich der bereinigte Desired State.'

    $confirmation = Read-WindowsSetupPrompt `
        -Prompt 'Lokales Backup-Modell verstanden und bestätigt? [j/N]'

    if ($confirmation -notmatch '^(?i:j|ja|y|yes)$') {
        Write-Warning 'Raycast-Initialisierung wurde nicht bestätigt.'
        return
    }

    $existingBackup = Get-LatestRaycastBackup -BackupPath $backupPath

    if ($existingBackup) {
        Write-Host (
            "[INFO] Vorhandenes lokales Raycast-Backup gefunden: {0}" `
                -f $existingBackup.FullName
        )

        $synced = Sync-RaycastDesiredState `
            -Config $Config `
            -RepositoryPath $RepositoryPath `
            -Package $package

        if (-not $synced) {
            Write-Warning 'Raycast-Zustand konnte nicht übernommen werden.'
            return
        }

        Write-WindowsSetupInteractive `
            -Message (
                "[INFO] Vorhandenes lokales Raycast-Backup: {0}" -f
                $existingBackup.FullName
            )

        $configured = Read-WindowsSetupPrompt `
            -Prompt (
                'Raycast ist bereits vollständig eingerichtet und Daily Backup ' +
                'verwendet BackupPath/ExportPassword aus config/raycast.psd1? [j/N]'
            )

        if ($configured -notmatch '^(?i:j|ja|y|yes)$') {
            Write-Warning 'Raycast wird noch nicht als initialisiert markiert.'
            return
        }

        New-RaycastInitializationMarker -StatePath $statePath
        Write-Host '[OK] Bestehende Raycast-Konfiguration übernommen.' `
            -ForegroundColor Green
        return
    }

    $desiredStatePath = Join-Path `
        $RepositoryPath `
        'dotfiles\raycast\config.json'

    if (-not (Test-Path -LiteralPath $desiredStatePath -PathType Leaf)) {
        throw "Raycast Desired State fehlt: $desiredStatePath"
    }

    $generatedDirectory = Join-Path `
        $RepositoryPath `
        '.generated\raycast'

    if (-not (Test-Path -LiteralPath $generatedDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $generatedDirectory -Force | Out-Null
    }

    $importPath = Join-Path `
        $generatedDirectory `
        'raycast-import.rayconfig'

    Invoke-RaycastConfigTool `
        -Action build `
        -InputPath $desiredStatePath `
        -OutputPath $importPath `
        -Config $Config `
        -RepositoryPath $RepositoryPath `
        -Package $package

    Write-WindowsSetupInteractive
    Write-WindowsSetupInteractive `
        -Message '[ACTION] Raycast-Erstinitialisierung erforderlich.'
    Write-WindowsSetupInteractive `
        -Message "  1. In Raycast 'Import Settings & Data' öffnen."
    Write-WindowsSetupInteractive `
        -Message "  2. Diese lokale Datei importieren: $importPath"
    Write-WindowsSetupInteractive `
        -Message "  3. Export-Passwort aus config/raycast.psd1 verwenden."
    Write-WindowsSetupInteractive `
        -Message "  4. Scheduled Backup auf Daily stellen."
    Write-WindowsSetupInteractive `
        -Message "  5. Backup Location auf '$backupPath' setzen."
    Write-WindowsSetupInteractive `
        -Message "  6. Auto-Delete auf 'Keep Latest' stellen."
    Write-WindowsSetupInteractive

    Start-Process explorer.exe -ArgumentList "/select,`"$importPath`""

    $completed = Read-WindowsSetupPrompt `
        -Prompt 'Import und Daily-Backup-Konfiguration erfolgreich abgeschlossen? [j/N]'

    if ($completed -notmatch '^(?i:j|ja|y|yes)$') {
        Write-Warning 'Raycast wird noch nicht als initialisiert markiert.'
        return
    }

    New-RaycastInitializationMarker -StatePath $statePath

    Write-Host '[OK] Raycast als initialisiert markiert.' `
        -ForegroundColor Green
}
