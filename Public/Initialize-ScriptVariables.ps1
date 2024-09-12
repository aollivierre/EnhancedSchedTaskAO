function Initialize-ScriptVariables {
    <#
    .SYNOPSIS
    Initializes global script variables and defines the path for storing related files.

    .DESCRIPTION
    This function initializes global script variables such as PackageName, PackageUniqueGUID, Version, and ScriptMode. Additionally, it constructs the path where related files will be stored based on the provided parameters.

    .PARAMETER PackageName
    The name of the package being processed.

    .PARAMETER PackageUniqueGUID
    The unique identifier for the package being processed.

    .PARAMETER Version
    The version of the package being processed.

    .PARAMETER ScriptMode
    The mode in which the script is being executed (e.g., "Remediation", "PackageName").

    .PARAMETER PackageExecutionContext
    The context in which the package is being executed (e.g., User, System).

    .PARAMETER RepetitionInterval
    The interval at which the package is executed repeatedly.

    .EXAMPLE
    Initialize-ScriptVariables -PackageName "MyPackage" -PackageUniqueGUID "1234-5678" -Version 1 -ScriptMode "Remediation" -PackageExecutionContext "System" -RepetitionInterval "P1D"

    This example initializes the script variables with the specified values.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the name of the package.")]
        [string]$PackageName,

        [Parameter(Mandatory = $true, HelpMessage = "Provide the unique identifier of the package.")]
        [string]$PackageUniqueGUID,

        [Parameter(Mandatory = $true, HelpMessage = "Provide the version of the package.")]
        [int]$Version,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the script execution mode.")]
        [string]$ScriptMode,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the execution context (e.g., User, System).")]
        [string]$PackageExecutionContext,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the repetition interval (e.g., 'P1D').")]
        [string]$RepetitionInterval
    )

    Begin {
        Write-EnhancedLog -Message "Starting Initialize-ScriptVariables function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Check if the global variable $Path_local is set, otherwise set it based on execution context
        Write-EnhancedLog -Message "Determining the local path based on the execution context..." -Level "INFO"
        try {
            if (-not $Path_local) {
                if (Test-RunningAsSystem) {
                    $Path_local = "C:\_MEM"
                }
                else {
                    $Path_local = "$ENV:LOCALAPPDATA\_MEM"
                }
            }
            Write-EnhancedLog -Message "Local path set to $Path_local" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Error determining local path: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
    }

    Process {
        try {
            Write-EnhancedLog -Message "Initializing variables based on the provided parameters..." -Level "INFO"

            # Construct paths and task names
            $Path_PR = "$Path_local\Data\$PackageName-$PackageUniqueGUID"
            $schtaskName = "$PackageName - $PackageUniqueGUID"
            $schtaskDescription = "Version $Version"

            Write-EnhancedLog -Message "Variables initialized successfully." -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Error initializing variables: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
    }

    End {
        Write-EnhancedLog -Message "Returning initialized script variables." -Level "INFO"
        try {
            # Return a hashtable containing all important variables
            return @{
                PackageName             = $PackageName
                PackageUniqueGUID       = $PackageUniqueGUID
                Version                 = $Version
                ScriptMode              = $ScriptMode
                Path_local              = $Path_local
                Path_PR                 = $Path_PR
                schtaskName             = $schtaskName
                schtaskDescription      = $schtaskDescription
                PackageExecutionContext = $PackageExecutionContext
                RepetitionInterval      = $RepetitionInterval
            }
        }
        catch {
            Write-EnhancedLog -Message "Error returning initialized script variables: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
        finally {
            Write-EnhancedLog -Message "Exiting Initialize-ScriptVariables function" -Level "Notice"
        }
    }
}

# Example usage
# $params = @{
#     PackageName             = "MyPackage"
#     PackageUniqueGUID       = "1234-5678"
#     Version                 = 1
#     ScriptMode              = "Remediation"
#     PackageExecutionContext = "System"
#     RepetitionInterval      = "P1D"
# }
# Initialize-ScriptVariables @params