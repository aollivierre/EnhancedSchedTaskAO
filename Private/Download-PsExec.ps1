function Download-PsExec {
    <#
    .SYNOPSIS
    Downloads and extracts PsExec64.exe from the official Sysinternals PSTools package.

    .DESCRIPTION
    The Download-PsExec function downloads the PSTools package from the official Sysinternals website, extracts PsExec64.exe, and places it in the specified target folder.

    .PARAMETER TargetFolder
    The target folder where PsExec64.exe will be stored.

    .EXAMPLE
    $params = @{
        TargetFolder = "C:\ProgramData\SystemTools"
    }
    Download-PsExec @params
    Downloads PsExec64.exe to the specified target folder.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetFolder
    )

    Begin {
        Write-EnhancedLog -Message "Starting Download-PsExec function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Ensure the target folder exists
        Ensure-TargetFolderExists -TargetFolder $TargetFolder
        Write-EnhancedLog -Message "Removing existing PsExec from target folder: $TargetFolder" -Level "INFO"
        
        Remove-ExistingPsExec -TargetFolder $TargetFolder
    }

    Process {
        try {
            # Define the URL for PsExec download
            $url = "https://download.sysinternals.com/files/PSTools.zip"
            # Full path for the downloaded file
            $zipPath = Join-Path -Path $TargetFolder -ChildPath "PSTools.zip"

            # Download the PSTools.zip file containing PsExec with retry logic
            Write-EnhancedLog -Message "Downloading PSTools.zip from: $url to: $zipPath" -Level "INFO"
            
            $downloadParams = @{
                Source      = $url
                Destination = $zipPath
                MaxRetries  = 3
            }
            Start-FileDownloadWithRetry @downloadParams

            # Extract PsExec64.exe from the zip file
            Write-EnhancedLog -Message "Extracting PSTools.zip to: $TargetFolder\PStools" -Level "INFO"
            Expand-Archive -Path $zipPath -DestinationPath "$TargetFolder\PStools" -Force

            # Specific extraction of PsExec64.exe
            $extractedFolderPath = Join-Path -Path $TargetFolder -ChildPath "PSTools"
            $PsExec64Path = Join-Path -Path $extractedFolderPath -ChildPath "PsExec64.exe"
            $finalPath = Join-Path -Path $TargetFolder -ChildPath "PsExec64.exe"

            # Move PsExec64.exe to the desired location
            if (Test-Path -Path $PsExec64Path) {
                Write-EnhancedLog -Message "Moving PsExec64.exe from: $PsExec64Path to: $finalPath" -Level "INFO"
                Move-Item -Path $PsExec64Path -Destination $finalPath

                # Remove the downloaded zip file and extracted folder
                Write-EnhancedLog -Message "Removing downloaded zip file and extracted folder" -Level "INFO"
                Remove-Item -Path $zipPath -Force
                Remove-Item -Path $extractedFolderPath -Recurse -Force

                Write-EnhancedLog -Message "PsExec64.exe has been successfully downloaded and moved to: $finalPath" -Level "INFO"
            } else {
                Write-EnhancedLog -Message "PsExec64.exe not found in the extracted files." -Level "ERROR"
                throw "PsExec64.exe not found after extraction."
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Download-PsExec function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Download-PsExec function" -Level "Notice"
    }
}

# Example usage
# $params = @{
#     TargetFolder = "C:\ProgramData\SystemTools"
# }
# Download-PsExec @params
