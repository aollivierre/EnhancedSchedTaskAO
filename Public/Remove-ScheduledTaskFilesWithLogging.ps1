function Remove-ScheduledTaskFilesWithLogging {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Begin {
        Write-EnhancedLog -Message "Starting Remove-ScheduledTaskFilesWithLogging function" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Validate before removal
            $validationResultsBefore = Validate-PathExistsWithLogging -Paths $Path

            if ($validationResultsBefore.TotalValidatedFiles -gt 0) {
                Write-EnhancedLog -Message "Calling Remove-Item for path: $Path" -Level "INFO"
                Remove-Item -Path $Path -Recurse -Force

                # Validate after removal
                $validationResultsAfter = Validate-PathExistsWithLogging -Paths $Path

                if ($validationResultsAfter.TotalValidatedFiles -gt 0) {
                    Write-EnhancedLog -Message "Path $Path still exists after attempting to remove. Manual intervention may be required." -Level "ERROR"
                } else {
                    Write-EnhancedLog -Message "All files within $Path successfully removed." -Level "CRITICAL"
                }
            } else {
                Write-EnhancedLog -Message "Path $Path does not exist. No action taken." -Level "WARNING"
            }
        } catch {
            Write-EnhancedLog -Message "Error during Remove-Item for path: $Path. Error: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Remove-ScheduledTaskFilesWithLogging function" -Level "INFO"
    }
}

# Example usage
# Remove-ScheduledTaskFilesWithLogging -Path "C:\Path\To\ScheduledTaskFiles"
