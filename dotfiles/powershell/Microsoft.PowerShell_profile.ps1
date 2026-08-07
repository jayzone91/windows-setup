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
    fnm env --use-on-cd --shell powershell |
    Out-String |
    Invoke-Expression
}

# Starship
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
