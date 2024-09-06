function Ensure-RunningAsSystem {
    <#
    .SYNOPSIS
    Ensures that the script is running as the SYSTEM user, invoking it with PsExec if not.

    .DESCRIPTION
    The Ensure-RunningAsSystem function checks if the current session is running as SYSTEM. If it is not, it attempts to re-run the script as SYSTEM using PsExec.

    .PARAMETER PsExec64Path
    The path to the PsExec64 executable.

    .PARAMETER ScriptPath
    The path to the script that needs to be executed as SYSTEM.

    .PARAMETER TargetFolder
    The target folder where PsExec and other required files will be stored.

    .EXAMPLE
    $params = @{
        PsExec64Path = "C:\Tools\PsExec64.exe"
        ScriptPath   = "C:\Scripts\MyScript.ps1"
        TargetFolder = "C:\ProgramData\SystemScripts"
    }
    Ensure-RunningAsSystem @params
    Ensures the script is running as SYSTEM.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PsExec64Path,

        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$TargetFolder
    )

    Begin {
        Write-EnhancedLog -Message "Starting Ensure-RunningAsSystem function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        Write-EnhancedLog -Message "Calling Test-RunningAsSystem" -Level "INFO"
    }

    Process {
        try {
            if (-not (Test-RunningAsSystem)) {
                Write-EnhancedLog -Message "Current session is not running as SYSTEM. Attempting to invoke as SYSTEM..." -Level "WARNING"

                # Ensure the target folder exists
                if (-not (Test-Path -Path $TargetFolder)) {
                    New-Item -Path $TargetFolder -ItemType Directory | Out-Null
                    Write-EnhancedLog -Message "Created target folder: $TargetFolder" -Level "INFO"
                }

                $PsExec64Path = Join-Path -Path $TargetFolder -ChildPath "PsExec64.exe"

                $invokeParams = @{
                    PsExec64Path       = $PsExec64Path
                    ScriptPathAsSYSTEM = $ScriptPath
                    TargetFolder       = $TargetFolder
                    UsePowerShell5     = $true
                }

                Invoke-AsSystem @invokeParams
            }
            else {
                Write-EnhancedLog -Message "Session is already running as SYSTEM." -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Ensure-RunningAsSystem function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Ensure-RunningAsSystem function" -Level "Notice"
    }
}

# Example usage
# $params = @{
#     PsExec64Path = "C:\Tools\PsExec64.exe"
#     ScriptPath   = "C:\Scripts\MyScript.ps1"
#     TargetFolder = "C:\ProgramData\SystemScripts"
# }
# Ensure-RunningAsSystem @params
