function Create-VBShiddenPS {
    <#
    .SYNOPSIS
    Creates a VBScript file to run a PowerShell script hidden from the user interface.

    .DESCRIPTION
    This function generates a VBScript (.vbs) file designed to execute a PowerShell script without displaying the PowerShell window. It is particularly useful for running background tasks or scripts that do not require user interaction.

    .PARAMETER Path_local
    The local path where the VBScript will be created.

    .PARAMETER DataFolder
    The folder where the VBScript will be stored (default: 'Data').

    .PARAMETER FileName
    The name of the VBScript file to be created (default: 'run-ps-hidden.vbs').

    .EXAMPLE
    $params = @{
        Path_local = "C:\ProgramData\Scripts"
        DataFolder = "Data"
        FileName   = "run-ps-hidden.vbs"
    }
    Create-VBShiddenPS @params
    Creates a hidden execution VBScript for PowerShell.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the local path for creating the VBScript.")]
        [ValidateNotNullOrEmpty()]
        [string]$Path_local,

        [Parameter(HelpMessage = "Specify the folder where the VBScript will be stored.")]
        [ValidateNotNullOrEmpty()]
        [string]$DataFolder = "Data",

        [Parameter(HelpMessage = "Specify the name of the VBScript file.")]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "run-ps-hidden.vbs"
    )

    Begin {
        Write-EnhancedLog -Message "Starting Create-VBShiddenPS function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters


        $fullDataFolderPath = Join-Path -Path $Path_local -ChildPath $DataFolder
        if (-not (Test-Path -Path $fullDataFolderPath -PathType Container)) {
            # If the DataFolder doesn't exist, create it
            Write-EnhancedLog -Message "DataFolder not found, creating directory: $fullDataFolderPath" -Level "INFO"
            New-Item -Path $fullDataFolderPath -ItemType Directory -Force | Out-Null
        }
        
        # validate the full path for the DataFolder
        if (-not (Test-Path -Path $fullDataFolderPath -PathType Container)) {
            throw "DataFolder does not exist or is not a directory: $fullDataFolderPath"
        }

    }

    Process {
        try {
            # Define the VBScript content
            $scriptBlock = @"
Dim shell, fso, file

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

strPath = WScript.Arguments.Item(0)

If fso.FileExists(strPath) Then
    Set file = fso.GetFile(strPath)
    strCMD = "powershell -nologo -executionpolicy Bypass -command " & Chr(34) & "&{" & file.ShortPath & "}" & Chr(34)
    shell.Run strCMD, 0
End If
"@

            # Combine the paths to construct the full path for the VBScript
            $Path_VBShiddenPS = Join-Path -Path $fullDataFolderPath -ChildPath $FileName

            # Write the VBScript content to the file
            Write-EnhancedLog -Message "Writing VBScript to path: $Path_VBShiddenPS" -Level "INFO"
            $scriptBlock | Out-File -FilePath (New-Item -Path $Path_VBShiddenPS -Force) -Force

            # Validate the VBScript creation
            if (Test-Path -Path $Path_VBShiddenPS) {
                Write-EnhancedLog -Message "VBScript created successfully at $Path_VBShiddenPS" -Level "INFO"
            }
            else {
                throw "Failed to create VBScript at $Path_VBShiddenPS"
            }

            return $Path_VBShiddenPS
        }
        catch {
            Write-EnhancedLog -Message "Error occurred while creating VBScript: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
        finally {
            Write-EnhancedLog -Message "Exiting Create-VBShiddenPS function" -Level "Notice"
        }
    }

    End {
        Write-EnhancedLog -Message "VBScript creation process complete." -Level "INFO"
    }
}
