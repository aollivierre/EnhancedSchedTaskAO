function Create-ScheduledTask {
    <#
    .SYNOPSIS
    Creates a scheduled task.

    .DESCRIPTION
    The Create-ScheduledTask function creates a scheduled task that runs a specified PowerShell script at logon with the highest privileges.

    .PARAMETER TaskPath
    The path of the task in Task Scheduler.

    .PARAMETER TaskName
    The name of the scheduled task.

    .PARAMETER ScriptPath
    The path to the PowerShell script to be executed.

    .EXAMPLE
    $params = @{
        TaskPath   = "AAD Migration"
        TaskName   = "Run Post-migration cleanup"
        ScriptPath = "C:\ProgramData\AADMigration\Scripts\PostRunOnce3.ps1"
    }
    Create-ScheduledTask @params
    Creates the scheduled task to run the specified script.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskPath,

        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    Begin {
        Write-EnhancedLog -Message "Starting Create-ScheduledTask function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {

            # Unregister the task if it exists
            Unregister-ScheduledTaskWithLogging -TaskName $TaskName

            # Create the new scheduled task
            $arguments = "-executionpolicy Bypass -file $ScriptPath"

            Write-EnhancedLog -Message "Creating scheduled task: $TaskName at $TaskPath to run script: $ScriptPath" -Level "INFO"
            
            $params = @{
                Execute    = 'PowerShell.exe'
                Argument   = $arguments
            }
            $action = New-ScheduledTaskAction @params

            $params = @{
                AtLogOn = $true
            }
            $trigger = New-ScheduledTaskTrigger @params

            $params = @{
                UserId = "SYSTEM"
                RunLevel = "Highest"
            }
            $principal = New-ScheduledTaskPrincipal @params

            $params = @{
                Principal = $principal
                Action    = $action
                Trigger   = $trigger
                TaskName  = $TaskName
                Description = "Run post AAD Migration cleanup"
                TaskPath  = $TaskPath
            }
            $Task = Register-ScheduledTask @params

            Write-EnhancedLog -Message "Scheduled task created successfully." -Level "INFO"
        }
        catch {
            Write-EnhancedLog -Message "An error occurred in Create-ScheduledTask function: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Create-ScheduledTask function" -Level "Notice"
    }
}

# # Example usage
# $params = @{
#     TaskPath   = "AAD Migration"
#     TaskName   = "Run Post-migration cleanup"
#     ScriptPath = "C:\ProgramData\AADMigration\Scripts\PostRunOnce3.ps1"
# }
# Create-ScheduledTask @params