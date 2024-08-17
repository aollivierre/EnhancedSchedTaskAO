function Download-PSAppDeployToolkit {
    <#
    .SYNOPSIS
    Downloads and extracts the latest PSAppDeployToolkit from a GitHub repository.

    .DESCRIPTION
    The Download-PSAppDeployToolkit function fetches the latest release of the PSAppDeployToolkit from a specified GitHub repository, downloads the release, and extracts its contents to a specified directory.

    .PARAMETER GithubRepository
    The GitHub repository from which to download the PSAppDeployToolkit (e.g., 'PSAppDeployToolkit/PSAppDeployToolkit').

    .PARAMETER FilenamePatternMatch
    The filename pattern to match the release asset (e.g., '*.zip').

    .PARAMETER ScriptDirectory
    The directory where the toolkit files should be extracted.

    .EXAMPLE
    $params = @{
        GithubRepository = 'PSAppDeployToolkit/PSAppDeployToolkit';
        FilenamePatternMatch = '*.zip';
        ScriptDirectory = 'C:\YourScriptDirectory'
    }
    Download-PSAppDeployToolkit @params
    Downloads and extracts the latest PSAppDeployToolkit to the specified directory.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$GithubRepository,

        [Parameter(Mandatory = $true)]
        [string]$FilenamePatternMatch,

        [Parameter(Mandatory = $true)]
        [string]$ScriptDirectory
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

            # Set the path for the temporary download location
            $zipTempDownloadPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath (Split-Path -Path $psadtDownloadUri -Leaf)
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

            # Set the temporary extraction path
            $tempExtractionPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "PSAppDeployToolkit"
            if (-not (Test-Path $tempExtractionPath)) {
                New-Item -Path $tempExtractionPath -ItemType Directory | Out-Null
            }

            # Extract the contents of the zip file to the temporary extraction path
            Write-EnhancedLog -Message "Extracting file from $zipTempDownloadPath to $tempExtractionPath" -Level "INFO"
            Expand-Archive -Path $zipTempDownloadPath -DestinationPath $tempExtractionPath -Force

            # Use robocopy to copy all files from the temporary extraction folder to the ScriptDirectory, excluding deploy-application.ps1
            Write-EnhancedLog -Message "Copying files from $tempExtractionPath to $ScriptDirectory" -Level "INFO"
            $robocopyArgs = @(
                $tempExtractionPath,
                $ScriptDirectory,
                "/E", # Copies subdirectories, including empty ones.
                "/XF", "deploy-application.ps1"
            )
            $robocopyCommand = "robocopy.exe $($robocopyArgs -join ' ')"
            Write-EnhancedLog -Message "Executing command: $robocopyCommand" -Level "INFO"
            Invoke-Expression $robocopyCommand

            # Copy Deploy-Application.exe from Toolkit to ScriptDirectory
            Write-EnhancedLog -Message "Copying Deploy-Application.exe from Toolkit to $ScriptDirectory" -Level "INFO"
            $deployAppSource = Join-Path -Path $tempExtractionPath -ChildPath "Toolkit"
            $deployAppArgs = @(
                $deployAppSource,
                $ScriptDirectory,
                "Deploy-Application.exe",
                "/COPY:DAT",
                "/R:1",
                "/W:1"
            )
            $deployAppCommand = "robocopy.exe $($deployAppArgs -join ' ')"
            Write-EnhancedLog -Message "Executing command: $deployAppCommand" -Level "INFO"
            Invoke-Expression $deployAppCommand

            Write-EnhancedLog -Message "Files copied successfully to $ScriptDirectory" -Level "INFO"

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
            Write-EnhancedLog -Message "File extracted and copied successfully to $ScriptDirectory" -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "Error in End block: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }

        Write-EnhancedLog -Message "Exiting Download-PSAppDeployToolkit function" -Level "Notice"
    }
}

# Example usage
# $params = @{
#     GithubRepository = 'PSAppDeployToolkit/PSAppDeployToolkit';
#     FilenamePatternMatch = '*.zip';
#     ScriptDirectory = 'C:\YourScriptDirectory'
# }
# Download-PSAppDeployToolkit @params