function Update-SessionPath {

    Write-Host ""
    Write-Host "[CONFIG] Aktualisiere PATH"


    $machinePath = [Environment]::GetEnvironmentVariable(
        "Path",
        "Machine"
    )

    $userPath = [Environment]::GetEnvironmentVariable(
        "Path",
        "User"
    )


    $env:Path = @(
        $machinePath,
        $userPath
    ) -join ";"


    Write-Host "[OK] PATH aktualisiert."
}
