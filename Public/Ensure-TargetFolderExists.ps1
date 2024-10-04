function Ensure-TargetFolderExists {
    <#
    .SYNOPSIS
    Ensures the target folder exists, creating it if necessary.

    .DESCRIPTION
    The Ensure-TargetFolderExists function checks if a specified folder exists. If it does not exist, it creates the folder and logs the action. Errors during the creation process are handled gracefully with logging and error handling.

    .PARAMETER TargetFolder
    The full path to the target folder that needs to be checked or created.

    .EXAMPLE
    $params = @{
        TargetFolder = "C:\ProgramData\AADMigration\MyFolder"
    }
    Ensure-TargetFolderExists @params
    Ensures the target folder exists or creates it.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the full path to the target folder.")]
        [ValidateNotNullOrEmpty()]
        [string]$TargetFolder
    )

    Begin {
        Write-EnhancedLog -Message "Starting Ensure-TargetFolderExists function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Validate the target folder path is provided
        if (-not $TargetFolder) {
            throw "Target folder path not provided."
        }
    }

    Process {
        try {
            # Check if the target folder exists
            if (-Not (Test-Path -Path $TargetFolder)) {
                Write-EnhancedLog -Message "Target folder does not exist. Creating folder: $TargetFolder" -Level "INFO"
                
                # Create the target folder
                New-Item -Path $TargetFolder -ItemType Directory -Force
                Write-EnhancedLog -Message "Target folder created: $TargetFolder" -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "Target folder already exists: $TargetFolder" -Level "INFO"
            }
        }
        catch {
            # Log and handle any errors encountered during the folder creation process
            Write-EnhancedLog -Message "An error occurred while ensuring the target folder exists: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
        finally {
            Write-EnhancedLog -Message "Exiting Ensure-TargetFolderExists function" -Level "Notice"
        }
    }

    End {
        # Final validation or actions could be placed here if needed
        Write-EnhancedLog -Message "Completed Ensure-TargetFolderExists function" -Level "INFO"
    }
}
