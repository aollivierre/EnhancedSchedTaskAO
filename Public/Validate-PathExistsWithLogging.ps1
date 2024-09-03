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
                if ([string]::IsNullOrWhiteSpace($Path)) {
                    Write-EnhancedLog -Message "Invalid Path: Path is null or empty." -Level "ERROR"
                    throw "Invalid Path: Path is null or empty."
                }

                Write-EnhancedLog -Message "Validating path: $Path" -Level "INFO"
                $exists = Test-Path -Path $Path

                if ($exists) {
                    Write-EnhancedLog -Message "Path exists: $Path" -Level "INFO"

                    try {
                        $filesInPath = Get-ChildItem -Path $Path -Recurse -File
                        $fileCount = $filesInPath.Count

                        # Update counters
                        $totalExpectedFiles.Add($fileCount)
                        $totalValidatedFiles.Add($fileCount)

                        Write-EnhancedLog -Message "Total files found in $Path $fileCount" -Level "INFO"
                    }
                    catch {
                        Write-EnhancedLog -Message "Error retrieving files in path: $Path. Error: $($_.Exception.Message)" -Level "ERROR"
                        throw "Error retrieving files in path: $Path. Error: $($_.Exception.Message)"
                    }
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

        if ($sumExpectedFiles -eq 0) {
            Write-EnhancedLog -Message "No files expected. Ensure the paths provided are correct and contain files." -Level "WARNING"
        }

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