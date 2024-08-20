function Validate-PathExistsWithLogging {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )


    Begin {
        Write-EnhancedLog -Message "Starting Validate-PathExistsWithLogging function" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Initialize counters and lists
        $totalExpectedFiles = [System.Collections.Generic.List[int]]::new()
        $totalValidatedFiles = [System.Collections.Generic.List[int]]::new()
        $missingFiles = [System.Collections.Generic.List[string]]::new()

    }

    Process {
        foreach ($Path in $Paths) {
            try {
                $exists = Test-Path -Path $Path

                if ($exists) {
                    Write-EnhancedLog -Message "Path exists: $Path" -Level "INFO"

                    $filesInPath = Get-ChildItem -Path $Path -Recurse -File
                    $totalExpectedFiles.Add($filesInPath.Count)
                    $totalValidatedFiles.Add($filesInPath.Count)

                    Write-EnhancedLog -Message "Total files found in $Path $($filesInPath.Count)" -Level "INFO"
                }
                else {
                    Write-EnhancedLog -Message "Path does not exist: $Path" -Level "WARNING"
                    $missingFiles.Add($Path)
                }
            }
            catch {
                Write-EnhancedLog -Message "Error during path validation for: $Path. Error: $($_.Exception.Message)" -Level "ERROR"
                Handle-Error -ErrorRecord $_
            }
        }
    }

    End {
        # Sum up the total counts
        $sumExpectedFiles = $totalExpectedFiles | Measure-Object -Sum | Select-Object -ExpandProperty Sum
        $sumValidatedFiles = $totalValidatedFiles | Measure-Object -Sum | Select-Object -ExpandProperty Sum

        if ($sumValidatedFiles -lt $sumExpectedFiles) {
            $missingCount = $sumExpectedFiles - $sumValidatedFiles
            Write-EnhancedLog -Message "Validation incomplete: $missingCount files are missing." -Level "ERROR"
            $missingFiles | ForEach-Object {
                Write-EnhancedLog -Message "Missing file: $_" -Level "ERROR"
            }
        }
        else {
            Write-EnhancedLog -Message "Validation complete: All files accounted for." -Level "INFO"
        }

        # Log summary and results
        Write-EnhancedLog -Message "Validation Summary: Total Files Expected: $sumExpectedFiles, Total Files Validated: $sumValidatedFiles" -Level "INFO"
        Write-EnhancedLog -Message "Exiting Validate-PathExistsWithLogging function" -Level "INFO"

        # Return result summary
        return @{
            TotalExpectedFiles  = $sumExpectedFiles
            TotalValidatedFiles = $sumValidatedFiles
            MissingFiles        = $missingFiles
        }
    }
}

# Example usage
# $results = Validate-PathExistsWithLogging -Paths "C:\Path\To\Check", "C:\Another\Path"
