$repositoryRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $repositoryRoot "modules\Helpers\index.ps1")

Describe "Hardlink- und Junction-Migration" {
    BeforeEach {
        $script:TestRoot = Join-Path `
            ([IO.Path]::GetTempPath()) `
            ("windows-setup-pester-" + [guid]::NewGuid().ToString("N"))

        New-Item `
            -ItemType Directory `
            -Path $script:TestRoot `
            -Force |
        Out-Null
    }

    AfterEach {
        if (Test-Path -LiteralPath $script:TestRoot) {
            Remove-Item `
                -LiteralPath $script:TestRoot `
                -Recurse `
                -Force
        }
    }

    It "erstellt einen Hardlink und erkennt das korrekte Ziel" {
        $target = Join-Path $script:TestRoot "source.txt"
        $path = Join-Path $script:TestRoot "linked.txt"

        Set-Content -LiteralPath $target -Value "source"

        Set-FileHardLink -Path $path -Target $target

        (Test-FileHardLinkTarget -Path $path -Target $target) |
            Should Be $true
    }

    It "ersetzt eine normale Datei nur mit explizitem ReplaceExistingFile" {
        $target = Join-Path $script:TestRoot "source.txt"
        $path = Join-Path $script:TestRoot "linked.txt"

        Set-Content -LiteralPath $target -Value "source"
        Set-Content -LiteralPath $path -Value "old"

        $thrown = $false

        try {
            Set-FileHardLink -Path $path -Target $target
        }
        catch {
            $thrown = $true
        }

        $thrown | Should Be $true

        Set-FileHardLink `
            -Path $path `
            -Target $target `
            -ReplaceExistingFile

        (Test-FileHardLinkTarget -Path $path -Target $target) |
            Should Be $true
    }

    It "lässt einen korrekten Hardlink beim zweiten Lauf bestehen" {
        $target = Join-Path $script:TestRoot "source.txt"
        $path = Join-Path $script:TestRoot "linked.txt"

        Set-Content -LiteralPath $target -Value "source"
        Set-FileHardLink -Path $path -Target $target

        $before = Get-Item -LiteralPath $path -Force

        Set-FileHardLink -Path $path -Target $target

        $after = Get-Item -LiteralPath $path -Force

        $after.LinkType | Should Be "HardLink"
        $after.CreationTimeUtc | Should Be $before.CreationTimeUtc
        (Test-FileHardLinkTarget -Path $path -Target $target) |
            Should Be $true
    }

    It "erstellt eine Junction und erkennt das korrekte Ziel" {
        $target = Join-Path $script:TestRoot "source"
        $path = Join-Path $script:TestRoot "linked"

        New-Item -ItemType Directory -Path $target | Out-Null

        Set-DirectoryJunction -Path $path -Target $target

        (Test-DirectoryJunctionTarget -Path $path -Target $target) |
            Should Be $true
    }

    It "migriert eine Junction mit falschem Ziel" {
        $targetA = Join-Path $script:TestRoot "source-a"
        $targetB = Join-Path $script:TestRoot "source-b"
        $path = Join-Path $script:TestRoot "linked"

        New-Item -ItemType Directory -Path $targetA | Out-Null
        New-Item -ItemType Directory -Path $targetB | Out-Null

        Set-DirectoryJunction -Path $path -Target $targetA

        (Test-DirectoryJunctionTarget -Path $path -Target $targetA) |
            Should Be $true

        Set-DirectoryJunction -Path $path -Target $targetB

        (Test-DirectoryJunctionTarget -Path $path -Target $targetB) |
            Should Be $true

        (Test-DirectoryJunctionTarget -Path $path -Target $targetA) |
            Should Be $false
    }

    It "überschreibt kein echtes Verzeichnis mit einer Junction" {
        $target = Join-Path $script:TestRoot "source"
        $path = Join-Path $script:TestRoot "existing"

        New-Item -ItemType Directory -Path $target | Out-Null
        New-Item -ItemType Directory -Path $path | Out-Null

        $thrown = $false

        try {
            Set-DirectoryJunction -Path $path -Target $target
        }
        catch {
            $thrown = $true
        }

        $thrown | Should Be $true
        (Get-Item -LiteralPath $path -Force).LinkType |
            Should BeNullOrEmpty
    }

    It "lässt eine korrekte Junction beim zweiten Lauf bestehen" {
        $target = Join-Path $script:TestRoot "source"
        $path = Join-Path $script:TestRoot "linked"

        New-Item -ItemType Directory -Path $target | Out-Null
        Set-DirectoryJunction -Path $path -Target $target

        $before = Get-Item -LiteralPath $path -Force

        Set-DirectoryJunction -Path $path -Target $target

        $after = Get-Item -LiteralPath $path -Force

        $after.LinkType | Should Be "Junction"
        $after.CreationTimeUtc | Should Be $before.CreationTimeUtc
        (Test-DirectoryJunctionTarget -Path $path -Target $target) |
            Should Be $true
    }
}