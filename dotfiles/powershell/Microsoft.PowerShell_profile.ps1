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

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
