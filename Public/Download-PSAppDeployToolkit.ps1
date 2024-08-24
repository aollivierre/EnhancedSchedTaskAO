function Download-PSAppDeployToolkit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$GithubRepository,

        [Parameter(Mandatory = $true)]
        [string]$FilenamePatternMatch,

        [Parameter(Mandatory = $true)]
        [string]$DestinationDirectory,

        [Parameter(Mandatory = $true)]
        [string]$CustomizationsPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Download-PSAppDeployToolkit function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        try {
            $psadtReleaseUri = "https://api.github.com/repos/$GithubRepository/releases/latest"
            Write-EnhancedLog -Message "GitHub release URI: $psadtReleaseUri" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Error in Begin block: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    Process {
        try {
            Write-EnhancedLog -Message "Fetching the latest release information from GitHub" -Level "INFO"
            $psadtDownloadUri = (Invoke-RestMethod -Method GET -Uri $psadtReleaseUri).assets |
            Where-Object { $_.name -like $FilenamePatternMatch } |
            Select-Object -ExpandProperty browser_download_url

            if (-not $psadtDownloadUri) {
                throw "No matching file found for pattern: $FilenamePatternMatch"
            }
            Write-EnhancedLog -Message "Found matching download URL: $psadtDownloadUri" -Level "INFO"

            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $tempDownloadPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "PSAppDeployToolkit_$timestamp.zip"
            Write-EnhancedLog -Message "Temporary download path: $tempDownloadPath" -Level "INFO"

            $downloadParams = @{
                Source      = $psadtDownloadUri
                Destination = $tempDownloadPath
                MaxRetries  = 3
            }
            Start-FileDownloadWithRetry @downloadParams

            Write-EnhancedLog -Message "Unblocking file at $tempDownloadPath" -Level "INFO"
            Unblock-File -Path $tempDownloadPath

            $finalDestinationPath = Join-Path -Path $DestinationDirectory -ChildPath "PSAppDeployToolkit"
            Write-EnhancedLog -Message "Final destination path: $finalDestinationPath" -Level "INFO"

            if (Test-Path $finalDestinationPath) {
                Remove-Item -Path $finalDestinationPath -Recurse -Force
                Write-EnhancedLog -Message "Removed existing destination path: $finalDestinationPath" -Level "INFO"
            }            

            Write-EnhancedLog -Message "Extracting files directly to $finalDestinationPath" -Level "INFO"
            Expand-Archive -Path $tempDownloadPath -DestinationPath $finalDestinationPath -Force

            Write-EnhancedLog -Message "Copying PS1 files from customization folder to $finalDestinationPath\Toolkit" -Level "INFO"
            Copy-Item -Path (Join-Path $CustomizationsPath '*.ps1') -Destination "$finalDestinationPath\Toolkit" -Force

            Write-EnhancedLog -Message "Copying PNG files from customization folder to $finalDestinationPath\Toolkit\AppDeployToolkit\" -Level "INFO"
            $appDeployToolkitFolder = "$finalDestinationPath\Toolkit\AppDeployToolkit"

            if (-not (Test-Path $appDeployToolkitFolder)) {
                Write-EnhancedLog -Message "Error: The AppDeployToolkit folder does not exist at $appDeployToolkitFolder" -Level "ERROR"
                throw "The AppDeployToolkit folder does not exist."
            }
            
            Copy-Item -Path (Join-Path $CustomizationsPath '*.png') -Destination $appDeployToolkitFolder -Force
            

            # Verify the extraction operation
            Write-EnhancedLog -Message "Verifying the extraction operation..." -Level "INFO"
            $extractedToolkitPath = "$finalDestinationPath\Toolkit"
            $extractedAppDeployToolkitPath = "$finalDestinationPath\Toolkit\AppDeployToolkit"

            $extractionVerification = [System.Collections.Generic.List[string]]::new()

            if (-not (Test-Path $extractedToolkitPath)) {
                $extractionVerification.Add("Toolkit folder does not exist.")
            }

            if (-not (Test-Path $extractedAppDeployToolkitPath)) {
                $extractionVerification.Add("AppDeployToolkit folder does not exist.")
            }

            if ($extractionVerification.Count -gt 0) {
                Write-EnhancedLog -Message "Discrepancies found during extraction verification: $($extractionVerification -join ', ')" -Level "ERROR"
            }
            else {
                Write-EnhancedLog -Message "Extraction verification completed successfully with no discrepancies." -Level "INFO"
            }

            # Verify the copy operation for PS1 files
            Write-EnhancedLog -Message "Verifying the PS1 file copy operation..." -Level "INFO"
            $ps1Files = Get-ChildItem -Path (Join-Path $CustomizationsPath '*.ps1')
            $ps1CopyVerification = [System.Collections.Generic.List[string]]::new()

            foreach ($file in $ps1Files) {
                $destinationFile = Join-Path "$finalDestinationPath\Toolkit" $file.Name
                if (-not (Test-Path $destinationFile)) {
                    $ps1CopyVerification.Add("$($file.Name) was not copied.")
                }
            }

            if ($ps1CopyVerification.Count -gt 0) {
                Write-EnhancedLog -Message "Discrepancies found during PS1 file copy verification: $($ps1CopyVerification -join ', ')" -Level "ERROR"
            }
            else {
                Write-EnhancedLog -Message "PS1 file copy verification completed successfully with no discrepancies." -Level "INFO"
            }

            # Verify the copy operation for PNG files
            Write-EnhancedLog -Message "Verifying the PNG file copy operation..." -Level "INFO"
            $pngFiles = Get-ChildItem -Path (Join-Path $CustomizationsPath '*.png')
            $pngCopyVerification = [System.Collections.Generic.List[string]]::new()

            foreach ($file in $pngFiles) {
                $destinationFile = Join-Path "$extractedAppDeployToolkitPath" $file.Name
                if (-not (Test-Path $destinationFile)) {
                    $pngCopyVerification.Add("$($file.Name) was not copied.")
                }
            }

            if ($pngCopyVerification.Count -gt 0) {
                Write-EnhancedLog -Message "Discrepancies found during PNG file copy verification: $($pngCopyVerification -join ', ')" -Level "ERROR"
            }
            else {
                Write-EnhancedLog -Message "PNG file copy verification completed successfully with no discrepancies." -Level "INFO"
            }


            Write-EnhancedLog -Message "Removing temporary download file: $tempDownloadPath" -Level "INFO"
            Remove-Item -Path $tempDownloadPath -Force

            Write-EnhancedLog -Message "Download and extraction completed successfully." -Level "Notice"
        }
        catch {
            Write-EnhancedLog -Message "Error in Process block: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Download-PSAppDeployToolkit function" -Level "Notice"
    }
}

# # Example usage
# $params = @{
#     GithubRepository     = 'PSAppDeployToolkit/PSAppDeployToolkit';
#     FilenamePatternMatch = '*.zip';
#     DestinationDirectory = 'C:\temp\psadt1';
#     CustomizationsPath   = 'C:\code\IntuneDeviceMigration\DeviceMigration\PSADT-Customizations'
# }
# Download-PSAppDeployToolkit @params
