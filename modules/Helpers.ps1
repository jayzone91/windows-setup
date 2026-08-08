function Update-SessionPath {

    Write-Host ""
    Write-Host "[CONFIG] Aktualisiere PATH"


    $machinePath =
    [Environment]::GetEnvironmentVariable(
        "Path",
        "Machine"
    )

    $userPath =
    [Environment]::GetEnvironmentVariable(
        "Path",
        "User"
    )

    $currentPath =
    $env:Path


    $paths = @(
        $currentPath
        $machinePath
        $userPath
    ) |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    } |
    ForEach-Object {
        $_ -split ";"
    } |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    } |
    Select-Object -Unique


    $env:Path =
    $paths -join ";"


    Write-Host "[OK] PATH aktualisiert."
}
