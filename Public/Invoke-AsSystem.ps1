function Invoke-AsSystem {
    <#
    .SYNOPSIS
    Executes a PowerShell script under the SYSTEM context, similar to Intune's execution context.

    .DESCRIPTION
    The Invoke-AsSystem function executes a PowerShell script using PsExec64.exe to run under the SYSTEM context. This method is useful for scenarios requiring elevated privileges beyond the current user's capabilities.

    .PARAMETER PsExec64Path
    Specifies the full path to PsExec64.exe. If not provided, it assumes PsExec64.exe is in the same directory as the script.

    .PARAMETER ScriptPathAsSYSTEM
    Specifies the path to the PowerShell script you want to run as SYSTEM.

    .PARAMETER TargetFolder
    Specifies the target folder where PsExec64.exe and other required files will be stored.

    .PARAMETER UsePowerShell5
    Specifies whether to always use PowerShell 5 for launching the process. If set to $true, the script will use the PowerShell 5 executable path.

    .EXAMPLE
    Invoke-AsSystem -PsExec64Path "C:\Tools\PsExec64.exe" -ScriptPathAsSYSTEM "C:\Scripts\MyScript.ps1" -TargetFolder "C:\ProgramData\SystemScripts" -UsePowerShell5 $true

    Executes PowerShell 5 as SYSTEM using PsExec64.exe located at "C:\Tools\PsExec64.exe".

    .NOTES
    Ensure PsExec64.exe is available and the script has the necessary permissions to execute it.

    .LINK
    https://docs.microsoft.com/en-us/sysinternals/downloads/psexec
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PsExec64Path,

        [Parameter(Mandatory = $true)]
        [string]$ScriptPathAsSYSTEM,

        [Parameter(Mandatory = $true)]
        [string]$TargetFolder,

        [Parameter(Mandatory = $false)]
        [bool]$UsePowerShell5 = $false
    )

    begin {
        CheckAndElevate

        # Get the PowerShell executable path
        $pwshPath = if ($UsePowerShell5) {
            "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        } else {
            Get-PowerShellPath
        }

        # Define the command for running PowerShell
        $commandToRun = "`"$pwshPath`" -NoExit -ExecutionPolicy Bypass -File `"$ScriptPathAsSYSTEM`""

        # Define the arguments for PsExec64.exe to run PowerShell as SYSTEM with the script
        $argList = @(
            "-accepteula",
            "-i",
            "-s",
            "-d",
            $commandToRun
        )

        Write-EnhancedLog -Message "Preparing to execute PowerShell as SYSTEM using PsExec64 with the script: $ScriptPathAsSYSTEM" -Level "INFO"

        # Log parameters using splatting
        $logParams = @{
            PsExec64Path       = $PsExec64Path
            ScriptPathAsSYSTEM = $ScriptPathAsSYSTEM
            TargetFolder       = $TargetFolder
            UsePowerShell5     = $UsePowerShell5
        }
        Log-Params -Params $logParams

        # Download PsExec to the target folder if necessary
        Download-PsExec -targetFolder $TargetFolder
    }

    process {
        try {
            # Ensure PsExec64Path exists
            if (-not (Test-Path -Path $PsExec64Path)) {
                $errorMessage = "PsExec64.exe not found at path: $PsExec64Path"
                Write-EnhancedLog -Message $errorMessage -Level "ERROR"
                throw $errorMessage
            }

            # Splat parameters for Start-Process
            $processParams = @{
                FilePath     = $PsExec64Path
                ArgumentList = $argList
                Wait         = $true
                NoNewWindow  = $true
            }

            # Run PsExec64.exe with the defined arguments to execute the script as SYSTEM
            Write-EnhancedLog -Message "Executing PsExec64.exe to start PowerShell as SYSTEM running script: $ScriptPathAsSYSTEM" -Level "INFO"
            Start-Process @processParams
            
            Write-EnhancedLog -Message "SYSTEM session started. Closing elevated session..." -Level "INFO"
            exit
        }
        catch {
            Write-EnhancedLog -Message "An error occurred: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }
}
