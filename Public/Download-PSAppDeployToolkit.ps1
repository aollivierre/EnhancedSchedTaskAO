function Download-PSAppDeployToolkit {
    <#
    .SYNOPSIS
    Downloads and extracts the latest PSAppDeployToolkit from a GitHub repository.

    .DESCRIPTION
    The Download-PSAppDeployToolkit function fetches the latest release of the PSAppDeployToolkit from a specified GitHub repository, downloads the release, and extracts its contents to a specified directory named `PSAppDeployToolkit`.

    .PARAMETER GithubRepository
    The GitHub repository from which to download the PSAppDeployToolkit (e.g., 'PSAppDeployToolkit/PSAppDeployToolkit').

    .PARAMETER FilenamePatternMatch
    The filename pattern to match the release asset (e.g., '*.zip').

    .PARAMETER DestinationDirectory
    The parent directory where the `PSAppDeployToolkit` folder will be created.

    .EXAMPLE
    $params = @{
        GithubRepository = 'PSAppDeployToolkit/PSAppDeployToolkit';
        FilenamePatternMatch = '*.zip';
        DestinationDirectory = 'C:\YourScriptDirectory'
    }
    Download-PSAppDeployToolkit @params
    Downloads and extracts the latest PSAppDeployToolkit to a `PSAppDeployToolkit` directory within the specified parent directory.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$GithubRepository,

        [Parameter(Mandatory = $true)]
        [string]$FilenamePatternMatch,

        [Parameter(Mandatory = $true)]
        [string]$DestinationDirectory
    )

    Begin {
        Write-EnhancedLog -Message "Starting Download-PSAppDeployToolkit function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        try {
            # Set the URI to get the latest release information from the GitHub repository
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
            # Fetch the latest release information from GitHub
            Write-EnhancedLog -Message "Fetching the latest release information from GitHub" -Level "INFO"
            $psadtDownloadUri = (Invoke-RestMethod -Method GET -Uri $psadtReleaseUri).assets |
            Where-Object { $_.name -like $FilenamePatternMatch } |
            Select-Object -ExpandProperty browser_download_url

            if (-not $psadtDownloadUri) {
                throw "No matching file found for pattern: $FilenamePatternMatch"
            }
            Write-EnhancedLog -Message "Found matching download URL: $psadtDownloadUri" -Level "INFO"

            # Set the path for the temporary download location with a timestamp
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $zipTempDownloadPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "PSAppDeployToolkit_$timestamp.zip"
            Write-EnhancedLog -Message "Temporary download path: $zipTempDownloadPath" -Level "INFO"

            # Download the file with retry mechanism using Start-FileDownloadWithRetry
            $downloadParams = @{
                Source      = $psadtDownloadUri
                Destination = $zipTempDownloadPath
                MaxRetries  = 3
            }
            Start-FileDownloadWithRetry @downloadParams

            # Unblock the downloaded file if necessary
            Write-EnhancedLog -Message "Unblocking file at $zipTempDownloadPath" -Level "INFO"
            Unblock-File -Path $zipTempDownloadPath

            # Create a timestamped temporary folder for extraction
            $tempExtractionPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "PSAppDeployToolkit_$timestamp"
            if (-not (Test-Path $tempExtractionPath)) {
                New-Item -Path $tempExtractionPath -ItemType Directory | Out-Null
            }

            # Extract the contents of the zip file to the temporary extraction path
            Write-EnhancedLog -Message "Extracting file from $zipTempDownloadPath to $tempExtractionPath" -Level "INFO"
            Expand-Archive -Path $zipTempDownloadPath -DestinationPath $tempExtractionPath -Force

            # Define the PSAppDeployToolkit directory path
            $psAppDeployToolkitPath = Join-Path -Path $DestinationDirectory -ChildPath "PSAppDeployToolkit"
            if (-not (Test-Path $psAppDeployToolkitPath)) {
                New-Item -Path $psAppDeployToolkitPath -ItemType Directory | Out-Null
                Write-EnhancedLog -Message "Created directory: $psAppDeployToolkitPath" -Level "INFO"
            }

            # Use Copy-Item to copy the entire extracted folder structure, excluding Toolkit\Deploy-Application.ps1 and AppDeployToolkitBanner.png
            Write-EnhancedLog -Message "Copying files from $tempExtractionPath to $psAppDeployToolkitPath, excluding Toolkit\Deploy-Application.ps1 and AppDeployToolkitBanner.png" -Level "INFO"


            #ToDO fix the following as it is creating duplicate empty folders within each other so either fix it with copy-item or bring back robocopy but maintain exclusions or use a hybrid approach of using robocopy to maintain the original folder structure and then use copy-item to copy specific items from source to destination 

            Get-ChildItem -Path $tempExtractionPath -Recurse | 
            Where-Object { 
                $_.FullName -notmatch '\\Toolkit\\Deploy-Application\.ps1$' -and
                $_.Name -ne 'AppDeployToolkitBanner.png'
            } |
            ForEach-Object {
                $destinationPath = $_.FullName.Replace($tempExtractionPath, $psAppDeployToolkitPath)
                if (-not (Test-Path -Path (Split-Path -Path $destinationPath -Parent))) {
                    New-Item -Path (Split-Path -Path $destinationPath -Parent) -ItemType Directory | Out-Null
                }
                Copy-Item -Path $_.FullName -Destination $destinationPath -Force
            }


            Write-EnhancedLog -Message "Files copied successfully from Source: $tempExtractionPath to Destination: $psAppDeployToolkitPath" -Level "INFO"

            # Verify the copy operation
            Write-EnhancedLog -Message "Verifying the copy operation..." -Level "INFO"
            $verificationResults = Verify-CopyOperation -SourcePath $tempExtractionPath -DestinationPath $psAppDeployToolkitPath

            # Handle the verification results if necessary
            if ($verificationResults.Count -gt 0) {
                Write-EnhancedLog -Message "Discrepancies found during copy verification." -Level "ERROR"
            }
            else {
                Write-EnhancedLog -Message "Copy verification completed successfully with no discrepancies." -Level "INFO"
            }

            # Clean up temporary files
            Write-EnhancedLog -Message "Removing temporary download file: $zipTempDownloadPath" -Level "INFO"
            Remove-Item -Path $zipTempDownloadPath -Force

            Write-EnhancedLog -Message "Removing temporary extraction folder: $tempExtractionPath" -Level "INFO"
            Remove-Item -Path $tempExtractionPath -Recurse -Force
        }
        catch {
            Write-EnhancedLog -Message "Error in Process block: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        try {
            Write-EnhancedLog -Message "File extracted and copied successfully to $psAppDeployToolkitPath" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Error in End block: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }

        Write-EnhancedLog -Message "Exiting Download-PSAppDeployToolkit function" -Level "Notice"
    }
}

# # Example usage
# $params = @{
#     GithubRepository = 'PSAppDeployToolkit/PSAppDeployToolkit';
#     FilenamePatternMatch = '*.zip';
#     DestinationDirectory = 'C:\temp\psadt-temp6'
# }
# Download-PSAppDeployToolkit @params
