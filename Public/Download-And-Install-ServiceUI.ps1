function Download-And-Install-ServiceUI {
    <#
    .SYNOPSIS
    Downloads and installs the ServiceUI.exe utility from MDT MSI package.

    .DESCRIPTION
    The Download-And-Install-ServiceUI function downloads the Microsoft Deployment Toolkit (MDT) MSI package, extracts the ServiceUI.exe utility, and installs it in a specified target folder.

    .PARAMETER TargetFolder
    The directory where ServiceUI.exe will be installed.

    .PARAMETER DownloadUrl
    The URL to download the MDT MSI package.

    .PARAMETER MsiFileName
    The name of the MSI file to be downloaded.

    .PARAMETER InstalledServiceUIPath
    The path where ServiceUI.exe is located after installing the MDT MSI package.

    .EXAMPLE
    $params = @{
        TargetFolder = "C:\Path\To\Your\Desired\Folder";
        DownloadUrl = "https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi";
        MsiFileName = "MicrosoftDeploymentToolkit_x64.msi";
        InstalledServiceUIPath = "C:\Program Files\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x64\ServiceUI.exe"
    }
    Download-And-Install-ServiceUI @params
    Downloads the MDT MSI package, extracts ServiceUI.exe, and installs it in the target folder.
    #>

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
        Write-EnhancedLog -Message "Starting Download-And-Install-ServiceUI function" -Level "INFO"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        try {
            $removeParams = @{
                TargetFolder = $TargetFolder
                FileName     = "ServiceUI.exe"
            }
            Remove-ExistingServiceUI @removeParams
        }
        catch {
            Write-EnhancedLog -Message "Error during Remove-ExistingServiceUI: $_" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    process {
        $msiPath = Join-Path -Path $([System.IO.Path]::GetTempPath()) -ChildPath $MsiFileName
        $finalPath = Join-Path -Path $TargetFolder -ChildPath "ServiceUI.exe"

        try {
            # Download the MSI file using Start-FileDownloadWithRetry
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

            if (Test-Path -Path $InstalledServiceUIPath) {
                $sourceDir = "`"$(Split-Path -Parent $InstalledServiceUIPath)`""
                $destDir = "`"$TargetFolder`""
                $fileName = "ServiceUI.exe"
                $robocopyCommand = "robocopy.exe $sourceDir $destDir $fileName"
                Write-EnhancedLog -Message "Executing command: $robocopyCommand" -Level "INFO"
                Invoke-Expression $robocopyCommand

                Write-EnhancedLog -Message "ServiceUI.exe has been successfully copied to: $finalPath" -Level "INFO"
            }
            else {
                throw "ServiceUI.exe not found at: $InstalledServiceUIPath"
            }

            $removeMsiParams = @{
                Path  = $msiPath
                Force = $true
            }
            Write-EnhancedLog -Message "Removing downloaded MSI file: $msiPath" -Level "INFO"
            Remove-Item @removeMsiParams
        }
        catch {
            Write-EnhancedLog -Message "An error occurred: $_" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    end {
        Write-EnhancedLog -Message "Download-And-Install-ServiceUI function execution completed." -Level "INFO"
    }
}

# # Example usage of Download-And-Install-ServiceUI function with splatting
# $params = @{
#     TargetFolder = "C:\Path\To\Your\Desired\Folder";
#     DownloadUrl = "https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi";
#     MsiFileName = "MicrosoftDeploymentToolkit_x64.msi";
#     InstalledServiceUIPath = "C:\Program Files\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x64\ServiceUI.exe"
# }
# Download-And-Install-ServiceUI @params
