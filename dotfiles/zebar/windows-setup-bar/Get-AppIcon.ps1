param(
    [Parameter(Mandatory)]
    [string] $ExecutableName
)

$ErrorActionPreference = "Stop"

$processName =
[System.IO.Path]::GetFileNameWithoutExtension(
    $ExecutableName
)

$process =
Get-Process `
    -Name $processName `
    -ErrorAction SilentlyContinue |
Where-Object {
    try {
        -not [string]::IsNullOrWhiteSpace(
            $_.MainModule.FileName
        )
    }
    catch {
        $false
    }
} |
Select-Object -First 1

if (-not $process) {
    throw "Kein laufender Prozess '$ExecutableName' gefunden."
}

$executablePath =
$process.MainModule.FileName

if (
    [string]::IsNullOrWhiteSpace($executablePath) -or
    -not (Test-Path -LiteralPath $executablePath)
) {
    throw "Programmpfad für '$ExecutableName' konnte nicht ermittelt werden."
}

Add-Type -AssemblyName System.Drawing

$icon =
[System.Drawing.Icon]::ExtractAssociatedIcon(
    $executablePath
)

if (-not $icon) {
    throw "Kein Icon für '$executablePath' gefunden."
}

$bitmap =
$icon.ToBitmap()

$stream =
[System.IO.MemoryStream]::new()

try {
    $bitmap.Save(
        $stream,
        [System.Drawing.Imaging.ImageFormat]::Png
    )

    [Convert]::ToBase64String(
        $stream.ToArray()
    )
}
finally {
    $stream.Dispose()
    $bitmap.Dispose()
    $icon.Dispose()
}
