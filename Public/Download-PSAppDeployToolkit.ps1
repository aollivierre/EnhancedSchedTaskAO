function Download-PSAppDeployToolkit {
    <#
    .SYNOPSIS
    Downloads and installs the PSAppDeployToolkit from a GitHub repository with customizations.

    .DESCRIPTION
    The Download-PSAppDeployToolkit function downloads the latest release of the PSAppDeployToolkit from the specified GitHub repository. It handles the file download, extraction, and customization, and performs verification on the extracted files and copied customizations.

    .PARAMETER GithubRepository
    The GitHub repository from which to download the PSAppDeployToolkit.

    .PARAMETER FilenamePatternMatch
    The filename pattern to match for the PSAppDeployToolkit zip file.

    .PARAMETER DestinationDirectory
    The directory where the toolkit will be extracted.

    .PARAMETER CustomizationsPath
    The path to the folder containing customization files (e.g., .ps1, .png).

    .EXAMPLE
    $params = @{
        GithubRepository     = 'PSAppDeployToolkit/PSAppDeployToolkit';
        FilenamePatternMatch = '*.zip';
        DestinationDirectory = 'C:\temp\psadt1';
        CustomizationsPath   = 'C:\code\IntuneDeviceMigration\DeviceMigration\PSADT-Customizations'
    }
    Download-PSAppDeployToolkit @params
    Downloads the latest PSAppDeployToolkit and applies customizations.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the GitHub repository.")]
        [ValidateNotNullOrEmpty()]
        [string]$GithubRepository,

        [Parameter(Mandatory = $true, HelpMessage = "Provide the filename pattern to match.")]
        [ValidateNotNullOrEmpty()]
        [string]$FilenamePatternMatch,

        [Parameter(Mandatory = $true, HelpMessage = "Provide the destination directory.")]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationDirectory,

        [Parameter(Mandatory = $true, HelpMessage = "Provide the path to customizations.")]
        [ValidateNotNullOrEmpty()]
        [string]$CustomizationsPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Download-PSAppDeployToolkit function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
        
        # Construct GitHub release URI
        $psadtReleaseUri = "https://api.github.com/repos/$GithubRepository/releases/latest"
        Write-EnhancedLog -Message "GitHub release URI: $psadtReleaseUri" -Level "INFO"
        
    }

    Process {
        try {
            # Fetch the download URL from GitHub
            Write-EnhancedLog -Message "Fetching the latest release information from GitHub" -Level "INFO"
            $psadtDownloadUri = (Invoke-RestMethod -Method GET -Uri $psadtReleaseUri).assets |
            Where-Object { $_.name -like $FilenamePatternMatch } |
            Select-Object -ExpandProperty browser_download_url

            if (-not $psadtDownloadUri) {
                throw "No matching file found for pattern: $FilenamePatternMatch"
            }
            Write-EnhancedLog -Message "Found matching download URL: $psadtDownloadUri" -Level "INFO"

            # Prepare paths and download the file
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $tempDownloadPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "PSAppDeployToolkit_$timestamp.zip"
            Write-EnhancedLog -Message "Temporary download path: $tempDownloadPath" -Level "INFO"

            # Download with retries
            $downloadParams = @{
                Source      = $psadtDownloadUri
                Destination = $tempDownloadPath
                MaxRetries  = 3
            }
            Start-FileDownloadWithRetry @downloadParams

            # Unblock and verify downloaded file
            Write-EnhancedLog -Message "Unblocking file at $tempDownloadPath" -Level "INFO"
            Unblock-File -Path $tempDownloadPath

            # Handle extraction
            $finalDestinationPath = Join-Path -Path $DestinationDirectory -ChildPath "PSAppDeployToolkit"
            Write-EnhancedLog -Message "Final destination path: $finalDestinationPath" -Level "INFO"

            if (Test-Path $finalDestinationPath) {
                $removeParams = @{
                    Path               = $finalDestinationPath
                    ForceKillProcesses = $true
                    MaxRetries         = 5
                    RetryInterval      = 10
                }
                Remove-EnhancedItem @removeParams
                Write-EnhancedLog -Message "Removed existing destination path: $finalDestinationPath" -Level "INFO"
            }

            Write-EnhancedLog -Message "Extracting files to $finalDestinationPath" -Level "INFO"
            Expand-Archive -Path $tempDownloadPath -DestinationPath $finalDestinationPath -Force

            # Apply customizations
            Write-EnhancedLog -Message "Applying customizations from $CustomizationsPath" -Level "INFO"
            Apply-PSADTCustomizations -DestinationPath $finalDestinationPath -CustomizationsPath $CustomizationsPath
        }
        catch {
            Write-EnhancedLog -Message "Error in Process block: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
        finally {
            # Clean up temporary download file
            Write-EnhancedLog -Message "Removing temporary download file: $tempDownloadPath" -Level "INFO"
            $removeTempParams = @{
                Path               = $tempDownloadPath
                ForceKillProcesses = $true
                MaxRetries         = 3
                RetryInterval      = 5
            }
            Remove-EnhancedItem @removeTempParams
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Download-PSAppDeployToolkit function" -Level "Notice"
    }
}

function Apply-PSADTCustomizations {
    param (
        [string]$DestinationPath,
        [string]$CustomizationsPath
    )

    Write-EnhancedLog -Message "Copying PS1 and PNG files from customization folder to Toolkit" -Level "INFO"

    # Copy .ps1 files
    Copy-Item -Path (Join-Path $CustomizationsPath '*.ps1') -Destination "$DestinationPath\Toolkit" -Force


    # Copy .xml files
    Copy-Item -Path (Join-Path $CustomizationsPath '*.xml') -Destination "$DestinationPath\Toolkit" -Force

    # Copy .png files
    $appDeployToolkitFolder = "$DestinationPath\Toolkit\AppDeployToolkit"
    if (-not (Test-Path $appDeployToolkitFolder)) {
        Write-EnhancedLog -Message "Error: The AppDeployToolkit folder does not exist at $appDeployToolkitFolder" -Level "ERROR"
        throw "The AppDeployToolkit folder does not exist."
    }

    Copy-Item -Path (Join-Path $CustomizationsPath '*.png') -Destination $appDeployToolkitFolder -Force

    # Verification
    Verify-PSADTFileCopy -CustomizationsPath $CustomizationsPath -DestinationPath $DestinationPath
}

function Verify-PSADTFileCopy {
    param (
        [string]$CustomizationsPath,
        [string]$DestinationPath
    )

    # Verify PS1 files
    Write-EnhancedLog -Message "Verifying PS1 file copy operation..." -Level "INFO"
    $ps1Files = Get-ChildItem -Path (Join-Path $CustomizationsPath '*.ps1')
    $ps1CopyVerification = [System.Collections.Generic.List[string]]::new()

    foreach ($file in $ps1Files) {
        $destinationFile = Join-Path "$DestinationPath\Toolkit" $file.Name
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

    # Verify PNG files
    Write-EnhancedLog -Message "Verifying PNG file copy operation..." -Level "INFO"
    $pngFiles = Get-ChildItem -Path (Join-Path $CustomizationsPath '*.png')
    $pngCopyVerification = [System.Collections.Generic.List[string]]::new()

    foreach ($file in $pngFiles) {
        $destinationFile = Join-Path "$DestinationPath\Toolkit\AppDeployToolkit" $file.Name
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
}
