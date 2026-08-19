$repositoryRoot = Split-Path -Parent $PSScriptRoot
$driverCommon = Join-Path `
    $repositoryRoot `
    "modules\Drivers\DriverCommon.ps1"

. $driverCommon

Describe "Pending-Reboot-Erkennung" {
    BeforeEach {
        Mock Test-Path {
            return $false
        }

        Mock Get-ItemProperty {
            return $null
        }
    }

    It "meldet ohne Reboot-Indikatoren keinen Neustart" {
        $status = Get-PendingRebootStatus

        $status.RebootRequired | Should Be $false
        $status.Reasons.Count | Should Be 0
        $status.ComponentBasedServicing | Should Be $false
        $status.WindowsUpdate | Should Be $false
        $status.FileRenameOperations | Should Be $false
    }

    It "erkennt Component Based Servicing RebootPending" {
        Mock Test-Path {
            param($Path)

            return (
                $Path -like
                "*Component Based Servicing\RebootPending"
            )
        }

        $status = Get-PendingRebootStatus

        $status.RebootRequired | Should Be $true
        $status.ComponentBasedServicing | Should Be $true
        ($status.Reasons -contains "ComponentBasedServicing") |
            Should Be $true
    }

    It "erkennt Windows Update RebootRequired" {
        Mock Test-Path {
            param($Path)

            return (
                $Path -like
                "*WindowsUpdate\Auto Update\RebootRequired"
            )
        }

        $status = Get-PendingRebootStatus

        $status.RebootRequired | Should Be $true
        $status.WindowsUpdate | Should Be $true
        ($status.Reasons -contains "WindowsUpdate") |
            Should Be $true
    }

    It "erkennt relevante PendingFileRenameOperations" {
        Mock Get-ItemProperty {
            [pscustomobject]@{
                PendingFileRenameOperations = @(
                    "\??\C:\Program Files\App\old.dll"
                    "\??\C:\Program Files\App\new.dll"
                )
            }
        }

        $status = Get-PendingRebootStatus

        $status.RebootRequired | Should Be $true
        $status.FileRenameOperations | Should Be $true
        $status.PendingFileRenames.Count | Should Be 2
        $status.RelevantPendingFileRenames.Count |
            Should Be 2
        ($status.Reasons -contains "PendingFileRenameOperations") |
            Should Be $true
    }

    It "ignoriert reine NSIS-Temp-Cleanup-Einträge" {
        $temp = $env:TEMP

        Mock Get-ItemProperty {
            [pscustomobject]@{
                PendingFileRenameOperations = @(
                    "\??\$temp\~nsu1234.tmp\cleanup.dll"
                    "\??\$temp\nsABC123.tmp\cleanup.exe"
                )
            }
        }

        $status = Get-PendingRebootStatus

        $status.RebootRequired | Should Be $false
        $status.PendingFileRenames.Count | Should Be 2
        $status.RelevantPendingFileRenames.Count |
            Should Be 0
        $status.FileRenameOperations | Should Be $false
    }

    It "behält relevante Einträge neben Temp-Cleanup bei" {
        $temp = $env:TEMP

        Mock Get-ItemProperty {
            [pscustomobject]@{
                PendingFileRenameOperations = @(
                    "\??\$temp\~nsu1234.tmp\cleanup.dll"
                    "\??\C:\Windows\System32\driver.dll"
                )
            }
        }

        $status = Get-PendingRebootStatus

        $status.RebootRequired | Should Be $true
        $status.PendingFileRenames.Count | Should Be 2
        $status.RelevantPendingFileRenames.Count |
            Should Be 1
        $status.FileRenameOperations | Should Be $true
    }

    It "Test-PendingReboot gibt nur den booleschen Status zurück" {
        Mock Get-PendingRebootStatus {
            [pscustomobject]@{
                RebootRequired = $true
            }
        }

        (Test-PendingReboot) | Should Be $true
    }
}