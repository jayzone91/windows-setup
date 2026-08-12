$script:WindowsSetupSourceRoot_modules_Development = Split-Path -Parent $PSScriptRoot

function Install-CodexCli {

    Write-Host ""
    Write-Host "========================================"
    Write-Host " OpenAI Codex CLI"
    Write-Host "========================================"


    if (Get-Command codex -ErrorAction SilentlyContinue) {

        Write-Host "[OK] Codex CLI bereits installiert."

        return
    }


    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {

        Write-Warning `
            "npm wurde nicht gefunden. Codex CLI kann nicht installiert werden."

        return
    }


    Write-Host "[INSTALL] @openai/codex"

    npm install -g @openai/codex

    if ($LASTEXITCODE -ne 0) {
        throw "Codex CLI konnte nicht installiert werden."
    }

    if (Get-Command codex -ErrorAction SilentlyContinue) {

        Write-Host "[OK] Codex CLI installiert."

    }
    else {

        Write-Warning `
            "Codex CLI wurde installiert, aber ist nicht verfügbar."

    }

}


$script:NeovimStashIssue = $null


function Set-NeovimCompilerEnvironment {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Neovim Compiler Environment"
    Write-Host "========================================"

    $zigCommand = Get-Command `
        -Name "zig" `
        -CommandType Application `
        -ErrorAction SilentlyContinue

    if (-not $zigCommand) {
        throw "Zig wurde nicht gefunden."
    }

    $scoopCommand = Get-Command `
        -Name "scoop" `
        -ErrorAction SilentlyContinue

    if (-not $scoopCommand) {
        throw "Scoop wurde nicht gefunden."
    }

    $scoopShimRoot = Join-Path `
        ([Environment]::GetFolderPath("UserProfile")) `
        "scoop\shims"

    $repositoryRoot = Split-Path `
        -Path $script:WindowsSetupSourceRoot_modules_Development `
        -Parent

    $stateDirectory = Join-Path `
        $repositoryRoot `
        ".generated\state\neovim"

    if (-not (Test-Path -LiteralPath $stateDirectory -PathType Container)) {
        New-Item `
            -ItemType Directory `
            -Path $stateDirectory `
            -Force |
        Out-Null
    }

    $compilerShims = @(
        @{
            Name      = "cc"
            Arguments = @("cc")
        },
        @{
            Name      = "c++"
            Arguments = @("c++")
        }
    )

    foreach ($shim in $compilerShims) {
        $existingCommand = Get-Command `
            -Name $shim.Name `
            -CommandType Application `
            -ErrorAction SilentlyContinue

        $isScoopShim = (
            $existingCommand -and
            $existingCommand.Source.StartsWith(
                $scoopShimRoot,
                [StringComparison]::OrdinalIgnoreCase
            )
        )

        if ($existingCommand -and -not $isScoopShim) {
            throw (
                "Compiler-Kommando '{0}' existiert bereits außerhalb der " +
                "Scoop-Shims: {1}. Automatische Überschreibung wird verweigert."
            ) -f $shim.Name, $existingCommand.Source
        }

        $shimMetadataPath = Join-Path `
            $scoopShimRoot `
            ("{0}.shim" -f $shim.Name)

        $statePath = Join-Path `
            $stateDirectory `
            ("{0}.json" -f $shim.Name.Replace("+", "plus"))

        $desiredSignature = Get-TextFingerprint `
            -Text (
                "{0}|{1}" -f
                [IO.Path]::GetFullPath($zigCommand.Source),
                ($shim.Arguments -join "`0")
            )

        $storedState = $null

        if (Test-Path -LiteralPath $statePath -PathType Leaf) {
            try {
                $storedState = Get-Content `
                    -LiteralPath $statePath `
                    -Raw |
                ConvertFrom-Json
            }
            catch {
                $storedState = $null
            }
        }

        $currentShimHash = $null

        if (Test-Path -LiteralPath $shimMetadataPath -PathType Leaf) {
            $currentShimHash = (
                Get-FileHash `
                    -LiteralPath $shimMetadataPath `
                    -Algorithm SHA256
            ).Hash.ToLowerInvariant()
        }

        $shimCurrent = (
            $isScoopShim -and
            $storedState -and
            $storedState.DesiredSignature -eq $desiredSignature -and
            $storedState.ShimHash -eq $currentShimHash
        )

        if ($shimCurrent) {
            Write-Host (
                "[CURRENT] Scoop-Shim '{0}' ist bereits korrekt." -f
                $shim.Name
            ) -ForegroundColor Green

            continue
        }

        if ($isScoopShim) {
            & $scoopCommand.Path shim rm $shim.Name

            if ($LASTEXITCODE -ne 0) {
                throw (
                    "Bestehender Scoop-Shim '{0}' konnte nicht entfernt werden."
                ) -f $shim.Name
            }
        }

        $addShimArguments = @(
            "shim",
            "add",
            $shim.Name,
            $zigCommand.Source
        ) + @($shim.Arguments)

        & $scoopCommand.Path @addShimArguments

        if ($LASTEXITCODE -ne 0) {
            throw (
                "Scoop-Shim '{0}' für Zig konnte nicht erstellt werden."
            ) -f $shim.Name
        }

        if (-not (Test-Path -LiteralPath $shimMetadataPath -PathType Leaf)) {
            throw "Scoop-Shim-Metadatei fehlt nach Erstellung: $shimMetadataPath"
        }

        $newShimHash = (
            Get-FileHash `
                -LiteralPath $shimMetadataPath `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        [ordered]@{
            DesiredSignature = $desiredSignature
            ShimHash          = $newShimHash
        } |
        ConvertTo-Json |
        Set-Content `
            -LiteralPath $statePath `
            -Encoding utf8NoBOM
    }

    $compilerEnvironment = [ordered]@{
        CC                   = "cc"
        CXX                  = "c++"
        CRATE_CC_NO_DEFAULTS = "1"
    }

    foreach ($entry in $compilerEnvironment.GetEnumerator()) {
        $currentUserValue = [Environment]::GetEnvironmentVariable(
            $entry.Key,
            "User"
        )

        if ($currentUserValue -ne $entry.Value) {
            [Environment]::SetEnvironmentVariable(
                $entry.Key,
                $entry.Value,
                "User"
            )

            Write-Host (
                "[CONFIG] Benutzer-Umgebungsvariable {0} = {1}" -f
                $entry.Key,
                $entry.Value
            )
        }

        Set-Item `
            -Path ("Env:{0}" -f $entry.Key) `
            -Value $entry.Value
    }

    $knownWrapper = [Environment]::GetEnvironmentVariable(
        "CC_KNOWN_WRAPPER_CUSTOM",
        "User"
    )

    if ($null -ne $knownWrapper) {
        [Environment]::SetEnvironmentVariable(
            "CC_KNOWN_WRAPPER_CUSTOM",
            $null,
            "User"
        )
    }

    Remove-Item `
        -Path "Env:CC_KNOWN_WRAPPER_CUSTOM" `
        -ErrorAction SilentlyContinue

    $ccCommand = Get-Command `
        -Name "cc" `
        -CommandType Application `
        -ErrorAction SilentlyContinue

    $cxxCommand = Get-Command `
        -Name "c++" `
        -CommandType Application `
        -ErrorAction SilentlyContinue

    if (-not $ccCommand) {
        throw "Der Compiler-Shim 'cc' ist nicht verfügbar."
    }

    if (-not $cxxCommand) {
        throw "Der Compiler-Shim 'c++' ist nicht verfügbar."
    }

    & cc --version *> $null

    if ($LASTEXITCODE -ne 0) {
        throw "Der Zig-C-Compiler über 'cc' konnte nicht ausgeführt werden."
    }

    & c++ --version *> $null

    if ($LASTEXITCODE -ne 0) {
        throw "Der Zig-C++-Compiler über 'c++' konnte nicht ausgeführt werden."
    }

    Write-Host (
        "[OK] Zig-Compiler konfiguriert: CC=cc, CXX=c++."
    ) -ForegroundColor Green
}