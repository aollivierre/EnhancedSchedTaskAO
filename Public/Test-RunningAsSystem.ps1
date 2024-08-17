function Test-RunningAsSystem {
    <#
    .SYNOPSIS
    Checks if the current session is running under the SYSTEM account.

    .DESCRIPTION
    The Test-RunningAsSystem function checks whether the current PowerShell session is running under the Windows SYSTEM account. 
    This is determined by comparing the security identifier (SID) of the current user with the SID of the SYSTEM account.

    .EXAMPLE
    $isSystem = Test-RunningAsSystem
    if ($isSystem) {
        Write-Host "The script is running under the SYSTEM account."
    } else {
        Write-Host "The script is not running under the SYSTEM account."
    }

    Checks if the current session is running under the SYSTEM account and returns the status.

    .NOTES
    This function is useful when determining if the script is being executed by a service or task running under the SYSTEM account.
    #>

    [CmdletBinding()]
    param ()

    Begin {
        Write-EnhancedLog -Message "Starting Test-RunningAsSystem function" -Level "NOTICE"

        # Initialize variables
        $systemSid = [System.Security.Principal.SecurityIdentifier]::new("S-1-5-18")
    }

    Process {
        try {
            Write-EnhancedLog -Message "Checking if the script is running under the SYSTEM account..." -Level "INFO"

            $currentSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User

            if ($currentSid -eq $systemSid) {
                Write-EnhancedLog -Message "The script is running under the SYSTEM account." -Level "INFO"
            } else {
                Write-EnhancedLog -Message "The script is not running under the SYSTEM account." -Level "WARNING"
            }
        }
        catch {
            Write-EnhancedLog -Message "Error determining if running as SYSTEM: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Test-RunningAsSystem function" -Level "NOTICE"
        return $currentSid -eq $systemSid
    }
}

# Usage Example
# $isSystem = Test-RunningAsSystem
# if ($isSystem) {
#     Write-Host "The script is running under the SYSTEM account."
# } else {
#     Write-Host "The script is not running under the SYSTEM account."
# }