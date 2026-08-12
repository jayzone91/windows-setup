function Get-WindowsScheduledTaskSignatureDifference {
    param(
        [AllowNull()]
        $Current,

        [AllowNull()]
        $Desired,

        [string] $Path = ""
    )

    $differences = [Collections.Generic.List[object]]::new()

    if ($null -eq $Current -and $null -eq $Desired) {
        return @()
    }

    if ($null -eq $Current -or $null -eq $Desired) {
        $differences.Add(
            [pscustomobject]@{
                Path    = $Path
                Current = $Current
                Desired = $Desired
            }
        )

        return $differences.ToArray()
    }

    if (
        $Current -is [pscustomobject] -and
        $Desired -is [pscustomobject]
    ) {
        $propertyNames = @(
            @($Current.PSObject.Properties.Name) +
            @($Desired.PSObject.Properties.Name) |
            Sort-Object -Unique
        )

        foreach ($propertyName in $propertyNames) {
            $currentProperty = $Current.PSObject.Properties[$propertyName]
            $desiredProperty = $Desired.PSObject.Properties[$propertyName]

            $currentValue = if ($null -ne $currentProperty) {
                $currentProperty.Value
            }
            else {
                $null
            }

            $desiredValue = if ($null -ne $desiredProperty) {
                $desiredProperty.Value
            }
            else {
                $null
            }

            $propertyPath = if ([string]::IsNullOrWhiteSpace($Path)) {
                $propertyName
            }
            else {
                "$Path.$propertyName"
            }

            foreach ($difference in @(
                    Get-WindowsScheduledTaskSignatureDifference `
                        -Current $currentValue `
                        -Desired $desiredValue `
                        -Path $propertyPath
                )) {
                $differences.Add($difference)
            }
        }

        return $differences.ToArray()
    }

    $currentIsEnumerable =
        $Current -is [Collections.IEnumerable] -and
        $Current -isnot [string]

    $desiredIsEnumerable =
        $Desired -is [Collections.IEnumerable] -and
        $Desired -isnot [string]

    if ($currentIsEnumerable -and $desiredIsEnumerable) {
        $currentItems = @($Current)
        $desiredItems = @($Desired)
        $maxCount = [Math]::Max(
            $currentItems.Count,
            $desiredItems.Count
        )

        for ($index = 0; $index -lt $maxCount; $index++) {
            $currentValue = if ($index -lt $currentItems.Count) {
                $currentItems[$index]
            }
            else {
                $null
            }

            $desiredValue = if ($index -lt $desiredItems.Count) {
                $desiredItems[$index]
            }
            else {
                $null
            }

            $itemPath = "{0}[{1}]" -f $Path, $index

            foreach ($difference in @(
                    Get-WindowsScheduledTaskSignatureDifference `
                        -Current $currentValue `
                        -Desired $desiredValue `
                        -Path $itemPath
                )) {
                $differences.Add($difference)
            }
        }

        return $differences.ToArray()
    }

    $currentText = [string]$Current
    $desiredText = [string]$Desired

    if ($currentText -cne $desiredText) {
        $differences.Add(
            [pscustomobject]@{
                Path    = $Path
                Current = $Current
                Desired = $Desired
            }
        )
    }

    return $differences.ToArray()
}

function Write-WindowsScheduledTaskSignatureDifference {
    param(
        [Parameter(Mandatory)]
        [string] $TaskName,

        [Parameter(Mandatory)]
        [string] $CurrentSignature,

        [Parameter(Mandatory)]
        [string] $DesiredSignature
    )

    $current = $CurrentSignature |
        ConvertFrom-Json -Depth 20 -ErrorAction Stop

    $desired = $DesiredSignature |
        ConvertFrom-Json -Depth 20 -ErrorAction Stop

    $differences = @(
        Get-WindowsScheduledTaskSignatureDifference `
            -Current $current `
            -Desired $desired
    )

    if ($differences.Count -eq 0) {
        Write-Host (
            "[DIAG] Scheduled Task '$TaskName': " +
            "JSON-Strings unterscheiden sich, aber strukturiert wurde " +
            "keine Property-Abweichung gefunden."
        ) -ForegroundColor Yellow

        Write-Host "[DIAG] Current JSON: $CurrentSignature"
        Write-Host "[DIAG] Desired JSON: $DesiredSignature"
        return
    }

    Write-Host (
        "[DIAG] Scheduled Task '$TaskName' weicht in " +
        "$($differences.Count) Property/Properties ab:"
    ) -ForegroundColor Yellow

    foreach ($difference in $differences) {
        $currentValue = if ($null -eq $difference.Current) {
            "<null>"
        }
        elseif ([string]$difference.Current -eq "") {
            "<empty>"
        }
        else {
            [string]$difference.Current
        }

        $desiredValue = if ($null -eq $difference.Desired) {
            "<null>"
        }
        elseif ([string]$difference.Desired -eq "") {
            "<empty>"
        }
        else {
            [string]$difference.Desired
        }

        Write-Host (
            "[DIAG]   {0}`n" +
            "[DIAG]     Current: {1}`n" +
            "[DIAG]     Desired: {2}" -f
            $difference.Path,
            $currentValue,
            $desiredValue
        )
    }
}