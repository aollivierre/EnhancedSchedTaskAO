function Download-And-Install-ServiceUI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetFolder,

        [Parameter(Mandatory = $true)]
        [string]$DownloadUrl,

        [Parameter(Mandatory = $true)]
        [string]$MsiFileName,

        [Parameter(Mandatory = $true)]
        [string]$InstalledServiceUIPath
    )

    begin {
        # Log the start of the function
        Write-EnhancedLog -Message "Starting Download-And-Install-ServiceUI function" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Validate MDT installation before attempting to download or install
        $mdtValidationParams = @{
            SoftwareName        = "Microsoft Deployment Toolkit"
            MinVersion          = [version]"6.3.8456.1000"  # The version from the screenshot
            # RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{MDT ProductCode}"  # You need to replace this with the actual product code for MDT from the registry
            # ExePath              = "C:\Program Files\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x64\ServiceUI.exe"  # Path to the MDT executable
            MaxRetries          = 3
            DelayBetweenRetries = 5
        }

        $mdtValidationResult = Validate-SoftwareInstallation @mdtValidationParams

        if ($mdtValidationResult.IsInstalled) {
            Write-EnhancedLog -Message "MDT is already installed and meets the minimum version requirement." -Level "INFO"
            $skipInstallation = $true
        }
        else {
            Write-EnhancedLog -Message "MDT is not installed or does not meet the minimum version requirement. Proceeding with installation." -Level "INFO"
            $skipInstallation = $false
        }
    }

    process {
        if (-not $skipInstallation) {
            # Set up paths for download and installation
            $timestamp = Get-Date -Format "yyyyMMddHHmmss"
            $msiPath = Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath "$($timestamp)_$MsiFileName"
            $finalPath = Join-Path -Path $TargetFolder -ChildPath "ServiceUI.exe"

            try {
                # Download the MSI file
                $downloadParams = @{
                    Source      = $DownloadUrl
                    Destination = $msiPath
                    MaxRetries  = 3
                }
                Start-FileDownloadWithRetry @downloadParams

                # Install the MDT MSI package
                $installParams = @{
                    FilePath     = "msiexec.exe"
                    ArgumentList = "/i `"$msiPath`" /quiet /norestart"
                    Wait         = $true
                }
                Write-EnhancedLog -Message "Installing MDT MSI from: $msiPath" -Level "INFO"
                Start-Process @installParams

                # Validate MDT installation after installation
                $mdtValidationResult = Validate-SoftwareInstallation @mdtValidationParams

                if (-not $mdtValidationResult.IsInstalled) {
                    Write-EnhancedLog -Message "MDT installation failed or does not meet the minimum version requirement." -Level "ERROR"
                    throw "MDT installation failed."
                }

                Write-EnhancedLog -Message "MDT installed successfully." -Level "INFO"

                # Remove the downloaded MSI file
                Write-EnhancedLog -Message "Removing downloaded MSI file: $msiPath" -Level "INFO"
                Remove-Item -Path $msiPath -Force
            }
            catch {
                Write-EnhancedLog -Message "An error occurred: $_" -Level "ERROR"
                Handle-Error -ErrorRecord $_
                throw $_
            }
        }


        # Set the final path where ServiceUI.exe should be located
        $finalPath = Join-Path -Path $TargetFolder -ChildPath "ServiceUI.exe"

        # Copy ServiceUI.exe to the target folder
        if (Test-Path -Path $InstalledServiceUIPath) {
            Write-EnhancedLog -Message "Copying ServiceUI.exe from $InstalledServiceUIPath to $finalPath" -Level "INFO"
            Copy-Item -Path $InstalledServiceUIPath -Destination $TargetFolder -Force

            # Debug: Check the value of $finalPath
            Write-EnhancedLog -Message "Final path for verification: $finalPath" -Level "INFO"

            # Verify the copy operation
            if (Test-Path -Path $finalPath) {
                Write-EnhancedLog -Message "Copy verification completed successfully." -Level "INFO"
            }
            else {
                Write-EnhancedLog -Message "Copy verification failed: ServiceUI.exe not found at $finalPath" -Level "ERROR"
                throw "ServiceUI.exe not found after copy operation."
            }
        }
        else {
            Write-EnhancedLog -Message "ServiceUI.exe not found at: $InstalledServiceUIPath" -Level "ERROR"
            throw "ServiceUI.exe not found."
        }

    }

    end {
        # Log the end of the function
        Write-EnhancedLog -Message "Download-And-Install-ServiceUI function execution completed." -Level "INFO"
    }
}


# $params = @{
#     TargetFolder           = "C:\temp";
#     DownloadUrl            = "https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi";
#     MsiFileName            = "MicrosoftDeploymentToolkit_x64.msi";
#     InstalledServiceUIPath = "C:\Program Files\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x64\ServiceUI.exe"
# }
# Download-And-Install-ServiceUI @params