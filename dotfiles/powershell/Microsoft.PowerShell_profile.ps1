# UTF-8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# PSReadLine
Import-Module PSReadLine

Set-PSReadLineOption `
    -PredictionSource HistoryAndPlugin `
    -PredictionViewStyle ListView `
    -EditMode Windows

Set-PSReadLineOption `
    -HistoryNoDuplicates

Set-PSReadLineKeyHandler `
    -Key Tab `
    -Function MenuComplete

Set-PSReadLineKeyHandler `
    -Key UpArrow `
    -Function HistorySearchBackward

Set-PSReadLineKeyHandler `
    -Key DownArrow `
    -Function HistorySearchForward

if (Get-Command fnm -ErrorAction SilentlyContinue) {

    $fnmEnvironment = fnm env `
        --use-on-cd `
        --shell powershell |
    Out-String

    $fnmScript = [scriptblock]::Create(
        $fnmEnvironment
    )

    & $fnmScript
}

# Starship
if (Get-Command starship -ErrorAction SilentlyContinue) {

    $starshipEnvironment =
    & starship init powershell |
    Out-String


    $starshipScript = [scriptblock]::Create(
        $starshipEnvironment
    )


    & $starshipScript
}


# Zoxide
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    $zoxideEnvironment =
    & zoxide init powershell |
    Out-String

    $zoxideScript = [scriptblock]::Create(
        $zoxideEnvironment
    )

    & $zoxideScript
}

# Shell Abbreviations
$script:ShellAbbreviations = [ordered]@{
    "cd"     = "z"

    "ls"     = "eza --icons --group-directories-first"
    "ll"     = "eza -lah --icons --group-directories-first"
    "la"     = "eza -a --icons --group-directories-first"
    "lt"     = "eza --tree --icons --group-directories-first"

    "cat"    = "bat"
    "grep"   = "rg"
    "find"   = "fd"

    "c"      = "clear"
    "cls"    = "clear"

    ".."     = "cd .."
    "..."    = "cd ../.."
    "...."   = "cd ../../.."

    "gs"     = "git status"
    "ga"     = "git add"
    "gaa"    = "git add --all"
    "gc"     = "git commit"
    "gcm"    = "git commit -m"
    "gp"     = "git push"
    "gl"     = "git pull"
    "gd"     = "git diff"
    "gb"     = "git branch"
    "gco"    = "git checkout"
    "gsw"    = "git switch"
    "glog"   = "git log --oneline --graph --decorate --all"
    "window" = "komorebic visible-windows"
}

function Expand-ShellAbbreviation {
    param(
        [Parameter(Mandatory)]
        [string] $Terminator
    )

    $line = $null
    $cursor = $null

    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState(
        [ref] $line,
        [ref] $cursor
    )

    if ([string]::IsNullOrWhiteSpace($line)) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(
            $Terminator
        )
        return
    }

    $prefix = $line.Substring(0, $cursor)

    if ($prefix -notmatch '^\s*(\S+)$') {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(
            $Terminator
        )
        return
    }

    $token = $Matches[1]

    if (-not $script:ShellAbbreviations.Contains($token)) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(
            $Terminator
        )
        return
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
        0,
        $cursor,
        $script:ShellAbbreviations[$token]
    )

    [Microsoft.PowerShell.PSConsoleReadLine]::Insert(
        $Terminator
    )
}

Set-PSReadLineKeyHandler `
    -Key Spacebar `
    -BriefDescription "ExpandAbbreviation" `
    -LongDescription "Fish-style shell abbreviation expansion" `
    -ScriptBlock {
    Expand-ShellAbbreviation -Terminator " "
}

Set-PSReadLineKeyHandler `
    -Key Enter `
    -BriefDescription "ExpandAbbreviationAndAcceptLine" `
    -LongDescription "Expand shell abbreviation and execute command" `
    -ScriptBlock {
    $line = $null
    $cursor = $null

    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState(
        [ref] $line,
        [ref] $cursor
    )

    $prefix = if ($cursor -gt 0) {
        $line.Substring(0, $cursor)
    }
    else {
        ""
    }

    if ($prefix -match '^\s*(\S+)$') {
        $token = $Matches[1]

        if ($script:ShellAbbreviations.Contains($token)) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                0,
                $cursor,
                $script:ShellAbbreviations[$token]
            )
        }
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

function Get-CurrentGitRoot {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        return $null
    }

    $root = & git rev-parse --show-toplevel 2>$null

    if ($LASTEXITCODE -ne 0 -or -not $root) {
        return $null
    }

    return [System.IO.Path]::GetFullPath(
        ($root | Select-Object -First 1).Trim()
    ).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
}

function Update-ProjectCommands {
    $moduleName = "WindowsSetupProjectCommands"

    $loadedModule = Get-Module -Name $moduleName

    if ($loadedModule) {
        Remove-Module `
            -Name $moduleName `
            -Force
    }

    $gitRoot = Get-CurrentGitRoot

    if (-not $gitRoot) {
        return
    }

    $windowsSetupRoot = [System.IO.Path]::GetFullPath(
        (Join-Path $HOME "windows-setup")
    ).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )

    if (-not $gitRoot.Equals(
            $windowsSetupRoot,
            [System.StringComparison]::OrdinalIgnoreCase
        )) {
        return
    }

    $projectModule = New-Module `
        -Name $moduleName `
        -ScriptBlock {
        function Update-WindowsSetup {
            <#
                .SYNOPSIS
                Führt den vollständigen windows-setup-Bootstrap aus.
                #>
            just update
        }

        function Test-WindowsSetup {
            <#
                .SYNOPSIS
                Führt die statische Prüfung des windows-setup-Repositories aus.
                #>
            just check
        }

        function Restart-WindowsSetupDesktop {
            <#
                .SYNOPSIS
                Startet die verwaltete Desktop-Umgebung kontrolliert neu.
                #>
            just desktop-restart
        }

        Set-Alias `
            -Name update `
            -Value Update-WindowsSetup

        Set-Alias `
            -Name check `
            -Value Test-WindowsSetup

        Set-Alias `
            -Name desktop-restart `
            -Value Restart-WindowsSetupDesktop

        Export-ModuleMember `
            -Function `
            Update-WindowsSetup,
        Test-WindowsSetup,
        Restart-WindowsSetupDesktop `
            -Alias `
            update,
        check,
        desktop-restart
    }

    Import-Module `
        -ModuleInfo $projectModule `
        -Global `
        -DisableNameChecking
}
# Project Command Prompt Hook
#
# Starship definiert die globale prompt-Funktion bereits weiter oben.
# Wir speichern diese Funktion und aktualisieren vor jedem Prompt die
# projektspezifischen Commands. Dadurch ist die Erkennung unabhängig
# davon, ob der Pfad über cd, zoxide, Set-Location oder ein anderes
# Werkzeug geändert wurde.
$starshipPrompt = Get-Command `
    -Name prompt `
    -CommandType Function `
    -ErrorAction SilentlyContinue

if ($starshipPrompt) {
    $script:StarshipPrompt = $starshipPrompt.ScriptBlock

    function global:prompt {
        Update-ProjectCommands

        & $script:StarshipPrompt
    }
}
else {
    function global:prompt {
        Update-ProjectCommands

        "PS $($executionContext.SessionState.Path.CurrentLocation)> "
    }
}

Update-ProjectCommands



# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}
