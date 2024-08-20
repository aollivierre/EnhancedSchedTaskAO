function Create-InteractiveMigrationTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskPath,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $true)]
        [string]$ServiceUIPath,
        
        [Parameter(Mandatory = $true)]
        [string]$ToolkitExecutablePath,
        
        [Parameter(Mandatory = $true)]
        [string]$ProcessName,
        
        [Parameter(Mandatory = $true)]
        [string]$DeploymentType,
        
        [Parameter(Mandatory = $true)]
        [string]$DeployMode,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskTriggerType,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskRepetitionDuration,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskRepetitionInterval,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskPrincipalUserId,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskRunLevel,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskDescription,
        
        [Parameter(Mandatory = $false)]
        [string]$Delay  # No default value is set
    )

    Begin {
        Write-EnhancedLog -Message "Starting Create-InteractiveMigrationTask function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
    }

    Process {
        try {
            # Unregister the task if it exists
            Unregister-ScheduledTaskWithLogging -TaskName $TaskName

            # Define the arguments for ServiceUI.exe
            $argList = "-process:$ProcessName `"$ToolkitExecutablePath`" -DeploymentType $DeploymentType -DeployMode $DeployMode"
            Write-EnhancedLog -Message "ServiceUI arguments: $argList" -Level "INFO"

            # Create the scheduled task action
            $actionParams = @{
                Execute  = $ServiceUIPath
                Argument = $argList
            }
            $action = New-ScheduledTaskAction @actionParams

            # Create the scheduled task trigger based on the type provided
            $triggerParams = @{
                $TaskTriggerType = $true
            }

            $trigger = New-ScheduledTaskTrigger @triggerParams

            # Apply the delay after creating the trigger, if provided
            if ($PSBoundParameters.ContainsKey('Delay')) {
                $trigger.Delay = $Delay
                Write-EnhancedLog -Message "Setting Delay: $Delay" -Level "INFO"
            }

            # Create the scheduled task principal
            $principalParams = @{
                UserId   = $TaskPrincipalUserId
                RunLevel = $TaskRunLevel
            }
            $principal = New-ScheduledTaskPrincipal @principalParams

            # Register the scheduled task
            $registerTaskParams = @{
                Principal   = $principal
                Action      = $action
                Trigger     = $trigger
                TaskName    = $TaskName
                Description = $TaskDescription
                TaskPath    = $TaskPath
            }
            $Task = Register-ScheduledTask @registerTaskParams

            # Set repetition properties
            # $Task.Triggers.Repetition.Duration = $TaskRepetitionDuration
            # $Task.Triggers.Repetition.Interval = $TaskRepetitionInterval
            # $Task | Set-ScheduledTask
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while creating the interactive migration task: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Exiting Create-InteractiveMigrationTask function" -Level "Notice"
    }
}

# Example usage with splatting
# $CreateInteractiveMigrationTaskParams = @{
#     TaskPath               = "AAD Migration"
#     TaskName               = "PR4B-AADM Launch PSADT for Interactive Migration"
#     ServiceUIPath          = "C:\ProgramData\AADMigration\ServiceUI.exe"
#     ToolkitExecutablePath  = "C:\ProgramData\AADMigration\PSAppDeployToolkit\Toolkit\Deploy-Application.exe"
#     ProcessName            = "explorer.exe"
#     DeploymentType         = "install"
#     DeployMode             = "Interactive"
#     TaskTriggerType        = "AtLogOn"
#     TaskRepetitionDuration = "P1D"  # 1 day
#     TaskRepetitionInterval = "PT15M"  # 15 minutes
#     TaskPrincipalUserId    = "NT AUTHORITY\SYSTEM"
#     TaskRunLevel           = "Highest"
#     TaskDescription        = "AADM Launch PSADT for Interactive Migration Version 1.0"
#     Delay                  = "PT2H"  # 2 hours delay before starting
# }

# Create-InteractiveMigrationTask @CreateInteractiveMigrationTaskParams